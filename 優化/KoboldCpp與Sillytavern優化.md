# KoboldCpp / llama.cpp Context Processing 優化指南
> 針對 **Prefill / Prompt Processing** 階段的加速設定總結  
> 測試環境：i5-12400F + RTX 4080 Super 16GB + 64GB RAM  
> 模型：`Nemotron-Cascade-2-30B-A3B-heretic.i1-Q4_K_M.gguf` (22.82 GB)

---

## 📋 問題定義

| 術語 | 說明 | 瓶頸特性 |
|------|------|---------|
| **Prefill / Prompt Processing** | 每次對話時，將完整 Context 編碼為 KV Cache 的過程 | 計算密集 + 記憶體頻寬密集，速度隨 Context 長度下降 |
| **Token Generation** | 生成新 Token 的推理階段 | 與本指南無關 |

> 🔸 **核心問題**：如果每次請求都重新處理完整歷史，Context 越大，等待時間越長。

---

## ✅ 已驗證有效的優化設定

### 🔧 KoboldCpp 啟動參數

```bash
./koboldcpp-linux-x64 your_model.gguf \
  --gpulayers 99 \                    # ✅ 最大化 GPU 離載
  --n-cpu-moe 28 \                    # ✅ MoE 專家層強制放 CPU（節省 VRAM）
  --contextsize 65536 \               # ✅ 根據需求設定，65K 為平衡點
  --flashattention \                  # ✅ 啟用 Flash Attention 加速注意力計算
  --quantkv 2 \                       # ✅ KV Cache 量化為 Q4，節省顯存
  --threads 6 \                       # ✅ 設定為 CPU 實體核心數（i5-12400F = 6 核）
  --batch-size 4096 \                 # ✅⭐ 關鍵！大幅提升 Prefill 速度
  --host 0.0.0.0 --port 5001
```

| 參數 | 建議值 | 效果 | 備註 |
|------|--------|------|------|
| `--gpulayers` | `99` | ✅ 讓模型層盡量跑在 GPU | 4080S 16GB 無法完全載入 30B 模型，但能離載大部分層 |
| `--batch-size` | `2048` → `4096` | ✅⭐ **Prefill 速度提升 20-50%** | 越大越快，但會增加 VRAM 使用，需監控是否 OOM |
| `--flashattention` | 啟用 | ✅ 長 Context 下加速注意力計算 | 需新版 KoboldCpp + NVIDIA GPU |
| `--quantkv 2` | 啟用 | ✅ KV Cache 記憶體減半 | Q4 量化，精度損失可忽略 |
| `--threads` | `6` | ✅ 避免超執行緒效能下降 | 設定為實體核心數 |
| `--n-cpu-moe 28` | `28` | ✅ 節省約 11GB VRAM | 讓部分 MoE 專家層放 CPU，避免 OOM |
| `~~--usevulkan~~` | **移除** | ✅ 切換回 CUDA 後端 | NVIDIA 顯卡用 CUDA 效率更佳 |

> ⚠️ **重要**：`--batch-size` 的甜蜜點需透過 `nvidia-smi` 監控 VRAM 使用率來決定。若超過 95% 或出現 OOM，請退回上一個數值。

---

### 🌐 SillyTavern 前端設定（KV Cache 复用關鍵）

| 設定位置 | 建議值 | 說明 |
|----------|--------|------|
| **API Type** | `Chat Completion` | ✅ 必須使用此模式才能支援會話狀態 |
| **Endpoint URL** | `http://localhost:5001/v1` | ✅ 必須包含 `/v1`，但**不要**加 `/chat/completions` |
| **Streaming** | ✅ 開啟 | ✅ 有助於保持會話連接狀態 |
| **Prompt Post-Processing** | `None` 或 `Merge` | ✅ 避免重組消息破壞前綴匹配 |
| **Max Context Size** | `≤ KoboldCpp 的 --contextsize` | ✅ 避免前端發送超出後端緩存的歷史 |
| **Smart Context 插件** | ✅ 啟用（可選） | ✅ 自動管理哪些歷史發送給後端 |

#### 🔍 驗證 KV Cache 是否复用的方法

觀察 KoboldCpp Log 中的 `Processing Prompt` 行：

```log
# ✅ 成功复用（理想）：
第一次：Processing Prompt [BATCH] (0 / 2640 tokens)  ← 完整處理
第二次：Processing Prompt [BATCH] (0 / 17 tokens)     ← 只處理新增的 17 tokens！

# ❌ 未复用（問題）：
第一次：Processing Prompt [BATCH] (0 / 4066 tokens)
第二次：Processing Prompt [BATCH] (0 / 4586 tokens)   ← 仍然處理完整歷史+新消息
```

> 🎯 **測試結果**：成功复用後，第二次請求的 Prefill 時間從 **2.91s → 0.17s**，快了 **17 倍**！

---

## 📚 Lorebook / World Info 使用建議

