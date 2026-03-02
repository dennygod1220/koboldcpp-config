# 如何關閉 Vast.ai ComfyUI 模板的 API 身份驗證

這份文件說明了如何手動或使用腳本關閉 ComfyUI (8188) 與 API Wrapper (8288) 的 Basic Auth 驗證。

## 方法一：使用自動化腳本 (推薦)

我們已經在 `/workspace` 目錄下準備了一個名為 `disable_auth.sh` 的腳本。您只需執行：

```bash
bash /workspace/disable_auth.sh
```

該腳本會：
1. 更新 `/workspace/.env` 檔案中的 `AUTH_EXCLUDE` 變數。
2. 重啟 Caddy 服務，使其動態生成新的 `Caddyfile`。

## 方法二：手動操作

如果您想要手動完成，請按照以下步驟：

1. **編輯或建立環境檔案**：
   開啟 `/workspace/.env` (如果不存在請建立)。
   
2. **新增排除參數**：
   在檔案中加入以下內容：
   ```bash
   AUTH_EXCLUDE=8188,8288
   ```

3. **重啟 Caddy 服務**：
   在終端機執行：
   ```bash
   supervisorctl restart caddy
   ```

## 驗證方式

執行完成後，請嘗試重新整理瀏覽器。如果您不再看到帳號密碼登入視窗，即表示設定成功。
