#!/bin/bash

# ============================================================
# ComfyUI API Auth 關閉工具 (Vast.ai 專用)
# ============================================================

ENV_FILE="/workspace/.env"
PORTS="8188,8288"

echo ">>> 正在檢查環境變數檔案: $ENV_FILE"

# 如果檔案不存在，則建立
if [ ! -f "$ENV_FILE" ]; then
    echo "--- 建立新的 .env 檔案"
    echo "AUTH_EXCLUDE=$PORTS" > "$ENV_FILE"
else
    # 如果檔案存在，檢查是否已經有 AUTH_EXCLUDE
    if grep -q "AUTH_EXCLUDE" "$ENV_FILE"; then
        echo "--- 更新現有的 AUTH_EXCLUDE 變數"
        # 簡單地將 8188,8288 加入（如果尚未存在）
        # 這裡使用 sed 替換整行以確保格式正確
        sed -i "s/^AUTH_EXCLUDE=.*/AUTH_EXCLUDE=$PORTS/" "$ENV_FILE"
    else
        echo "--- 將 AUTH_EXCLUDE 變數加入 .env 檔案"
        echo "AUTH_EXCLUDE=$PORTS" >> "$ENV_FILE"
    fi
fi

echo ">>> 已更新 $ENV_FILE，設定 AUTH_EXCLUDE=$PORTS"
echo ">>> 正在重啟 Caddy 服務以套用變更..."

# 重啟 Caddy
supervisorctl restart caddy

echo ">>> ============================================================"
echo ">>> 身份驗證已成功關閉！"
echo ">>> 埠號 8188 (ComfyUI) 與 8288 (API Wrapper) 現在無需密碼即可訪問。"
echo ">>> ============================================================"
