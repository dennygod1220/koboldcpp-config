#!/bin/bash

# 發送 POST 請求來清除 ComfyUI 歷史紀錄
echo "正在清除 ComfyUI 歷史紀錄..."

curl -s -X POST http://localhost:8188/history \
     -H 'Content-Type: application/json' \
     -d '{"clear": true}'

echo -e "\n清除完畢！"
