# Hermes ComfyUI Workflow Plugin - 程式碼分析

## 一、Plugin 發現與註冊機制

### 1. Plugin 結構
```
hermes-agent-comfyui-workflow/
├── __init__.py          # 核心程式碼
├── plugin.yaml          # Plugin 元資料
├── README.md
└── templates/           # ComfyUI Workflow JSON 範本
    ├── Flux2_klein_t2i_API_Template.json
    └── Comfyui_Hermes_單圖編輯工作流API_Template.json
```

### 2. Plugin 註冊方式（`__init__.py:307-314`）

```python
def register(ctx):
    """Register the comfyui_workflow tool"""
    ctx.register_tool(
        "comfyui_workflow",           # tool name
        "comfyui-workflow",           # toolset name  
        COMFYUI_WORKFLOW_SCHEMA,      # JSON Schema 定義
        handle_comfyui_workflow,      # 處理函式
    )
```

Hermes Agent 會載入 plugins 目錄下的所有 plugin，呼叫其 `register(ctx)` 函式來註冊 tool。

### 3. Tool Schema 定義（`__init__.py:241-274`）

```python
COMFYUI_WORKFLOW_SCHEMA = {
    "name": "comfyui_workflow",
    "description": "執行 ComfyUI workflow 進行圖片生成或編輯...",
    "parameters": {
        "type": "object",
        "properties": {
            "prompt": {"type": "string", "description": "生成或編輯圖片的指令"},
            "workflow_type": {
                "type": "string", 
                "enum": ["image_edit", "text_to_image"],
                "default": "text_to_image"
            },
            "image_url": {"type": "string"},  # image_edit 必要
            "width": {"type": "integer", "default": 1024},
            "height": {"type": "integer", "default": 1024},
        },
        "required": ["prompt", "workflow_type"],
    },
}
```

---

## 二、與 Hermes Agent 的整合流程

### 1. 環境變數配置（`plugin.yaml`）
```yaml
requires_env:
  - COMFY_API_URL      # ComfyUI API 伺服器網址
  - COMFY_TEMPLATE_DIR # JSON 範本目錄
  - COMFY_OUTPUT_DIR   # 圖片輸出目錄
```

### 2. Handler 呼叫流程

```
User Input (Discord)
       ↓
Hermes Agent (LLM 判断使用 comfyui_workflow tool)
       ↓
handle_comfyui_workflow(params, task_id)
       ↓
_run_workflow(prompt, workflow_type, image_url, width, height)
       ↓
執行結果回傳 (JSON string)
       ↓
Hermes Agent 解讀結果，回覆用戶
```

### 3. Handler 實作（`__init__.py:277-304`）

```python
def handle_comfyui_workflow(
    params: Dict[str, Any], task_id: str = None, **kwargs
) -> str:
    prompt = params.get("prompt", "")
    workflow_type = params.get("workflow_type", "text_to_image")
    image_url = params.get("image_url")
    width = params.get("width", 1024)
    height = params.get("height", 1024)

    try:
        result = _run_workflow(...)
        return result
    except Exception as e:
        return json.dumps({"status": "error", "message": str(e)})
```

---

## 三、與 ComfyUI 溝通機制

### 1. API 端點

| 操作 | Method | Endpoint |
|------|--------|----------|
| 提交 prompt | POST | `{COMFY_API_URL}/prompt` |
| 查詢歷史 | GET | `{COMFY_API_URL}/history/{prompt_id}` |
| 下載圖片 | GET | `{COMFY_API_URL}/view?filename=...` |

### 2. Workflow 執行流程

```
_load_template()          # 載入 JSON 範本
       ↓
修改節點參數
  - image_edit: 修改 node 64 (base64 圖片), node 7 (prompt)
  - text_to_image: 修改 node 67 (prompt), node 77 (寬高)
       ↓
POST /prompt              # 提交 workflow
       ↓
取得 prompt_id
       ↓
_poll_for_result()       # 輪詢 /history/{prompt_id}
       ↓
下載結果圖片到本地端
       ↓
回傳 {status, image_path, filename}
```

### 3. 圖片下載（`__init__.py:85-109`）

```python
def _download_image_as_base64(url: str) -> str:
    # 支援三種來源：
    # 1. file:// 本地檔案
    # 2. HTTP URL (自動加上 ?raw=1)
    # 3. 直接路徑 os.path.isfile()
    
    if url.startswith("file://"):
        url = url[7:]
    
    if os.path.isfile(url):
        with open(url, "rb") as f:
            return base64.b64encode(f.read()).decode("utf-8")
    
    raw_url = url if url.endswith((".png", ".jpg", ".jpeg", ".webp")) else url + "?raw=1"
    response = requests.get(raw_url, timeout=30)
    return base64.b64encode(response.content).decode("utf-8")
```

