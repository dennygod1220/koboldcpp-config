# Ubuntu GitHub SSH 設定與推送完整教學

這份教學整理了在 Ubuntu 伺服器上建立 SSH 金鑰、配置 GitHub 帳號，並將本地已 Clone 的專案推送到 GitHub 的完整流程。這是根據我們剛才解決問題的流程整理而成的。

## 1. 設定 Git 使用者名稱與信箱
在進行首次提交前，Git 需要知道是誰在操作，因此必須設定全局 (Global) 的使用者名稱和信箱來作為 Commit 的作者標籤。

```bash
git config --global user.name "你的名字"
git config --global user.email "你的信箱@example.com"
```

## 2. 生成 SSH 金鑰 (SSH Key)
在 Ubuntu 終端機中透過 `ssh-keygen` 工具生成新的 SSH 密鑰對。這對密鑰包含私鑰（留在本機存放）與公鑰（要交給 GitHub）。

```bash
ssh-keygen -t ed25519 -C "你的信箱@example.com"
```
* 當系統提示 `Enter file in which to save the key` 時，通常直接按 `Enter` 接受預設路徑 (`~/.ssh/id_ed25519`) 即可。
* 當系統提示設定密碼 (passphrase) 時，可以輸入密碼增加安全性，或是直接按兩次 `Enter` 留空（代表不使用密碼保護該金鑰，後續推播也不會一直被要求打密碼）。

## 3. 把 SSH 公鑰加入到 GitHub
你需要讀取剛剛生成的「公鑰」檔案內容，並把它新增到 GitHub 帳號的安全設定中。

1. 透過以下指令在終端機印出公鑰內容：
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
2. 將終端機印出，以 `ssh-ed25519...` 開頭的字串全部複製下來。
3. 登入 GitHub 網站：
   * 點擊右上角大頭貼，進入 **Settings**。
   * 選擇左邊側欄的 **SSH and GPG keys**。
   * 點擊右上方的綠色按鈕 **New SSH key**。
   * **Title** 可以輸入便於辨識的名稱（例如：`Ubuntu Server`）。
   * 把剛剛複製的那一長串貼到 **Key** 的欄位。
   * 點擊 **Add SSH key** 儲存。

## 4. 變更專案的遠端網址 (Remote URL) 為 SSH 格式
如果你一開始是用 HTTPS 模式 `git clone` 專案下來的，那 Git 預設會走 HTTPS 的登入驗證（因而會報錯或者要求輸入密碼/Token）。因為我們現在要用 SSH 金鑰來自動驗證，必須把遠端網址改成 SSH 的格式。

在專案資料夾內（如 `koboldcpp-config`）執行：

```bash
# 檢查目前的遠端網址 (剛 Clone 下來時可能會顯示 https:// 開頭)
git remote -v

# 變更遠端網址為 SSH 協議
# (這裡以你的儲存庫為例)
git remote set-url origin git@github.com:dennygod1220/koboldcpp-config.git

# 再次檢查，會確認已經變成 git@github.com: 開頭的網址
git remote -v
```

## 5. 提交與推播 (Commit & Push)
SSH 驗證與作者身分都設定妥當後，就可以直接推播程式碼囉！

```bash
# 加入所有被變更的檔案
git add .

# 提交變更並寫上註解文字
git commit -m "更新了某些功能..."

# 推播到遠端 GitHub 儲存庫
git push
```

*附註：若是該分支第一次推播到遠端，Git 可能會提示你要用 `git push --set-upstream origin main` 這種指令建立分支追蹤關聯。*
