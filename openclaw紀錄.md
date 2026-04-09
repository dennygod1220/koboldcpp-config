# 1. 重啟 KoboldCPP（全 GPU 模式）
cd /workspace/koboldcpp-config && screen -dmS koboldcpp bash -c './koboldcpp-linux-x64 \
  --model Qwen3.5/Crow-9B-Opus-4.6-Distill-Heretic_Qwen3.5.Q8_0.gguf \
  --mmproj Qwen3.5/Crow-9B-Opus-4.6-Distill-Heretic_Qwen3.5.mmproj-Q8_0.gguf \
  --gpulayers 99 --flashattention --contextsize 8192 \
  --threads 6 --port 5001 --host 0.0.0.0 2>&1 | tee /workspace/koboldcpp.log'
# 2. 等 KoboldCPP 載入完（約 30 秒）再重啟 OpenClaw
sleep 40 && screen -dmS openclaw bash -c 'openclaw gateway run 2>&1 | tee /workspace/openclaw-gateway.log'