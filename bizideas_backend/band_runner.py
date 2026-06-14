"""Connect the four business agents to the live Band platform.

Each agent registers with its own Band identity (UUID + API key) and runs as an
independent participant. They collaborate through a shared Band chat room via
@mentions. Run this alongside the FastAPI server (main.py) when USE_SIMULATOR
is false.

Env vars (see .env.example):
    BAND_<AGENT>_ID / BAND_<AGENT>_KEY  for ORCHESTRATOR, LOCATION_SCOUT,
                                        COMPETITOR_ANALYST, BUSINESS_PLANNER
    BAND_WS_URL  (default wss://app.band.ai/api/v1/socket/websocket)
    BAND_REST_URL (default https://app.band.ai)
"""

from __future__ import annotations

import asyncio
import logging
import os
from typing import List

from dotenv import load_dotenv
load_dotenv()

from band import Agent
from band_agents import (
    OrchestratorBandAdapter,
    LocationScoutBandAdapter,
    CompetitorAnalystBandAdapter,
    BusinessPlannerBandAdapter,
)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("BandRunner")


def _env_or_default(*names: str, default: str) -> str:
    for name in names:
        value = os.getenv(name)
        if value:
            return value
    return default


WS_URL = _env_or_default(
    "BAND_WS_URL",
    "THENVOI_WS_URL",
    default="wss://app.band.ai/api/v1/socket/websocket",
)
REST_URL = _env_or_default("BAND_REST_URL", "THENVOI_REST_URL", default="https://app.band.ai")

# (env-prefix, adapter class) for each agent.
AGENT_SPECS = [
    ("ORCHESTRATOR", OrchestratorBandAdapter),
    ("LOCATION_SCOUT", LocationScoutBandAdapter),
    ("COMPETITOR_ANALYST", CompetitorAnalystBandAdapter),
    ("BUSINESS_PLANNER", BusinessPlannerBandAdapter),
]


def _creds(prefix: str) -> tuple[str | None, str | None]:
    return os.getenv(f"BAND_{prefix}_ID"), os.getenv(f"BAND_{prefix}_KEY")


def build_agents() -> List[Agent]:
    agents: List[Agent] = []
    missing: List[str] = []
    for prefix, adapter_cls in AGENT_SPECS:
        agent_id, api_key = _creds(prefix)
        if not agent_id or not api_key:
            missing.append(prefix)
            continue
        agent = Agent.create(
            adapter=adapter_cls(),
            agent_id=agent_id,
            api_key=api_key,
            ws_url=WS_URL,
            rest_url=REST_URL,
        )
        agents.append(agent)
        logger.info(f"Configured Band agent: {prefix}")
    if missing:
        raise RuntimeError(
            "Missing Band credentials for: "
            + ", ".join(missing)
            + ". Set BAND_<AGENT>_ID and BAND_<AGENT>_KEY in .env "
            "(obtain from the Band dashboard → New Agent → Remote Agent)."
        )
    return agents


async def run() -> None:
    agents = build_agents()
    logger.info(f"Starting {len(agents)} Band agents. Press Ctrl+C to stop.")
    # Each agent.run() connects over WebSocket and processes messages until
    # cancelled. Run them concurrently in this process so they share the
    # per-room state used for the parallel -> merge join.
    await asyncio.gather(*(agent.run() for agent in agents))


if __name__ == "__main__":
    try:
        asyncio.run(run())
    except KeyboardInterrupt:
        logger.info("Band runner stopped.")
