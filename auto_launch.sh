#!/bin/bash

# KoboldCPP 自動化啟動與 Context Size 優化腳本 (針對 A6000 48GB)
# 使用方式: ./auto_launch.sh <模型路徑> [context_size]

MODEL_FILE="$1"
CUSTOM_CTX="$2"  # 可選: 手動指定 context size，留空則自動計算

# 檢查參數
if [ -z "$MODEL_FILE" ]; then
    echo "❌ 錯誤: 請指定模型檔案路徑。"
    echo "範例: ./auto_launch.sh GLM-4.7-Flash-absolute-heresy.i1-Q4_K_M.gguf"
    exit 1
fi

# 檢查檔案是否存在
if [ ! -f "$MODEL_FILE" ]; then
    echo "❌ 錯誤: 找不到檔案 $MODEL_FILE"
    exit 1
fi

echo "🔍 正在分析硬體資源..."

# 1. 獲取 GPU 總顯存 (MiB)
TOTAL_VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1)
if [ -z "$TOTAL_VRAM" ]; then
    echo "⚠️ 無法讀取 GPU 資訊，將預設為 48000 MiB (A6000)。"
    TOTAL_VRAM=48000
fi

# 2. 獲取模型檔案大小 (MiB)
MODEL_SIZE_MIB=$(du -m "$MODEL_FILE" | cut -f1)

# 3. 計算剩餘可用於 KV Cache 的空間
# 公式: 總顯存 - 模型大小 - 3GB 緩衝 (預留給系統與額外運算)
AVAIL_FOR_KV=$(($TOTAL_VRAM - $MODEL_SIZE_MIB - 3072))

# 4. 估算最佳 Context Size
# KV cache 大小 = 2 (K+V) × n_layers × n_embd_k_gqa × 2 bytes (FP16) per token
# 不同規模模型的保守 bytes/token 估算 (FP16 KV):
#   ~12B  → n_layers≈32, n_embd_k_gqa≈1024 → ~128 KB/token
#   ~24B  → n_layers≈40, n_embd_k_gqa≈1024 → ~160 KB/token
#   ~32-35B → n_layers≈60, n_embd_k_gqa≈1024 → ~240 KB/token
# 根據模型大小自動選擇估算係數 (bytes per token，單位 KiB)
# 根據模型大小選擇 KIB/token 估算值 (FP16 KV cache):
#   ~12B  → n_layers≈32, n_embd_k_gqa≈1024 → ~132 KiB/token
#   ~24B  → n_layers≈40, n_embd_k_gqa≈1024 → ~168 KiB/token
#   ~30-35B → n_layers≈60, n_embd_k_gqa≈1024 → ~248 KiB/token
# 注意: 30B+ Q4_K_M 模型大約 17-22 GB，因此門檻設為 15000 MiB
if [ "$MODEL_SIZE_MIB" -ge 15000 ]; then
    # 大型 30B+ 模型 (>15GB)，使用 248 KiB/token
    KV_BYTES_PER_TOKEN_KIB=248
elif [ "$MODEL_SIZE_MIB" -ge 10000 ]; then
    # 中型 20-30B 模型 (10-15GB)，使用 168 KiB/token
    KV_BYTES_PER_TOKEN_KIB=168
else
    # 小型 ≤12B 模型 (<10GB)，使用 132 KiB/token
    KV_BYTES_PER_TOKEN_KIB=132
fi

# 公式: (可用 MiB × 1024 KiB/MiB) / KiB_per_token
calc_ctx=$(( ($AVAIL_FOR_KV * 1024) / $KV_BYTES_PER_TOKEN_KIB ))

# 限制最大與最小範圍 (最小 8k, 最大 131072)
if [ $calc_ctx -lt 8192 ]; then calc_ctx=8192; fi
if [ $calc_ctx -gt 131072 ]; then calc_ctx=131072; fi

# 若使用者手動指定 context size，則覆蓋自動計算值
if [ -n "$CUSTOM_CTX" ]; then
    echo "⚙️  使用手動指定 Context Size: $CUSTOM_CTX (自動計算值: $calc_ctx)"
    calc_ctx=$CUSTOM_CTX
fi

echo "========================================"
echo "🚀 啟動模型: $MODEL_FILE"
echo "📊 模型大小: $MODEL_SIZE_MIB MiB"
echo "💎 總顯存:   $TOTAL_VRAM MiB"
echo "💡 KV係數:   $KV_BYTES_PER_TOKEN_KIB KiB/token (FP16)"
echo "🧠 Context Size: $calc_ctx"
echo "⚡ 優化參數: --gpulayers 99 --flashattention"
echo "========================================"

# 5. 執行 KoboldCPP
./koboldcpp-linux-x64 \
  --model "$MODEL_FILE" \
  --gpulayers 99 \
  --contextsize "$calc_ctx" \
  --port 5001 \
  --host 0.0.0.0 \
  --flashattention
