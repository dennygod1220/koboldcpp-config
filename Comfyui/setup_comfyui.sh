#!/bin/bash

# ============================================================
# ComfyUI 自動環境部署腳本 (Vast.ai 專用)
# ============================================================

# 設定變數
PYTHON_EXEC="python3.12"
WORKSPACE_DIR="/workspace"
COMFYUI_DIR="$WORKSPACE_DIR/ComfyUI"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"

echo ">>> 開始執行 ComfyUI 環境部署腳本..."

# ============================================================
# 1. 安裝系統函式庫 (用於 OpenCV, InsightFace 等)
# ============================================================
echo ">>> 正在安裝系統函式庫 (apt-get)..."
# 先更新一次清單
apt-get update
apt-get install -y \
    libxcb1 \
    libxcb-xinerama0 \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    cmake \
    build-essential \
    ffmpeg

# ============================================================
# 2. 準備 Custom Nodes
# ============================================================
echo ">>> 正在處理 Custom Nodes..."

if [ ! -d "$CUSTOM_NODES_DIR" ]; then
    echo "找不到 $CUSTOM_NODES_DIR，正在建立..."
    mkdir -p "$CUSTOM_NODES_DIR"
fi

cd "$CUSTOM_NODES_DIR"

# 定義要下載的 Repo 列表 (參考 install_custom_node.sh)
repos=(
    "https://github.com/glowcone/comfyui-base64-to-image"
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus.git"
    "https://github.com/Fannovel16/comfyui_controlnet_aux.git"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
    "https://github.com/kijai/ComfyUI-KJNodes.git"
    "https://github.com/cubiq/ComfyUI_FaceAnalysis.git"
    "https://github.com/yolain/ComfyUI-Easy-Use.git"
    "https://github.com/chrisgoringe/cg-use-everywhere.git"
    "https://github.com/rgthree/rgthree-comfy.git"
    # "https://github.com/PozzettiAndrea/ComfyUI-Grounding.git"
)

# 迴圈檢查並下載
for repo in "${repos[@]}"; do
    dir_name=$(basename "$repo" .git)
    if [ -d "$dir_name" ]; then
        echo "--- [$dir_name] 已存在，跳過下載。"
    else
        echo ">>> 正在下載插件: $dir_name"
        git clone "$repo"
    fi
done

# ============================================================
# 3. 安裝 Python 依賴
# ============================================================
echo ">>> 正在安裝 Python 套件 (pip)..."

# 切換到 ComfyUI 根目錄
cd "$COMFYUI_DIR"

