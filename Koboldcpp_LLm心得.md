##  gemma-4-26b-a4b-it-heretic.q4_k_m.gguf + Embed text + mmprojcpu
  ./koboldcpp-linux-x64 gemma-4-26b-a4b-it-heretic.q4_k_m.gguf \
  --embeddingsmodel nomic-embed-text-v2-moe.Q8_0.gguf \
  --mmproj mmproj-google_gemma-4-26B-A4B-it-bf16.gguf \
  --mmprojcpu \
  --usecuda \
  --gpulayers 99 \
  --n-cpu-moe 28 \
  --contextsize 65536 \
  --flashattention \
  --quantkv 1 \
  --threads 5 \
  --jinja \
  --useswa \
  --batch-size 2048 \
  --multiuser 4 \
  --defaultgenamt 4096 \
  --host 0.0.0.0 --port 5001 2>&1 | tee kobold_run.log

  --jinjatools \
##  gemma-4-26b-a4b-it-heretic.q4_k_m.gguf 
  ./koboldcpp-linux-x64 gemma-4-26b-a4b-it-heretic.q4_k_m.gguf \
  --usecublas \
  --gpulayers 99 \
  --n-cpu-moe 28 \
  --contextsize 65536 \
  --flashattention \
  --quantkv 3 \
  --threads 6 \
  --jinja \
  --useswa \
  --batch-size 2048 \
  --host 0.0.0.0 --port 5001 2>&1 | tee kobold_run.log

## Nemotron-Cascade-2-30B-A3B-heretic.i1-Q4_K_M.gguf
  ./koboldcpp-linux-x64 Nemotron-Cascade-2-30B-A3B-heretic.i1-Q4_K_M.gguf \
  --embeddingsmodel nomic-embed-text-v2-moe.Q8_0.gguf \
  --usecuda \
  --gpulayers 99 \
  --n-cpu-moe 28 \
  --contextsize 65536 \
  --flashattention \
  --quantkv 3 \
  --threads 5 \
  --batch-size 4096 \
  --defaultgenamt 8192 \
  --multiuser 4 \
  --jinja \
  --host 0.0.0.0 --port 5001 2>&1 | tee kobold_run.log

## Qwen3.5-35B-A3B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf
./koboldcpp-linux-x64 Qwen3.5-35B-A3B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf \
  --embeddingsmodel nomic-embed-text-v2-moe.Q8_0.gguf \
  --usecuda \
  --gpulayers 99 \
  --n-cpu-moe 28 \
  --contextsize 131072 \
  --flashattention \
  --quantkv 2 \
  --threads 5 \
  --batch-size 4096 \
  --multiuser 4 \
  --jinja \
  --host 0.0.0.0 --port 5001 2>&1 | tee kobold_run.log

## Cydonia-24B-v4.3-heretic-v4.i1-Q4_K_M.gguf
  ./koboldcpp-linux-x64 \
  --model Cydonia-24B-v4.3-heretic-v4.i1-Q4_K_M.gguf \
  --gpulayers 41 \
  --contextsize 98304  \
  --port 5001 \
  --host 0.0.0.0
  --flashattention

## Mistral-Nemo-Instruct-2407-OmniWriter.i1-Q4_K_M.gguf
./koboldcpp-linux-x64 \
  --model Mistral-Nemo-Instruct-2407-OmniWriter.i1-Q4_K_M.gguf \
  --gpulayers 41 \
  --contextsize 98304 \
  --port 5001 \
  --host 0.0.0.0

## Dolphin-Mistral-GLM-4.7-Flash-24B-Venice-Edition-Thinking-Uncensored.i1-Q4_K_M.gguf
  ./koboldcpp-linux-x64 \
  --model Dolphin-Mistral-GLM-4.7-Flash-24B-Venice-Edition-Thinking-Uncensored.i1-Q4_K_M.gguf \
  --gpulayers 41 \
  --contextsize 65536 \
  --port 5001 \
  --host 0.0.0.0

<hr>

# Nemo系列

## Mistral-Nemo-Instruct-2407-OmniWriter.i1-Q4_K_M.gguf

### 倉庫
  - https://huggingface.co/mradermacher/Mistral-Nemo-Instruct-2407-OmniWriter-i1-GGUF

### 使用腳本下載
```
./hf_download.sh mradermacher/Mistral-Nemo-Instruct-2407-OmniWriter-i1-GGUF Mistral-Nemo-Instruct-2407-OmniWriter.i1-Q4_K_M.gguf
```

### 啟動方式
```
./auto_launch.sh Mistral-Nemo-Instruct-2407-OmniWriter.i1-Q4_K_M.gguf
```
### 心得
- 


<hr>

# GLM系列

## mradermacher/Dolphin-Mistral-GLM-4.7-Flash-24B-Venice-Edition-Thinking-Uncensored-i1-GGUF

### 倉庫
  - https://huggingface.co/mradermacher/Dolphin-Mistral-GLM-4.7-Flash-24B-Venice-Edition-Thinking-Uncensored-i1-GGUF

### 使用腳本下載
```
./hf_download.sh mradermacher/Dolphin-Mistral-GLM-4.7-Flash-24B-Venice-Edition-Thinking-Uncensored-i1-GGUF Dolphin-Mistral-GLM-4.7-Flash-24B-Venice-Edition-Thinking-Uncensored.i1-Q4_K_M.gguf

```

### 啟動方式
```
./auto_launch.sh Dolphin-Mistral-GLM-4.7-Flash-24B-Venice-Edition-Thinking-Uncensored.i1-Q4_K_M.gguf
```
### 心得
- 

## GLM-4.7-Flash-absolute-heresy.i1-Q4_K_M.gguf

### 倉庫
  - https://huggingface.co/mradermacher/GLM-4.7-Flash-absolute-heresy-i1-GGUF

### 使用腳本下載
  ```
  ./hf_download.sh mradermacher/GLM-4.7-Flash-absolute-heresy-i1-GGUF GLM-4.7-Flash-absolute-heresy.i1-Q4_K_M.gguf

  ```

### 啟動方式
```
./koboldcpp-linux-x64 \
  --model GLM-4.7-Flash-absolute-heresy.i1-Q4_K_M.gguf \
  --gpulayers 99 \
  --contextsize 131072 \
  --port 5001 \
  --host 0.0.0.0 \
  --flashattention
```
### 心得
- 模型搭配"Guided Generations Settings"不太好用，會一直重複場景和思考

## mradermacher/GLM-4.7-Flash-REAP-23B-A3B-absolute-heresy-i1-GGUF

### 倉庫
  - https://huggingface.co/mradermacher/GLM-4.7-Flash-REAP-23B-A3B-absolute-heresy-i1-GGUF

### 使用腳本下載
```
./hf_download.sh mradermacher/GLM-4.7-Flash-REAP-23B-A3B-absolute-heresy-i1-GGUF GLM-4.7-Flash-REAP-23B-A3B-absolute-heresy.i1-Q4_K_M.gguf

```

### 啟動方式
```
./auto_launch.sh GLM-4.7-Flash-REAP-23B-A3B-absolute-heresy.i1-Q4_K_M.gguf
```
### 心得
- 不行，會一直重複場景和思考