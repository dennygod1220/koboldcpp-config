import requests
import base64
import time
import json
import os
from functools import partial


# --------- 輔助函式 ---------
def retry(fn, max_attempts=5, delay=2, backoff=2):
    success = False
    for attempt in range(max_attempts):
        try:
            result = fn()
            success = True
            break
        except Exception as e:
            if attempt == max_attempts - 1:
                raise e
            time.sleep(delay * (backoff**attempt))
    return result


def retryable(fn):
    def wrapper(*args, **kwargs):
        return retry(lambda: fn(*args, **kwargs))

    return wrapper


class ComfyUITool:
    def __init__(self, api_url, template_path, output_dir=None):
        self.api_url = api_url.rstrip("/")
        self.template_path = template_path
        self.output_dir = output_dir
        if not self.output_dir:
            self.output_dir = "/tmp/hermes_comfy_output"
        if not os.path.isdir(self.output_dir):
            os.makedirs(self.output_dir, exist_ok=True)

    def _load_template(self):
        with open(self.template_path, "r", encoding="utf-8") as f:
            return json.load(f)

    @retryable
    def _download_image_as_base64(self, url):
        raw_url = url if url.endswith((".png", ".jpg", ".jpeg")) else url + "?raw=1"
        response = requests.get(raw_url, timeout=10)
        response.raise_for_status()
        return base64.b64encode(response.content).decode("utf-8")

    def execute(self, prompt, image_url, height=None):
        print(f"[Tool] Starting task with prompt: {prompt}")
        img_b64 = self._download_image_as_base64(image_url)
        workflow = self._load_template()
        workflow["64"]["inputs"]["data"] = img_b64
        workflow["7"]["inputs"]["text"] = prompt
        if height:
            workflow["28"]["inputs"]["value"] = height
        else:
            workflow["28"]["inputs"]["value"] = 1024
        payload = {"prompt": workflow}
        response = requests.post(f"{self.api_url}/prompt", json=payload)
        response.raise_for_status()
        prompt_id = response.json().get("prompt_id")
        print(f"[Tool] Task submitted. Prompt ID: {prompt_id}")
        return self._poll_for_result(prompt_id)

    def _poll_for_result(self, prompt_id, timeout=600):
        start = time.time()
        while time.time() - start < timeout:
            res = requests.get(f"{self.api_url}/history/{prompt_id}")
            if res.status_code == 200 and res.json():
                history = res.json()
                result_data = None
                for nid in history:
                    outputs = history[nid].get("outputs", {})
                    for node_output in outputs.values():
                        if "images" in node_output and node_output["images"]:
                            result_data = node_output
                            break
                    if result_data:
                        break
                if result_data:
                    img = result_data["images"][0]
                    filename = img.get("filename")
                    subfolder = img.get("subfolder", "")
                    if subfolder:
                        subfolder = subfolder.split("/")[-1]
                    img_type = img.get("type", "output")
                    local_path = os.path.join(self.output_dir, filename)
                    img_url = f"{self.api_url}/view?filename={filename}&type={img_type}&subfolder={subfolder}"
                    print(f"[Tool] Downloading image via /view: {img_url}")
                    img_res = requests.get(img_url)
                    img_res.raise_for_status()
                    with open(local_path, "wb") as f:
                        f.write(img_res.content)
                    print(f"[Tool] Image saved to {local_path}")
                    return {"status": "success", "local_path": local_path}
            time.sleep(2)
        raise TimeoutError("ComfyUI task timed out")
