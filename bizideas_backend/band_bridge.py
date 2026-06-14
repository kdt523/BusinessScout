"""Band platform bridge.

Adapts the real Band SDK `AgentToolsProtocol` to the `room` interface that the
existing agents (Orchestrator, Location Scout, Competitor Analyst, Business
Planner) already expect. This lets every agent's real analysis logic — Bright
Data research plus multi-model LLM calls — run unchanged while messages flow
through a live Band chat room instead of the local simulator.

The bridge also mirrors every message into the local simulator room so the
existing SSE stream (and the Flutter visualization) keeps working with no
frontend changes.
"""

from __future__ import annotations

import asyncio
import logging
import os
from typing import Any, Dict, List, Optional

from band_simulator import simulator
from band_simulator import Message  # noqa: F401  (re-exported for callers)

from dotenv import load_dotenv
load_dotenv()

logger = logging.getLogger("BandBridge")

USE_SIMULATOR = os.getenv("USE_SIMULATOR", "true").strip().lower() in ("1", "true", "yes")


def _handle(env_key: str, fallback: str) -> str:
    """Resolve a Band @mention handle from env, stripping any leading '@'."""
    return (os.getenv(env_key) or fallback).lstrip("@")


# Maps our internal agent display names to the real Band @mention handle.
# Band routes mentions by HANDLE (e.g. zrald/scout), not by display name, so
# these must match the handles shown on the Band dashboard. Configured via env
# so the same code works for any account.
AGENT_HANDLES = {
    "Orchestrator": _handle("BAND_ORCHESTRATOR_HANDLE", "Orchestrator"),
    "Location Scout": _handle("BAND_LOCATION_SCOUT_HANDLE", "Location Scout"),
    "Competitor Analyst": _handle("BAND_COMPETITOR_ANALYST_HANDLE", "Competitor Analyst"),
    "Business Planner": _handle("BAND_BUSINESS_PLANNER_HANDLE", "Business Planner"),
}