### 4. 結果輪詢（`__init__.py:112-156`）

```python
def _poll_for_result(api_url, prompt_id, output_dir, timeout=600):
    while time.time() - start < timeout:
        res = requests.get(f"{api_url}/history/{prompt_id}")
        if res.status_code == 200 and res.json():
            # 遍历 history 找 outputs.images
            for node_output in outputs.values():
                if "images" in node_output and node_output["images"]:
                    # 下載圖片到 output_dir
                    img_url = f"{api_url}/view?filename={filename}&type={img_type}"
                    img_res = requests.get(img_url)
                    with open(local_path, "wb") as f:
                        f.write(img_res.content)
                    return {"status": "success", "local_path": ...}
        time.sleep(2)
    raise TimeoutError("ComfyUI task timed out")
```

---

## 四、Template 結構解析

### 1. 文生圖 Template（Flux2）

```
┌─────────────────┐     ┌─────────────────┐
│ 67 CLIPTextEncode │ ──▶ │   73 KSampler   │
│   (prompt)       │     │   (denoise=1)   │
└─────────────────┘     └────────┬────────┘
                                 │
┌─────────────────┐     ┌────────▼────────┐     ┌─────────────────┐
│ 77 EmptyFlux2   │ ──▶ │  VAEDecode (69) │ ──▶ │ ImageCompressor │
│ LatentImage     │     │                 │     │     (75)         │
└─────────────────┘     └─────────────────┘     └─────────────────┘

模型載入：
├── 71: UNETLoader (flux2/snofs...distilledV12Fp8.safetensors)
├── 70: CLIPLoader (qwen_3_8b_fp8mixed.safetensors)  
└── 68: VAELoader (flux2-vae.safetensors)
```

### 2. 圖片編輯 Template

```
┌──────────────┐     ┌──────────────┐
│ 64 LoadImage │ ──▶ │ 63:51 Resize │
│  FromBase64  │     │              │
└──────────────┘     └──────┬───────┘
                            │
              ┌──────────────▼──────────────┐
              │    63:50 VAEEncode          │
              │   (將圖片轉為 latent)       │
              └──────────────┬──────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ 7 CLIPText   │    │ 63:55        │    │ 63:57        │
│ Encode       │    │ Reference    │    │ EmptyFlux2   │
│ (prompt)     │    │ Latent (+)   │    │ LatentImage  │
└──────────────┘    └──────────────┘    └──────────────┘
                            │                   │
                            └─────────┬─────────┘
                                      ▼
                              ┌──────────────┐
                              │  73 KSampler │
                              │ (denoise=0.85│
                              └──────────────┘
```

關鍵節點：
- **node 64**: `LoadImageFromBase64` - 接收 base64 圖片
- **node 7**: `CLIPTextEncode` - 編碼編輯指令
- **node 63:55**: `ReferenceLatent` - 將原圖 latent 與 prompt 結合
- **KSampler**: `denoise=0.85` - 保留 15% 原圖內容

---

## 五、錯誤處理與 Debug

### 1. Debug 模式
```python
COMFY_WORKFLOW_DEBUG=true  # 啟用 logging
COMFY_WORKFLOW_LOG_DIR=/path/to/logs  # 日誌目錄
```

### 2. 常見錯誤

| 錯誤 | 原因 | 解決 |
|------|------|------|
| Template not found | COMFY_TEMPLATE_DIR 錯誤 | 確認路徑存在 |
| COMFY_API_URL not configured | 環境變數未設定 | 檢查 .env |
| TimeoutError | ComfyUI 執行過慢 | 增加 timeout 參數 |
| 圖片未傳 Discord | 缺少 MEDIA: 標籤 | 回覆需包含 `MEDIA:{路徑}` |

---

## 六、整合要點總結

1. **Plugin 發現**：Hermes 會自動掃描 `~/.hermes/plugins/` 目錄，呼叫 `register()` 註冊 tool
2. **Tool 定義**：透過 JSON Schema 描述 tool 的 input/output 結構
3. **API 溝通**：HTTP REST API - POST prompt → GET history → GET view
4. **圖片傳遞**：Base64 編碼 / 下載儲存 / 本地路徑回傳
5. **結果呈現**：需要在回覆中加入 `MEDIA:<路徑>` 才能發送到 Discord