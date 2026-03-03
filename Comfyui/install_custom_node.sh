#!/bin/bash

# 設定 Python 執行檔的路徑 (使用系統 Python 3.12)
PYTHON_EXEC="python3.12"
CUSTOM_NODES_DIR="/workspace/ComfyUI/custom_nodes"

# ============================================================
# 0. 安裝系統函式庫 (opencv-python 等需要)
# ============================================================
echo ">>> 安裝系統函式庫..."
apt-get install -y \
    libxcb1 \
    libxcb-xinerama0 \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    cmake \
    build-essential

# ============================================================
# 1. 檢查並建立/進入 custom_nodes 資料夾
# ============================================================
if [ ! -d "$CUSTOM_NODES_DIR" ]; then
    echo "找不到 $CUSTOM_NODES_DIR，正在建立..."
    mkdir -p "$CUSTOM_NODES_DIR"
fi

echo ">>> 正在進入 $CUSTOM_NODES_DIR 準備下載插件..."
cd "$CUSTOM_NODES_DIR"

# 定義要下載的 Repo 列表
repos=(
    "https://github.com/glowcone/comfyui-base64-to-image"
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"
    "https://github.com/Fannovel16/comfyui_controlnet_aux.git"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
    # "https://github.com/PozzettiAndrea/ComfyUI-DepthAnythingV3.git"
    "https://github.com/kijai/ComfyUI-KJNodes.git"
    # "https://github.com/Gourieff/ComfyUI-ReActor.git"
    "https://github.com/cubiq/ComfyUI_FaceAnalysis.git"
    "https://github.com/yolain/ComfyUI-Easy-Use.git"
    "https://github.com/chrisgoringe/cg-use-everywhere.git"
    "https://github.com/rgthree/rgthree-comfy.git"
)

# 迴圈檢查並下載
for repo in "${repos[@]}"; do
    dir_name=$(basename "$repo" .git)
    if [ -d "$dir_name" ]; then
        echo "!!! $dir_name 已存在，跳過下載。"
    else
        echo ">>> 正在下載: $dir_name"
        git clone "$repo"
    fi
done

# ============================================================
# 2. 返回 ComfyUI 根目錄，安裝 Python 套件
# ============================================================
cd /workspace/ComfyUI
echo ">>> 返回 ComfyUI 根目錄，開始安裝 Python 依賴..."

# 安裝各個 custom node 的 requirements.txt
echo ">>> 自動安裝所有 custom node 的 requirements.txt..."
for req_file in "$CUSTOM_NODES_DIR"/*/requirements.txt; do
    node_name=$(basename "$(dirname "$req_file")")
    echo "---"
    echo ">>> 安裝 [$node_name] 的依賴..."
    $PYTHON_EXEC -m pip install -r "$req_file" --root-user-action=ignore || \
        echo "!!! [$node_name] 部分套件安裝失敗，請手動確認"
done

# 額外安裝腳本原本指定的套件 (補充 requirements.txt 未涵蓋的)
echo "---"
echo ">>> 安裝額外 Python 套件..."
$PYTHON_EXEC -m pip install \
    opencv-python \
    insightface \
    addict \
    matplotlib \
    onnxruntime-gpu \
    omegaconf \
    segment_anything \
    ultralytics \
    color-matcher \
    --root-user-action=ignore

echo ""
echo ">>> 所有安裝步驟已完成！"