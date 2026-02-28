#!/bin/bash

# KoboldCPP 自動化啟動腳本 (--quantkv 1 / Q8 KV Cache 版)
# KV Cache 量化為 Q8，精度高於 Q4，但相較 FP16 仍可節省顯存
# 使用方式: ./auto_launch_q8kv.sh <模型路徑>

MODEL_FILE="$1"

# 檢查參數
if [ -z "$MODEL_FILE" ]; then
    echo "❌ 錯誤: 請指定模型檔案路徑。"
    echo "範例: ./auto_launch_q8kv.sh Cydonia-24B-v4.3-heretic-v4.i1-Q4_K_M.gguf"
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
    echo "⚠️ 無法讀取 GPU 資訊，將預設為 24000 MiB。"
    TOTAL_VRAM=24000
fi

# 2. 獲取模型檔案大小 (MiB)
MODEL_SIZE_MIB=$(du -m "$MODEL_FILE" | cut -f1)

# 3. 計算剩餘可用於 KV Cache 的空間
# 公式: 總顯存 - 模型大小 - 3GB 緩衝
AVAIL_FOR_KV=$(($TOTAL_VRAM - $MODEL_SIZE_MIB - 3072))

# 4. 估算最佳 Context Size
# --quantkv 1 使用 Q8 KV cache，每 token 佔用約 64 bytes (FP16 的 1/2)
# 公式: (可用的 MiB * 1024) / 64
calc_ctx=$(( ($AVAIL_FOR_KV * 1024) / 64 ))

# 限制最大與最小範圍 (最小 8k, 最大 131072)
if [ $calc_ctx -lt 8192 ]; then calc_ctx=8192; fi
if [ $calc_ctx -gt 131072 ]; then calc_ctx=131072; fi

echo "========================================================"
echo "🚀 啟動模型: $MODEL_FILE"
echo "📊 模型大小: $MODEL_SIZE_MIB MiB"
echo "💎 總顯存:   $TOTAL_VRAM MiB"
echo "🧠 自動優化 Context Size: $calc_ctx (quantkv 1 模式)"
echo "⚡ 優化參數: --gpulayers 99 --flashattention --quantkv 1"
echo "========================================================"

# 5. 執行 KoboldCPP
./koboldcpp-linux-x64 \
  --model "$MODEL_FILE" \
  --gpulayers 99 \
  --contextsize "$calc_ctx" \
  --port 5001 \
  --host 0.0.0.0 \
  --flashattention \
  --quantkv 1
