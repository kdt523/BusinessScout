import asyncio
import os
import sys
import time
from dotenv import load_dotenv

# Load env from bizideas_backend
dotenv_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "bizideas_backend", ".env")
load_dotenv(dotenv_path)

aimlapi_key = os.getenv("AIMLAPI_API_KEY")
featherless_key = os.getenv("FEATHERLESS_API_KEY")

from openai import OpenAI

async def main():
    if featherless_key:
        client = OpenAI(api_key=featherless_key, base_url="https://api.featherless.ai/v1", max_retries=0)
        
        system_instruction = "You are a helpful assistant."
        prompt = "Introduce yourself."
        
        def _call():
            print("Inside _call thread...")
            messages = [{"role": "system", "content": system_instruction}, {"role": "user", "content": prompt}]
            response = client.chat.completions.create(
                model="Qwen/Qwen2.5-7B-Instruct",
                messages=messages,
                temperature=0.7,
                timeout=10.0
            )
            print("Received response inside thread.")
            return response.choices[0].message.content

        print("Calling asyncio.to_thread(_call)...")
        start = time.time()
        result = await asyncio.to_thread(_call)
        print(f"asyncio.to_thread completed in {time.time() - start:.2f}s:")
        print(result)

if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    asyncio.run(main())
