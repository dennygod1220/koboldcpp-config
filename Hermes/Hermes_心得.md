# Hermes Agent 設定與維護筆記

## 📁 重要路徑

| 用途 | 路徑 |
|------|------|
| Hermes 設定檔 | `/root/.hermes/config.yaml` |
| Hermes 啟動程式 | `/root/.hermes/hermes-agent/venv/bin/python` |
| Gateway PID 紀錄 | `/root/.hermes/gateway.pid` |
| Gateway 日誌 | `/root/.hermes/logs/gateway.log` |

---

## ⚙️ 重要設定：max_tokens（生成 token 上限）

### 問題
Hermes agent 使用本地 KoboldCPP 作為後端，KoboldCPP 預設生成 token 上限為 **1024 tokens**，
導致 agent 執行複雜任務時做到一半就被截斷中斷。

### 解法
在 `~/.hermes/config.yaml` 的 `custom_providers` 區塊，對應的 model 設定下加入 `max_tokens`：

```yaml
custom_providers:
- name: Local (127.0.0.1:5001)
  base_url: http://127.0.0.1:5001/v1
  model: koboldcpp/gemma-4-26b-a4b-it-heretic.q4_k_m
  models:
    koboldcpp/gemma-4-26b-a4b-it-heretic.q4_k_m:
      context_length: 65536
      max_tokens: 8192   # ← 這行是關鍵，預設沒有會用 KoboldCPP 的 1024 上限
```

### 說明
- Hermes 透過 OpenAI-compatible API 呼叫 KoboldCPP
- `max_tokens` 會放進每次 API 請求的 body 裡，KoboldCPP 會尊重這個值
- **不需要**也**不能**從 KoboldCPP 啟動參數設定（`--max_length` 這個 flag 並不存在）
- 修改 `config.yaml` 後，**必須重啟 Hermes gateway** 才會生效

---

## 🔄 重啟 Hermes Gateway

### 查看目前 gateway 狀態

```bash
cat /root/.hermes/gateway.pid
```

### 重啟指令

```bash
cd /root/.hermes/hermes-agent && \
/root/.hermes/hermes-agent/venv/bin/python -m hermes_cli.main gateway run --replace &
```

OR 

```bash
cd /root/.hermes/hermes-agent && /root/.hermes/hermes-agent/venv/bin/python -m hermes_cli.main gateway run --replace > /root/.hermes/logs/gateway.log 2>&1 &
echo "Gateway restarted"
```

- `--replace` 參數會自動停掉舊的 gateway 再啟動新的，不需要手動 kill
- 執行後會看到 `⚕ Hermes Gateway Starting...` 表示成功

### 查看 gateway 日誌

```bash
tail -f /root/.hermes/logs/gateway.log
```

---

## 🧠 Hermes 使用的模型設定

目前設定（`~/.hermes/config.yaml`）：

```yaml
model:
  default: koboldcpp/gemma-4-26b-a4b-it-heretic.q4_k_m
  provider: custom
  base_url: http://127.0.0.1:5001/v1
```

- **Model**：`gemma-4-26b-a4b-it-heretic.q4_k_m`
- **Backend**：本地 KoboldCPP，Port `5001`
- **Context Length**：65536 tokens
- **Max Generation**：8192 tokens（已設定）

---

## 📝 注意事項

- 修改 `config.yaml` → 必須重啟 gateway
- KoboldCPP 本身不需要重啟（`max_tokens` 是透過 API 請求傳遞的）
- 若 KoboldCPP 重啟了，Hermes 不需要重啟，會自動重連
- `max_tokens: 8192` 是每次單次回應的上限，不是對話 context 的上限（那個是 `context_length`）