# 安裝各個 custom node 的 requirements.txt
echo ">>> 掃描並安裝 custom node 的 requirements.txt..."
for req_file in "$CUSTOM_NODES_DIR"/*/requirements.txt; do
    if [ -f "$req_file" ]; then
        node_name=$(basename "$(dirname "$req_file")")
        echo "--- 正在安裝 [$node_name] 的依賴..."
        $PYTHON_EXEC -m pip install -r "$req_file" --root-user-action=ignore || \
            echo "!!! WARNING: [$node_name] 的依賴安裝可能有部分失敗，請檢查輸出資訊。"
    fi
done

# 額定安裝額外/全域 Python 套件
echo "--- 正在安裝額外 Python 套件 (如 OpenCV, InsightFace 等)..."
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

# ============================================================
# 4. 模型下載區
# ============================================================
echo ">>> 正在處理模型下載 (HuggingFace)..."

# 設定模型下載目錄
TEXT_ENCODER_DIR="$COMFYUI_DIR/models/text_encoders"
mkdir -p "$TEXT_ENCODER_DIR"

# 下載 qwen_3_8b_fp8mixed.safetensors (Text Encoder)
# 來源: https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-9b/blob/main/split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors
REPOS_ID="Comfy-Org/vae-text-encorder-for-flux-klein-9b"
REMOTE_FILE="split_files/text_encoders/qwen_3_8b_fp8mixed.safetensors"
LOCAL_FILE="qwen_3_8b_fp8mixed.safetensors"

if [ -f "$TEXT_ENCODER_DIR/$LOCAL_FILE" ]; then
    echo "--- [$LOCAL_FILE] 已存在，跳過下載。"
else
    echo ">>> 正在下載 Text Encoder: $LOCAL_FILE"
    hf download "$REPOS_ID" "$REMOTE_FILE" \
        --local-dir "$TEXT_ENCODER_DIR" 

    if [ -f "$TEXT_ENCODER_DIR/$REMOTE_FILE" ]; then
        mv "$TEXT_ENCODER_DIR/$REMOTE_FILE" "$TEXT_ENCODER_DIR/$LOCAL_FILE"
        rm -rf "$TEXT_ENCODER_DIR/split_files"
        echo ">>> $LOCAL_FILE 下載並整理完成。"
    fi
fi

# 下載 flux2-vae.safetensors (VAE)
# 來源: https://huggingface.co/Comfy-Org/flux2-dev/blob/main/split_files/vae/flux2-vae.safetensors
VAE_DIR="$COMFYUI_DIR/models/vae"
mkdir -p "$VAE_DIR"
REPOS_ID_VAE="Comfy-Org/flux2-dev"
REMOTE_FILE_VAE="split_files/vae/flux2-vae.safetensors"
LOCAL_FILE_VAE="flux2-vae.safetensors"

if [ -f "$VAE_DIR/$LOCAL_FILE_VAE" ]; then
    echo "--- [$LOCAL_FILE_VAE] 已存在，跳過下載。"
else
    echo ">>> 正在下載 VAE: $LOCAL_FILE_VAE"
    hf download "$REPOS_ID_VAE" "$REMOTE_FILE_VAE" \
        --local-dir "$VAE_DIR" 

    if [ -f "$VAE_DIR/$REMOTE_FILE_VAE" ]; then
        mv "$VAE_DIR/$REMOTE_FILE_VAE" "$VAE_DIR/$LOCAL_FILE_VAE"
        rm -rf "$VAE_DIR/split_files"
        echo ">>> $LOCAL_FILE_VAE 下載並整理完成。"
    fi
fi

# 下載額外 Flux 模型 (來自 下載Model.md)
echo ">>> 正在檢查並下載額外 Flux 模型..."

# --- LoRAs 下載區 ---
LORA_DIR="$COMFYUI_DIR/models/loras/flux2_9B"
mkdir -p "$LORA_DIR"
cd "$LORA_DIR"

# 1. Sex, Nudes, Other Fun Stuff (SNOFS)
if [ ! -f "klein_snofs_v1_1.safetensors" ]; then
    echo ">>> 正在下載 SNOFS LoRA..."
    wget --header='Host: civitai-delivery-worker-prod.5ac0637cfd0766c97916cefa3764fbdf.r2.cloudflarestorage.com' --header='User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36' --header='Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' --header='Accept-Language: en-US,en;q=0.9,zh-TW;q=0.8,zh;q=0.7,en-AU;q=0.6' --header='Referer: https://civitai.com/' 'https://civitai-delivery-worker-prod.5ac0637cfd0766c97916cefa3764fbdf.r2.cloudflarestorage.com/model/2506/kleinSnofsV11.usnP.safetensors?X-Amz-Expires=86400&response-content-disposition=attachment%3B%20filename%3D%22klein_snofs_v1_1.safetensors%22&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=e01358d793ad6966166af8b3064953ad/20260225/us-east-1/s3/aws4_request&X-Amz-Date=20260225T050340Z&X-Amz-SignedHeaders=host&X-Amz-Signature=0441efc66364c372635020231dd0f780789ee30e3cc55288ed96528cadbb1e8f' -c -O 'klein_snofs_v1_1.safetensors'
fi

# 2. Diverse Male Nudity
if [ ! -f "diverse_male_nudity_Flux2_Klein_base_9b_000009600.safetensors" ]; then
    echo ">>> 正在下載 Diverse Male Nudity LoRA..."
    wget --header='Host: civitai-delivery-worker-prod.5ac0637cfd0766c97916cefa3764fbdf.r2.cloudflarestorage.com' --header='User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36' --header='Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' --header='Accept-Language: en-US,en;q=0.9,zh-TW;q=0.8,zh;q=0.7,en-AU;q=0.6' --header='Referer: https://civitai.com/' 'https://civitai-delivery-worker-prod.5ac0637cfd0766c97916cefa3764fbdf.r2.cloudflarestorage.com/model/2254624/diverseMaleNudityFlux2.aN21.safetensors?X-Amz-Expires=86400&response-content-disposition=attachment%3B%20filename%3D%22diverse_male_nudity_Flux2_Klein_base_9b_000009600.safetensors%22&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=e01358d793ad6966166af8b3064953ad/20260225/us-east-1/s3/aws4_request&X-Amz-Date=20260225T050612Z&X-Amz-SignedHeaders=host&X-Amz-Signature=77c1e56e33f52bb287bb5b87471dc8d3a5c02d60bcfee0a368d610e6ced903d0' -c -O 'diverse_male_nudity_Flux2_Klein_base_9b_000009600.safetensors'
fi

# 3. Flaccid VTX | Flaccid Uncut Penis
if [ ! -f "Klein VTX 9b.safetensors" ]; then
    echo ">>> 正在下載 Flaccid VTX LoRA..."
    wget --header='Host: civitai-delivery-worker-prod.5ac0637cfd0766c97916cefa3764fbdf.r2.cloudflarestorage.com' --header='User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36' --header='Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' --header='Accept-Language: en-US,en;q=0.9,zh-TW;q=0.8,zh;q=0.7,en-AU;q=0.6' --header='Referer: https://civitai.com/' 'https://civitai-delivery-worker-prod.5ac0637cfd0766c97916cefa3764fbdf.r2.cloudflarestorage.com/model/7547075/klein20VTX209b.guo0.safetensors?X-Amz-Expires=86400&response-content-disposition=attachment%3B%20filename%3D%22Klein%20VTX%209b.safetensors%22&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=e01358d793ad6966166af8b3064953ad/20260225/us-east-1/s3/aws4_request&X-Amz-Date=20260225T090555Z&X-Amz-SignedHeaders=host&X-Amz-Signature=0bc37eb9d6302c0ec070e6149530fac0e8ed23b5541ce18a6172200bffc3b7cb' -c -O 'Klein VTX 9b.safetensors'
fi

# --- Diffusion Model 下載區 ---
DIFFUSION_DIR="$COMFYUI_DIR/models/diffusion_models"
mkdir -p "$DIFFUSION_DIR"
cd "$DIFFUSION_DIR"

# 4. Dark Beast | 黑兽
if [ ! -f "darkBeastMar0326Latest_dbkleinv2BFS.safetensors" ]; then
    echo ">>> 正在下載 Dark Beast Diffusion 模型..."
    wget --header='Host: b2.civitai.com' --header='User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36' --header='Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' --header='Accept-Language: en-US,en;q=0.9,zh-TW;q=0.8,zh;q=0.7,en-AU;q=0.6' --header='Referer: https://civitai.com/' --header='Cookie: _sharedID=e9553233-d6cf-4b2e-95ec-d738cc879235; _sharedID_cst=TyylLI8srA%3D%3D; _ga=GA1.1.91605148.1761120223; __qca=I0-640231510-1763155904187; _pubcid=52af86fe-4700-4a44-92d4-3b536bb91c6c; __gads=ID=1aac7ba5836e45be:T=1761120226:RT=1772389998:S=ALNI_Mbx_mNmOrZfL6M_WLr74rkvI2Ffhw; __eoi=ID=fba4b38bd8577b90:T=1761120226:RT=1772389998:S=AA-Afjax0VidfK9ZL3bNbfqffL_Z; _cc_id=2c1a933cb61cea6ab510180846e1cd8c; panoramaId_expiry=1773072597496; panoramaId=9ce583930c983f6fef6ee346a7c2185ca02c27382158009e66ea72d455e8ad02; panoramaIdType=panoDevice; _sharedID_last=Thu%2C%2005%20Mar%202026%2020%3A34%3A51%20GMT; cto_bundle=BV8Hpl81cjF4Nm5HM1pRUE5JRmpmbTlJQUtpdEJDbnoybVJrRWdQelNWUXZZcVhPJTJGdHNRZUZGTUhUNXhibzRtU1IyQ0tFcXdGU3BvV1RIYmpJcVI4czhpbGVrdG8yTkRWNExzcERseDdDTm9aV2F2ZkF5b2M5cTg3NjlDeEdsdVdZWUFvdzBhSUkyJTJCTFpIbHhWcFkzSkklMkZxMEElM0QlM0Q; _ga_N6W8XF7DXE=GS2.1.s1772742891$o316$g1$t1772742956$j60$l0$h0; __Secure-civitai-token=eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIn0..4nPabJILoObLmHQP.JkrS2MqtKI14htygGAxutKCF6cjo887k21-sefCifZ164GeaUA8snkuhJBBlXqox7RKGVoMVyxQUdJ1fIS-f5roQhfOB3csJv2U-oAqjcdwIENQkv0R2gjXUL92ZAsyf0BkUfVL3y54XwH3xGbOaJLIAh2MR55KWSgCoffFenRxH-yJO5Iih9YEohE9PEGRoPvV1J2T2bT6iEB-L7Fa5LQ3InViYCsRBXsC52SMrlQDLCNRKlo6NKAbDzeqBFJASH0UO735QY3xIicyrS5eyEMpdEXdqN9wRIFcgmVodnZ1E53i30bT5piyjNBIWu3sgT0wZvn7YvszXRBUjc6JMma8hwd4Psmk6DqQIyCQzd4GjXDkmARu9aJVCmtjFMyP8PbUoC39YRuw-jqZAdadTpe-lO_7T-buxMbvw_swmDlYknl74eARnWJvlC0v1p9hwijUZW5MZ8YKMwCG3JrSPt8gThyIUNdeFUbq8FmXLAJj8TPowfbxmxu61UgmgICyC7bvXTQ7BnNBRwQ96z-3C0yDXp5ZZoBFqENBhklb1B8lIkuoDzYpSi1S1UXqjymF2Rg861zFhE1bWOiO2mdL7biKiPEnnafIlY0m4gcw1BEGfX8b3Nzn_T9AvcJv-zeAWYpR0HcVLrSP_W434du-Sixtb_s3Sxw1GvdM9kxCCRtp6M1qDRe28CnNmtEo4ApXkAzyM54aWMZujtcaOOtkqR7UG_suIzU2A8hIzbk9B8HlqIAZNwZI17-NFZLURiYS2osPle2XFoRWikGqrsSvoasWzOnKeMUFn4Hs3NXNgrQZXpXkveOEtJheGqOUToKQEuGgf6sPOAFgtukAN3jFFsITXAZsrm0VM8jH5sEozO_V3hWExb3dXIKBApfWhyiS35hQPYubUVOg_y8aEJCxbECTpxd1O0-TPHEtfK6139XiHe0WB8OoBG5HyjEFf6v5Q_zsBk6Cxb508ipihKZOzj5xveL1edlxBj6OF3MZ5FFclOLaLQgP-kr-Wjiv53fRRV3uh2nXdEYnKopkaoYDq2Bq-tmfCLBmYzxboT5AVOn-QI-CAuUeYl8_mUJn4r-_I4Hnw8NaO_0-u1_QNLBGSI7bBrmVOLVmtRkBU9oz1VUPGamOSh1SIoiqZAgXSaqOSMkhfmJiVKK4tfrZPQDUQ6LW_B4wwaUklYdXWFZI4WbV37v-a8Db1I3CBnqo6AQ1AeViHlworUMk_CgbAucLy0yYExDBxcPvv9gbltBx4bOuKr_U-nI1bFrD-9n4GPg-0PHp_iMQL-IT03LlpA_rgKrFxmurdP6KHB_pKL9xehz6D9BsdHqCGKsbLovknrlRJyVCOH6GCAHVVoSKP-lvDLny2wjo3Dne1TJSCVA.BgqzSMCB3v_4Aql81x0WDw' --header='Connection: keep-alive' 'https://b2.civitai.com/file/civitai-modelfiles/model/289798/darkbeastKlein9bV2BFS.CAQF.safetensors?Authorization=3_20260305203803_b8f6683ebbbde2f81af5a8d7_79ea62992e9a32cc85d8d5d4467a2a7492592a2a_004_20260305213803_0051_dnld&b2ContentDisposition=attachment%3B+filename%3D%22darkBeastMar0326Latest_dbkleinv2BFS.safetensors%22' -c -O 'darkBeastMar0326Latest_dbkleinv2BFS.safetensors'
fi


echo ""
echo ">>> ============================================================"
echo ">>> 自動化部署完成！"
echo ">>> 請重新啟動 ComfyUI 以套用所有更改。"
echo ">>> ============================================================"
