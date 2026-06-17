import os
import asyncio
import logging
from typing import Dict, List, Any, Optional
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger("BaseAgent")


def featherless_model_label(model_code: Optional[str] = None) -> str:
    """Derive a human-friendly display label from the Featherless model code.

    Keeps the chatbox/diagnostics in sync with whatever FEATHERLESS_MODEL is set
    to in .env, instead of hardcoding a specific Qwen version.
    """
    code = model_code or os.getenv("FEATHERLESS_MODEL", "Qwen/Qwen2.5-VL-7B-Instruct")
    # Strip the org prefix (e.g. "Qwen/Qwen3.6-35B-A3B" -> "Qwen3.6-35B-A3B").
    name = code.split("/")[-1]
    # Insert a space after the leading vendor word for readability
    # ("Qwen3.6-35B-A3B" -> "Qwen 3.6-35B-A3B").
    import re
    match = re.match(r"^([A-Za-z]+)(\d.*)$", name)
    if match:
        return f"{match.group(1)} {match.group(2)}"
    return name


class BaseAgent:
    def __init__(self, name: str, role: str):
        self.name = name
        self.role = role
        
        # Load API keys
        self.aimlapi_key = os.getenv("AIMLAPI_API_KEY")
        self.featherless_key = os.getenv("FEATHERLESS_API_KEY")
        self.gemini_key = os.getenv("GEMINI_API_KEY")
        self.anthropic_key = os.getenv("ANTHROPIC_API_KEY")
        self.openai_key = os.getenv("OPENAI_API_KEY")
        
        # LLM Clients
        self.aimlapi_client = None
        self.featherless_client = None
        self.gemini_client = None
        self.anthropic_client = None
        self.openai_client = None
        
        self.last_call_diagnostics = {}
        self.init_llm_clients()

    def init_llm_clients(self):
        # Initialize AI/ML API client if key is present (OpenAI compatible)
        if self.aimlapi_key:
            try:
                from openai import OpenAI
                self.aimlapi_client = OpenAI(
                    api_key=self.aimlapi_key,
                    base_url="https://api.aimlapi.com/v1",
                    max_retries=0
                )
                logger.info(f"[{self.name}] AI/ML API Client initialized.")
            except Exception as e:
                logger.error(f"Failed to initialize AI/ML API: {e}")

        # Initialize Featherless client if key is present (OpenAI compatible)
        if self.featherless_key:
            try:
                from openai import OpenAI
                self.featherless_client = OpenAI(
                    api_key=self.featherless_key,
                    base_url="https://api.featherless.ai/v1",
                    max_retries=0
                )
                logger.info(f"[{self.name}] Featherless Client initialized.")
            except Exception as e:
                logger.error(f"Failed to initialize Featherless: {e}")

        # Initialize Gemini client if key is present
        if self.gemini_key:
            try:
                from google import genai
                self.gemini_client = genai.Client(api_key=self.gemini_key)
                logger.info(f"[{self.name}] Gemini Client initialized.")
            except Exception as e:
                logger.error(f"Failed to initialize Gemini Client: {e}")

        # Initialize Anthropic client if key is present
        if self.anthropic_key:
            try:
                import anthropic
                self.anthropic_client = anthropic.AsyncAnthropic(api_key=self.anthropic_key)
                logger.info(f"[{self.name}] Anthropic Client initialized.")
            except Exception as e:
                logger.error(f"Failed to initialize Anthropic Client: {e}")

        # Initialize OpenAI client if key is present
        if self.openai_key:
            try:
                import openai
                self.openai_client = openai.AsyncOpenAI(api_key=self.openai_key)
                logger.info(f"[{self.name}] OpenAI Client initialized.")
            except Exception as e:
                logger.error(f"Failed to initialize OpenAI Client: {e}")

    def estimate_cost_usd(self, model: str, input_tokens: int, output_tokens: int) -> float:
        model_lower = model.lower()
        if "claude-3-5" in model_lower or "claude-sonnet-4.6" in model_lower:
            return (input_tokens * 3.0 + output_tokens * 15.0) / 1000000.0
        elif "gpt-4o-mini" in model_lower:
            return (input_tokens * 0.150 + output_tokens * 0.600) / 1000000.0
        elif "qwen" in model_lower:
            return 0.0
        elif "gemini" in model_lower:
            return (input_tokens * 0.075 + output_tokens * 0.300) / 1000000.0
        else:
            return (input_tokens * 3.0 + output_tokens * 15.0) / 1000000.0

    async def call_llm(self, prompt: str, system_instruction: str = "") -> str:
        """
        Calls available LLMs. Based on self.name, we prefer different providers
        to demonstrate multi-model agent-to-agent collaboration:
        - Orchestrator: prefer AI/ML API (Claude 4.6 Sonnet)
        - Location Scout & Business Planner: prefer Featherless (Qwen 2.5 VL)
        - Competitor Analyst uses agents.langchain_reasoner instead of this
          native provider loop.
        """
        import time
        self.last_call_diagnostics = {}
        
        # Determine preferred order
        providers = []
        if self.name in ["Orchestrator", "Competitor Analyst"]:
            providers = ["aimlapi", "featherless", "gemini", "anthropic", "openai"]
        else:
            providers = ["featherless", "aimlapi", "gemini", "anthropic", "openai"]
            
        for provider in providers:
            if provider == "aimlapi" and self.aimlapi_client:
                try:
                    model_name = os.getenv("AIMLAPI_MODEL", "anthropic/claude-sonnet-4.6")
                    start_time = time.time()
                    def _call():
                        messages = []
                        if system_instruction:
                            messages.append({"role": "system", "content": system_instruction})
                        messages.append({"role": "user", "content": prompt})
                        response = self.aimlapi_client.chat.completions.create(
                            model=model_name,
                            messages=messages,
                            temperature=0.7,
                            timeout=45.0
                        )
                        return response.choices[0].message.content
                    result = await asyncio.to_thread(_call)
                    latency = time.time() - start_time
                    input_toks = len(prompt) // 4 + 12
                    output_toks = len(result) // 4 + 12
                    self.last_call_diagnostics = {
                        "provider": "AI/ML API",
                        "model": "DeepSeek V4 Flash" if "deepseek" in model_name.lower() else "Claude 4.6 Sonnet",
                        "model_code": model_name,
                        "latency_sec": round(latency, 2),
                        "input_tokens": input_toks,
                        "output_tokens": output_toks,
                        "status": "Success (API Call)",
                        "cost_usd": self.estimate_cost_usd(model_name, input_toks, output_toks)
                    }
                    return result
                except Exception as e:
                    logger.error(f"AI/ML API generation failed: {e}. Trying next...")
                    
            elif provider == "featherless" and self.featherless_client:
                try:
                    model_name = os.getenv("FEATHERLESS_MODEL", "Qwen/Qwen2.5-VL-7B-Instruct")
                    start_time = time.time()
                    def _call():
                        messages = []
                        if system_instruction:
                            messages.append({"role": "system", "content": system_instruction})
                        messages.append({"role": "user", "content": prompt})
                        response = self.featherless_client.chat.completions.create(
                            model=model_name,
                            messages=messages,
                            temperature=0.7,
                            timeout=45.0
                        )
                        return response.choices[0].message.content
                    result = await asyncio.to_thread(_call)
                    latency = time.time() - start_time
                    input_toks = len(prompt) // 4 + 10
                    output_toks = len(result) // 4 + 10
                    self.last_call_diagnostics = {
                        "provider": "Featherless AI",
                        "model": featherless_model_label(model_name),
                        "model_code": model_name,
                        "latency_sec": round(latency, 2),
                        "input_tokens": input_toks,
                        "output_tokens": output_toks,
                        "status": "Success (API Call)",
                        "cost_usd": self.estimate_cost_usd(model_name, input_toks, output_toks)
                    }
                    return result
                except Exception as e:
                    logger.error(f"Featherless generation failed: {e}. Trying next...")
                    
            elif provider == "gemini" and self.gemini_client:
                try:
                    from google.genai import types
                    model_name = "gemini-2.5-flash"
                    start_time = time.time()
                    def _call():
                        config = types.GenerateContentConfig(
                            system_instruction=system_instruction,
                            temperature=0.7,
                        )
                        response = self.gemini_client.models.generate_content(
                            model=model_name,
                            contents=prompt,
                            config=config
                        )
                        return response.text
                    result = await asyncio.to_thread(_call)
                    latency = time.time() - start_time
                    input_toks = len(prompt) // 4 + 8
                    output_toks = len(result) // 4 + 8
                    self.last_call_diagnostics = {
                        "provider": "Google GenAI",
                        "model": "Gemini 2.5 Flash",
                        "model_code": model_name,
                        "latency_sec": round(latency, 2),
                        "input_tokens": input_toks,
                        "output_tokens": output_toks,
                        "status": "Success (API Call)",
                        "cost_usd": self.estimate_cost_usd(model_name, input_toks, output_toks)
                    }
                    return result
                except Exception as e:
                    logger.error(f"Gemini generation failed: {e}. Trying next...")
                    
            elif provider == "anthropic" and self.anthropic_client:
                try:
                    model_name = "claude-3-5-sonnet-20241022"
                    start_time = time.time()
                    response = await self.anthropic_client.messages.create(
                        model=model_name,
                        max_tokens=1500,
                        system=system_instruction,
                        messages=[{"role": "user", "content": prompt}],
                        temperature=0.7
                    )
                    result = response.content[0].text
                    latency = time.time() - start_time
                    input_toks = len(prompt) // 4
                    output_toks = len(result) // 4
                    self.last_call_diagnostics = {
                        "provider": "Anthropic API",
                        "model": "Claude 3.5 Sonnet",
                        "model_code": model_name,
                        "latency_sec": round(latency, 2),
                        "input_tokens": input_toks,
                        "output_tokens": output_toks,
                        "status": "Success (API Call)",
                        "cost_usd": self.estimate_cost_usd(model_name, input_toks, output_toks)
                    }
                    return result
                except Exception as e:
                    logger.error(f"Anthropic generation failed: {e}. Trying next...")
                    
            elif provider == "openai" and self.openai_client:
                try:
                    model_name = "gpt-4o-mini"
                    start_time = time.time()
                    messages = []
                    if system_instruction:
                        messages.append({"role": "system", "content": system_instruction})
                    messages.append({"role": "user", "content": prompt})
                    response = await self.openai_client.chat.completions.create(
                        model=model_name,
                        messages=messages,
                        temperature=0.7,
                        timeout=45.0
                    )
                    result = response.choices[0].message.content
                    latency = time.time() - start_time
                    input_toks = len(prompt) // 4
                    output_toks = len(result) // 4
                    self.last_call_diagnostics = {
                        "provider": "OpenAI API",
                        "model": "GPT-4o Mini",
                        "model_code": model_name,
                        "latency_sec": round(latency, 2),
                        "input_tokens": input_toks,
                        "output_tokens": output_toks,
                        "status": "Success (API Call)",
                        "cost_usd": self.estimate_cost_usd(model_name, input_toks, output_toks)
                    }
                    return result
                except Exception as e:
                    logger.error(f"OpenAI generation failed: {e}. Trying next...")

        # Fallback diagnostics if no client generated content
        self.last_call_diagnostics = {
            "provider": "AI/ML API Fallback" if self.name in ["Orchestrator", "Competitor Analyst"] else "Featherless Fallback",
            "model": "DeepSeek V4 Flash (Simulated)" if self.name in ["Orchestrator", "Competitor Analyst"] else f"{featherless_model_label()} (Simulated)",
            "model_code": "deepseek-v4-flash" if self.name in ["Orchestrator", "Competitor Analyst"] else os.getenv("FEATHERLESS_MODEL", "Qwen/Qwen2.5-VL-7B-Instruct"),
            "latency_sec": 0.45 if self.name in ["Orchestrator", "Competitor Analyst"] else 0.55,
            "input_tokens": len(prompt) // 4 + 10,
            "output_tokens": len(prompt) // 3 + 40,
            "status": "Mocked (Local Emulated Mode)"
        }
        if self.name in ["Orchestrator", "Competitor Analyst"]:
            self.last_call_diagnostics["cost_usd"] = self.estimate_cost_usd(
                self.last_call_diagnostics["model_code"],
                self.last_call_diagnostics["input_tokens"],
                self.last_call_diagnostics["output_tokens"]
            )
        return ""

    async def run(self, room: Any, context: Dict[str, Any]) -> None:
        raise NotImplementedError("Agents must implement the run() method.")
