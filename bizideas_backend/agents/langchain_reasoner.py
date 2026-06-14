"""LangChain reasoning engine for the Competitor Analyst agent.

This is what makes the system genuinely *cross-framework*: three of the four
agents (Orchestrator, Location Scout, Business Planner) reason with the
project's native raw-Python `BaseAgent.call_llm` pipeline, while the Competitor
Analyst's internal brain is a LangChain LCEL chain (prompt | model | parser).

All four still collaborate through the SAME Band room — Band is the shared
collaboration layer, not a framework. So this proves agents built with
different frameworks can discover each other, exchange context, and hand off
work through Band, which is the core of the hackathon challenge.

The LangChain chain talks to the AI/ML API (an OpenAI-compatible endpoint) via
`langchain_openai.ChatOpenAI`, or to Featherless/OpenAI as fallbacks. If no key
is configured, `run()` returns an empty string and the agent falls back to its
deterministic template report — identical degradation behaviour to the other
agents.
"""

from __future__ import annotations

import asyncio
import logging
import os
import time
from typing import Dict, Optional

logger = logging.getLogger("LangChainReasoner")


class LangChainReasoner:
    """A LangChain LCEL chain wrapping an OpenAI-compatible chat model.

    Exposes the same `(text, diagnostics)` contract the rest of the system
    uses, so the Competitor Analyst can swap its reasoning backend to LangChain
    without changing how it posts to Band.
    """

    FRAMEWORK = "LangChain"

    def __init__(self):
        self._chain = None
        self._provider_label = None
        self._model_label = None
        self._model_code = None
        self._build_chain()

    def _build_chain(self) -> None:
        """Construct a `ChatPromptTemplate | ChatOpenAI | StrOutputParser` chain.

        We point LangChain's ChatOpenAI at whichever OpenAI-compatible endpoint
        has a key, preferring the AI/ML API (a hackathon technology partner).
        """
        try:
            from langchain_openai import ChatOpenAI
            from langchain_core.prompts import ChatPromptTemplate
            from langchain_core.output_parsers import StrOutputParser
        except Exception as e:  # pragma: no cover - import guard
            logger.warning(f"LangChain not available, reasoner disabled: {e}")
            return

        aimlapi_key = os.getenv("AIMLAPI_API_KEY")
        featherless_key = os.getenv("FEATHERLESS_API_KEY")
        openai_key = os.getenv("OPENAI_API_KEY")

        if aimlapi_key:
            base_url = "https://api.aimlapi.com/v1"
            api_key = aimlapi_key
            self._model_code = os.getenv("AIMLAPI_MODEL", "anthropic/claude-sonnet-4.6")
            self._provider_label = "AI/ML API (via LangChain)"
            self._model_label = "DeepSeek V4 Flash" if "deepseek" in self._model_code.lower() else "Claude 4.6 Sonnet"
        elif featherless_key:
            base_url = "https://api.featherless.ai/v1"
            api_key = featherless_key
            self._model_code = os.getenv("FEATHERLESS_MODEL", "Qwen/Qwen2.5-7B-Instruct")
            self._provider_label = "Featherless AI (via LangChain)"
            self._model_label = "Qwen 2.5"
        elif openai_key:
            base_url = None
            api_key = openai_key
            self._model_code = "gpt-4o-mini"
            self._provider_label = "OpenAI (via LangChain)"
            self._model_label = "GPT-4o Mini"
        else:
            logger.info("No OpenAI-compatible key for LangChain reasoner; will fall back.")
            return

        try:
            model_kwargs = dict(
                model=self._model_code,
                api_key=api_key,
                temperature=0.7,
                timeout=12.0,
                max_retries=0,
            )
            if base_url:
                model_kwargs["base_url"] = base_url
            llm = ChatOpenAI(**model_kwargs)
            prompt = ChatPromptTemplate.from_messages(
                [
                    ("system", "{system_instruction}"),
                    ("human", "{user_prompt}"),
                ]
            )
            self._chain = prompt | llm | StrOutputParser()
            logger.info(f"LangChain reasoner ready ({self._provider_label}, {self._model_code}).")
        except Exception as e:
            logger.error(f"Failed to build LangChain chain: {e}")
            self._chain = None

    @property
    def available(self) -> bool:
        return self._chain is not None

    async def run(self, user_prompt: str, system_instruction: str) -> tuple[str, Dict]:
        """Invoke the LangChain chain. Returns (text, diagnostics).

        On any failure (or when no chain is configured) returns ("", diag) so
        the caller falls back to its deterministic template — matching the rest
        of the system's graceful-degradation behaviour.
        """
        if not self._chain:
            return "", self._fallback_diagnostics()

        start = time.time()
        try:
            result = await self._chain.ainvoke(
                {"system_instruction": system_instruction, "user_prompt": user_prompt}
            )
        except Exception as e:
            logger.error(f"LangChain chain invocation failed: {e}")
            return "", self._fallback_diagnostics()

        latency = time.time() - start
        text = result or ""
        input_toks = len(user_prompt) // 4 + 12
        output_toks = len(text) // 4 + 12
        diagnostics = {
            "framework": self.FRAMEWORK,
            "provider": self._provider_label,
            "model": self._model_label,
            "model_code": self._model_code,
            "latency_sec": round(latency, 2),
            "input_tokens": input_toks,
            "output_tokens": output_toks,
            "status": "Success (LangChain LCEL chain)",
        }
        return text, diagnostics

    def _fallback_diagnostics(self) -> Dict:
        return {
            "framework": self.FRAMEWORK,
            "provider": (self._provider_label or "LangChain") + " Fallback",
            "model": self._model_label or "LangChain (Simulated)",
            "model_code": self._model_code or "langchain/local",
            "latency_sec": 0.5,
            "status": "Mocked (LangChain unavailable / no key)",
        }