### 問題：Lorebook 會大幅增加 Prompt 長度

從 Log 可見，啟用 Lorebook 後 Context 從 2640 → 7342 tokens，導致 Prefill 時間增加。

### ✅ 優化策略

| 策略 | 設定建議 | 預期效果 |
|------|---------|---------|
| **限制 Scanning Depth** | `2-4` | 避免掃描過多歷史，減少誤匹配 |
| **啟用精確匹配** | `Match Whole Words` + `Case Sensitive` | ✅ 提高關鍵字觸發準確度 |
| **設定 Max Budget** | `500-1000 tokens` | ✅ 限制 Lorebook 總佔用，避免暴增 |
| **使用精確關鍵字** | 專有名詞 > 通用詞 | ✅ 減少不必要的插入 |
| **分層管理** | Core Lore（永久）+ Dynamic Lore（觸發） | ✅ 只插入當前場景相關的條目 |
| **控制插入位置** | `After System Prompt` 或 `Before User Message` | ✅ 避免每個回合重複插入 |

### 📝 Lorebook 條目範例（JSON 格式）

```json
{
  "key": ["dryer", "laundry room", "Michelle's secret"],
  "content": "Michelle secretly masturbates on the dryer during laundry cycles, using the vibration and warmth.",
  "constant": false,        // ✅ 不永久插入
  "selective": true,        // ✅ 只在關鍵字匹配時插入
  "order": 100,             // ✅ 控制插入順序
  "position": 0,            // ✅ 插入位置：0 = 頂部
  "disable": false
}
```

---

## 📊 性能對比總結

| 設定階段 | Prefill 速度 | 總 Prompt 大小 | 備註 |
|---------|------------|--------------|------|
| **初始設定**（Vulkan + batch 2048 + 未复用） | ~400-500 T/s | 4000-7000 tokens | 每次重新處理完整歷史 |
| **優化後**（CUDA + batch 4096 + KV Cache 复用） | **1200-1800 T/s** | 2640 → 17 tokens（第二次） | ⭐ 速度提升 3-4 倍，复用後提升 17 倍 |
| **啟用優化 Lorebook** | ~1000-1500 T/s | 3000-4000 tokens | 保持速度同時享受世界觀 |

---

## 🚨 硬體限制與現實建議

由於 **模型 22.82 GB > 顯卡 16 GB**，以下瓶頸無法完全透過軟體設定解決：

| 方案 | 說明 | 預期效果 |
|------|------|---------|
| **換用更小模型** | 例如 14B Q4_K_M (~9GB) 可完全放入 VRAM | Prefill 速度提升 2-3 倍 |
| **升級顯卡** | 24GB VRAM (3090/4090) 可容納更多層 | 減少 PCIe 傳輸瓶頸 |
| **降低 Context Size** | 從 65536 降到 32768 | 減少 KV Cache 記憶體佔用 |
| **使用 EXL2 格式** | 如果支援，可能比 GGUF 更高效 | 需確認 KoboldCpp 版本支援 |

---

## 🎯 最終檢查清單

- [ ] ✅ 移除 `--usevulkan`，讓 KoboldCpp 自動使用 CUDA
- [ ] ✅ `--batch-size` 設定為 `4096`（監控 VRAM 使用率）
- [ ] ✅ SillyTavern 使用 `/v1` 端點 + Streaming 開啟
- [ ] ✅ 確認 Prompt Post-Processing 設為 `None` 或 `Merge`
- [ ] ✅ 同一個聊天會話中連續對話，不頻繁點擊 "New Chat"
- [ ] ✅ 觀察 Log 確認第二次請求只處理新增 tokens
- [ ] ✅ Lorebook 設定 `Max Budget` ≤ 1000 tokens + 精確關鍵字

---

## 🔧 附錄：完整啟動指令範例

```bash
#!/bin/bash
# KoboldCpp 優化啟動腳本 (RTX 4080 Super 16GB)

./koboldcpp-linux-x64 Nemotron-Cascade-2-30B-A3B-heretic.i1-Q4_K_M.gguf \
  --gpulayers 99 \
  --n-cpu-moe 28 \
  --contextsize 65536 \
  --flashattention \
  --quantkv 2 \
  --threads 6 \
  --batch-size 4096 \
  --host 0.0.0.0 \
  --port 5001 \
  2>&1 | tee kobold_run.log
```

> 💡 **提示**：執行 `watch -n 1 nvidia-smi` 監控顯存使用率，確保 `--batch-size` 設定在安全範圍內。

---

> 📌 **總結**：在硬體限制下，**KV Cache 复用** 是提升體驗的關鍵，其次是 **`--batch-size` 調優** 與 **CUDA 後端切換**。Lorebook 需謹慎管理，避免破壞前綴匹配條件。

*最後更新：2026-04-02*  
*測試版本：KoboldCpp v1.110 + SillyTavern + Nemotron-Cascade-2-30B*