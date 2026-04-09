#!/bin/bash
# Hugging Face GGUF Downloader
# Usage: ./hf_download.sh <repo> <filename>
# Example: ./hf_download.sh mradermacher/Cydonia-24B-v4.3-heretic-v4-i1-GGUF Cydonia-24B-v4.3-heretic-v4.i1-Q4_K_M.gguf

DOWNLOAD_DIR="/home/ubuntu/koboldcpp-config"

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "用法: $0 <HuggingFace倉庫> <檔案名>"
  echo "範例: $0 mradermacher/Cydonia-24B-v4.3-heretic-v4-i1-GGUF Cydonia-24B-v4.3-heretic-v4.i1-Q4_K_M.gguf"
  exit 1
fi

REPO="$1"
FILE="$2"

echo "📥 開始下載..."
echo "   倉庫: $REPO"
echo "   檔案: $FILE"
echo "   目標: $DOWNLOAD_DIR"
echo ""

hf download "$REPO" "$FILE" --local-dir "$DOWNLOAD_DIR"

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ 下載完成！檔案已儲存至 $DOWNLOAD_DIR/$FILE"
else
  echo ""
  echo "❌ 下載失敗，請檢查倉庫名稱與檔案名稱是否正確。"
  exit 1
fi
