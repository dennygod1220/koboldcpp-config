
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