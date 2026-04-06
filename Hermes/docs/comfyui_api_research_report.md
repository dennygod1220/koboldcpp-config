# ComfyUI API 圖片下載研究報告

## 1. 研究目標
自動化從 ComfyUI History API 提取生成圖片並下載至本地目錄。

## 2. 發現問題
- **路徑解析失效**：原始腳本僅嘗試從 `inputs['images']` 獲取檔名，忽略了 ComfyUI 輸出時會帶有 `subfolder` 參數的特性。
- **URL 構造錯誤**：ComfyUI 的圖片存取需要完整的 `filename`、`type` 以及 `subfolder` 參數才能透過 `/view` 接口正確讀取。

## 3. 關鍵技術細節 (JSON Schema 發現)
根據 History JSON 結構，圖片的完整存取網址格式如下：
`{host}/view?filename={filename}&type=output&subfolder={subfolder_path}`

**範例實例：**
- **Host**: `https://still-aimed-recorders-hay.trycloudflare.com`
- **Filename**: `compressed_20260406_143142_470845_0001_4884.webp`
- **Type**: `output`
- **Subfolder**: `/workspace/ComfyUI/output/compressed`

## 4. 最終解決方案
在自動化腳本中，必須解析 History JSON 中的 `subfolder` 欄位，並將其與 `filename` 組合，使用 `/view` 接口進行下載，而非僅依賴檔名。

## 5. 結論
透過精確解析 History 數據中的子目錄資訊，可以實現 100% 成功的圖片自動化抓取。