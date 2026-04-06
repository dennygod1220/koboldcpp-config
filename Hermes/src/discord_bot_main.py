import discord
from discord.ext import commands
import os
import asyncio
from comfyui_tool import ComfyUITool


def _load_env(env_file):
    env = {}
    if os.path.exists(env_file):
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    if "=" in line:
                        key, value = line.split("=", 1)
                        env[key.strip()] = value.strip()
    return env


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_FILE = os.path.join(os.path.dirname(SCRIPT_DIR), ".env")
env = _load_env(ENV_FILE)

DISCORD_TOKEN = env.get("DISCORD_TOKEN", "")
COMFY_API_URL = env.get("COMFY_API_URL", "")
TEMPLATE_PATH = env.get("TEMPLATE_PATH", "")
OUTPUT_DIR = env.get("OUTPUT_DIR", "")

if not all([DISCORD_TOKEN, COMFY_API_URL, TEMPLATE_PATH, OUTPUT_DIR]):
    raise ValueError("請檢查 .env 檔案設定是否完整")

comfy_tool = ComfyUITool(
    api_url=COMFY_API_URL, template_path=TEMPLATE_PATH, output_dir=OUTPUT_DIR
)

# --- Bot 設定 ---
intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix="$", intents=intents)


@bot.event
async def on_ready():
    print(f"[Bot] 已連線 | 使用者名稱: {bot.user.name}")
    print(f"[Bot] ComfyUI 端點: {COMFY_API_URL}")
    print("------------------------------------------")


@bot.event
async def on_message(message):
    if message.author == bot.user:
        return

    if message.attachments:
        attachment = message.attachments[0]
        if any(
            attachment.filename.lower().endswith(ext)
            for ext in ["png", "jpg", "jpeg", "webp"]
        ):
            processing_msg = await message.reply(
                "🔍 **偵測到圖片與指令，正在啟動 AI 編輯流程...**"
            )

            try:
                user_prompt = message.content if message.content else "Default edit"
                image_url = attachment.url

                print(f"[Bot] 收到任務: {user_prompt} | 圖片: {image_url}")

                loop = asyncio.get_event_loop()
                result = await loop.run_in_executor(
                    None,
                    lambda: comfy_tool.execute(prompt=user_prompt, image_url=image_url),
                )

                if result.get("status") == "success":
                    local_file_path = result.get("local_path")
                    await message.reply(
                        content=f"✅ **編輯完成！**\n\n**指令:** `{user_prompt}`\n**檔案:** `{os.path.basename(local_file_path)}`",
                        file=discord.File(local_file_path),
                    )
                else:
                    await message.reply("❌ **處理失敗**，請檢查 ComfyUI 日誌。")

            except Exception as e:
                print(f"[Error] 處理過程中發生錯誤: {e}")
                await message.reply(f"❌ **發生錯誤:** `{str(e)}`")

            finally:
                await processing_msg.edit(content="")

    await bot.process_commands(message)


if __name__ == "__main__":
    bot.run(DISCORD_TOKEN)