class BandRoomBridge:
    """Quacks like a simulator `BandRoom`, but writes to a real Band room.

    The existing agents call: add_participant, post_status, post_text,
    post_data, post_orchestration_event, and read `.room_id`. We implement
    each by (1) sending into the live Band room via `tools`, and (2) mirroring
    into the local simulator room (or HTTP API if separated) so the SSE visualization still streams.
    """

    def __init__(self, room_id: str, tools: Any, *, agent_name: str, mirror: bool = True):
        self.room_id = room_id
        self._tools = tools
        self._agent_name = agent_name
        self._mirror_enabled = mirror
        self._mirror_room = None  # lazily resolved simulator room

    async def _mirror(self):
        if not self._mirror_enabled:
            return None
        if self._mirror_room is None:
            self._mirror_room = await simulator.get_or_create_room(self.room_id)
        return self._mirror_room

    async def _mirror_http(
        self,
        sender: str,
        role: str,
        content: str,
        msg_type: str,
        data: Optional[Dict[str, Any]] = None,
    ):
        if not self._mirror_enabled:
            return

        if USE_SIMULATOR:
            # Local in-memory simulator mirroring
            room = await self._mirror()
            if not room:
                return
            if msg_type == "status":
                await room.post_status(content)
            elif msg_type == "orchestration":
                await room.post_orchestration_event(
                    stage=data.get("stage") if data else "",
                    content=content,
                    from_agent=data.get("from_agent") if data else "",
                    to_agents=data.get("to_agents") if data else [],
                    state=data.get("state", "active") if data else "active",
                    data=data,
                )
            elif msg_type == "data":
                await room.post_data(sender, content, data)
            elif msg_type == "participant":
                await room.add_participant(sender)
            else:
                await room.post_text(sender, role, content, data)
        else:
            # Process isolation: post updates to FastAPI server running on localhost
            try:
                import httpx
                port = os.getenv("PORT", "8000")
                url = f"http://127.0.0.1:{port}/api/rooms/{self.room_id}/messages"
                payload = {
                    "sender": sender,
                    "role": role,
                    "content": content,
                    "type": msg_type,
                    "data": data,
                }
                async with httpx.AsyncClient(trust_env=False) as client:
                    resp = await client.post(url, json=payload, timeout=5.0)
                    if resp.status_code != 200:
                        logger.warning(
                            f"HTTP mirroring failed with status {resp.status_code}: {resp.text}"
                        )
            except Exception as e:
                logger.warning(f"Failed to mirror message via HTTP: {e}")

    @staticmethod
    def _extract_mentions(content: str) -> List[str]:
        """Pull @Mentioned Names out of agent text so Band routes the handoff.

        Agents embed handoffs as literal '@Competitor Analyst' / '@Business
        Planner' strings. We translate those into Band mention handles so only
        the intended next agent is activated.
        """
        mentions: List[str] = []
        for name, handle in AGENT_HANDLES.items():
            if f"@{name}" in content:
                mentions.append(handle)
        return mentions

    async def add_participant(self, agent_name: str):
        handle = AGENT_HANDLES.get(agent_name, agent_name)
        try:
            await self._tools.add_participant(handle)
        except Exception as e:
            # Participant may already be present, or self-add is implicit.
            logger.debug(f"add_participant({handle}) noop/failed: {e}")
        await self._mirror_http(
            sender=agent_name, role="participant", content="", msg_type="participant"
        )

    async def post_status(self, content: str):
        try:
            await self._tools.send_event(content=content, message_type="task")
        except Exception as e:
            logger.debug(f"post_status send_event failed, falling back to message: {e}")
            try:
                orch_handle = AGENT_HANDLES.get("Orchestrator", "Orchestrator")
                await self._tools.send_message(f"@{orch_handle} [Status] {content}", mentions=[orch_handle])
            except Exception as e2:
                logger.warning(f"post_status fully failed: {e2}")
        await self._mirror_http(sender="System", role="system", content=content, msg_type="status")

    async def post_text(
        self, sender: str, role: str, content: str, data: Optional[Dict[str, Any]] = None
    ):
        mentions = self._extract_mentions(content)
        if not mentions:
            orch_handle = AGENT_HANDLES.get("Orchestrator", "Orchestrator")
            mentions = [orch_handle]
            if f"@{orch_handle}" not in content:
                content = f"@{orch_handle} {content}"
        try:
            await self._tools.send_message(content, mentions=mentions or None)
        except Exception as e:
            logger.warning(f"post_text send_message failed: {e}")
        await self._mirror_http(
            sender=sender, role=role, content=content, msg_type="text", data=data
        )

    async def post_data(self, sender: str, content: str, data: Dict[str, Any]):
        mentions = self._extract_mentions(content)
        if not mentions:
            orch_handle = AGENT_HANDLES.get("Orchestrator", "Orchestrator")
            mentions = [orch_handle]
            if f"@{orch_handle}" not in content:
                content = f"@{orch_handle} {content}"
        try:
            await self._tools.send_message(content, mentions=mentions or None)
        except Exception as e:
            logger.warning(f"post_data send_message failed: {e}")
        await self._mirror_http(
            sender=sender, role="agent", content=content, msg_type="data", data=data
        )

    async def post_orchestration_event(
        self,
        stage: str,
        content: str,
        from_agent: str = "",
        to_agents: Optional[List[str]] = None,
        state: str = "active",
        data: Optional[Dict[str, Any]] = None,
    ):
        payload = {
            "stage": stage,
            "from_agent": from_agent,
            "to_agents": to_agents or [],
            "state": state,
            **(data or {}),
        }
        try:
            await self._tools.send_event(
                content=content,
                message_type="thought",
                metadata=payload,
            )
        except Exception as e:
            logger.debug(f"orchestration send_event failed: {e}")

        await self._mirror_http(
            sender=from_agent or "System",
            role="system",
            content=content,
            msg_type="orchestration",
            data=payload,
        )
