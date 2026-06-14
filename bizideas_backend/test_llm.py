import os
import sys
import time
from dotenv import load_dotenv

# Load env from bizideas_backend
dotenv_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "bizideas_backend", ".env")
load_dotenv(dotenv_path)

aimlapi_key = os.getenv("AIMLAPI_API_KEY")
featherless_key = os.getenv("FEATHERLESS_API_KEY")

print(f"AIMLAPI KEY: {aimlapi_key[:5] if aimlapi_key else 'None'}...")
print(f"FEATHERLESS KEY: {featherless_key[:5] if featherless_key else 'None'}...")

from openai import OpenAI

if aimlapi_key:
    print("Testing AIMLAPI...")
    try:
        client = OpenAI(api_key=aimlapi_key, base_url="https://api.aimlapi.com/v1", max_retries=0)
        start = time.time()
        response = client.chat.completions.create(
            model="anthropic/claude-sonnet-4.6",
            messages=[{"role": "user", "content": "Hi"}],
            timeout=10.0
        )
        print(f"AIMLAPI Success in {time.time() - start:.2f}s:")
        print(response.choices[0].message.content)
    except Exception as e:
        print(f"AIMLAPI Failed: {e}")

if featherless_key:
    print("\nTesting Featherless...")
    try:
        client = OpenAI(api_key=featherless_key, base_url="https://api.featherless.ai/v1", max_retries=0)
        start = time.time()
        response = client.chat.completions.create(
            model="Qwen/Qwen2.5-7B-Instruct",
            messages=[{"role": "user", "content": "Hi"}],
            timeout=10.0
        )
        print(f"Featherless Success in {time.time() - start:.2f}s:")
        print(response.choices[0].message.content)
    except Exception as e:
        print(f"Featherless Failed: {e}")
