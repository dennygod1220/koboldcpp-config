# Discord Bot 重啟指南

當需要重啟 Discord Bot 服務時，請使用以下指令以確保路徑與日誌位置正確：

```bash
# 1. 結束現有的 discord_bot 程序
kill $(pgrep -f discord_bot_main.py)

# 2. 使用 nohup 在背景重新啟動，並將日誌存放在正確的 logs 資料夾中
nohup python3 /root/koboldcpp-config/Hermes/src/discord_bot_main.py > /root/koboldcpp-config/Hermes/logs/discord_bot.log 2>&1 &
```

## 注意事項
- **路徑變更**：請務必使用 `/root/koboldcpp-config/Hermes/` 作為基準路徑。
- **日誌位置**：輸出日誌會存放在 `/root/koboldcpp-config/Hermes/logs/discord_bot.log`。
- **檢查狀態**：啟動後可使用 `ps aux | grep discord_bot_main.py` 確認程序是否正常運行。