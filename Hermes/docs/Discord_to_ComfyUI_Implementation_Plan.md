# 🤖 Agent-Centric: Discord $\rightarrow$ ComfyUI 實作計畫 (優化版)

**核心理念:** Discord 僅作為感官與回饋，Hermes Agent 作為決策大腦，透過傳遞 URL 實現輕量化通訊。

## 1. 🧠 Agent 決策架構 (The Brain)
Agent 不再處理沉重的數據，而是專注於意圖解析：
1. **感知 (Perceive):** 接收 Discord 訊息與圖片 URL。
2. **推理 (Reason):** 解析使用者自然語言指令 $\rightarrow$ 轉換為 ComfyUI Prompt。
3. **行動 (Act):** 調用 `comfyui_image_editor` 工具，僅傳遞 `image_url` 與 `prompt`。

## 2. 🛠️ 工具定義 (The Tool Definition)

### **Tool Name:** `comfyui_image_editor`
* **Description:** 「當使用者要求編輯圖片時使用。此工具會將圖片 URL 與指令送入 ComfyUI 進行 AI 處理，並返回處理後的結果。」
* **Arguments (JSON Schema):**
    * `prompt` (string): 使用者的編輯指令。
    * `image_url` (string): **(優化)** 圖片的原始網址，避免 Base64 造成的 Context 負擔。
    * `height` (integer): 輸出高度。

## 3. 🚀 實作路徑 (Implementation Roadmap)

### **第一階段：工具開發與封裝 (Tooling Phase - 重點)**
- [ ] **開發 Tool 核心腳本:** 撰寫一個高度解耦的 Python 函式，負責以下「苦力活」：
    * **URL 下載與轉碼:** 從 `image_url` 下載圖片 $\rightarrow$ 在本地暫存 $\rightarrow$ 轉碼為 Base64。
    * **模板注入:** 將 Base64 與 `prompt` 注入 `/root/hermes/Comfyui_Hermes_單圖編輯工作流API_Template.json`。
    * **API 執行:** 發送請求至 ComfyUI 伺服器。
- [ ] **註冊 Tool:** 將此工具註冊至 Hermes Toolset，確保 Agent 僅需傳遞 URL 即可完成任務。

### **第二階段：感官與回饋整合 (I/O Integration)**
- [ ] **Discord 感官器:** 監聽 Discord 附件，提取圖片的 `url` 而非下載內容。
- [ ] **Discord 執行器:** 負責將 Agent 回傳的結果（圖片檔案）發送回頻道。

### **第三階段：Agent 循環測試 (ReAct Loop Testing)**
- [ ] **測試案例:** 驗證 Agent 是否能正確解析「把背景變紅」並將 `image_url` 傳遞給工具，而非自行處理 Base64。

## 4. ⚠️ 關鍵技術挑戰 (Technical Challenges)
- **職責分離 (Decoupling):** 確保 Agent 的 Context 始終保持精簡，所有重度數據處理都發生在 Tool 內部。
- **網路穩定性:** 處理 Cloudflare Tunnel 可能導致的下載或 API 連線中斷問題。
- **效能優化:** 確保工具內部的下載與轉碼流程高效，減少使用者等待時間。