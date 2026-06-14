"""Real Band agent adapters.

Each of the four business agents becomes a separately-registered Band agent
with its own identity and WebSocket connection. They collaborate through a
live Band chat room via @mentions:

    User ──@Orchestrator──▶ Orchestrator
        broadcasts shared context, then @mentions Location Scout + Competitor Analyst
    Location Scout ──@Competitor Analyst / @Business Planner──▶ ...
    Competitor Analyst ──@Business Planner──▶ Business Planner
        synthesizes consensus + PDF ──▶ User

The agents' real analysis logic (Bright Data + multi-model LLM) is reused
unchanged via BandRoomBridge, which presents the `room` interface they expect.
"""

from __future__ import annotations

import asyncio
import logging
from typing import Any, Dict, Optional

from band.core import SimpleAdapter, HistoryProvider
from band.core.protocols import AgentToolsProtocol
from band.core.types import PlatformMessage

from band_bridge import BandRoomBridge, AGENT_HANDLES
from utils.market_profile import build_market_profile

logger = logging.getLogger("BandAgents")


# ---------------------------------------------------------------------------
# Shared per-room context
#
# The four agents run as independent Band participants but need to share the
# research context that previously lived in a single in-process dict (zones,
# events, demographics, enriched_zones, ...). We key that context by room_id.
# An asyncio.Event per stage lets the Business Planner wait until BOTH the
# Location Scout and Competitor Analyst have committed their findings (the
# parallel -> merge join).
# ---------------------------------------------------------------------------

class RoomState:
    def __init__(self, room_id: str):
        self.room_id = room_id
        self.context: Dict[str, Any] = {}
        self.scout_done = asyncio.Event()
        self.analyst_done = asyncio.Event()
        self.lock = asyncio.Lock()
        # Once-per-room guards so a re-delivered mention can't double-run an agent.
        self.started: Dict[str, bool] = {}

    async def claim_once(self, agent_name: str) -> bool:
        """Return True the first time an agent claims this room, else False."""
        async with self.lock:
            if self.started.get(agent_name):
                return False
            self.started[agent_name] = True
            return True


_ROOM_STATES: Dict[str, RoomState] = {}
_ROOM_STATES_LOCK = asyncio.Lock()


async def get_room_state(room_id: str) -> RoomState:
    async with _ROOM_STATES_LOCK:
        if room_id not in _ROOM_STATES:
            _ROOM_STATES[room_id] = RoomState(room_id)
        return _ROOM_STATES[room_id]


async def ensure_context(state: RoomState, msg: PlatformMessage) -> Dict[str, Any]:
    """Seed shared context from the first user brief if not already present."""
    async with state.lock:
        if state.context:
            return state.context
        # Parse the brief. The user (or Orchestrator recruit message) provides
        # business_type and city. We accept "<business> in <city>" or fall back
        # to metadata on the platform message.
        meta = getattr(msg, "metadata", None) or {}
        if hasattr(meta, "get"):
            business_type = meta.get("business_type")
            city = meta.get("city")
        else:
            business_type = getattr(meta, "business_type", None)
            city = getattr(meta, "city", None)
        if not business_type or not city:
            business_type, city = _parse_brief(msg.content)
        market_profile = await build_market_profile(city)
        state.context = {
            "business_type": business_type,
            "city": city,
            "market_profile": market_profile.to_dict(),
        }
        return state.context


def _parse_brief(content: str) -> tuple[str, str]:
    text = (content or "").strip()
    low = text.lower()
    business_type = "Coffee Shop"
    city = "New York, United States"
    if " in " in low:
        # e.g. "start a Coffee Shop in Tokyo, Japan"
        head, _, tail = text.partition(" in ")
        # strip leading verbs/mentions from head
        for token in ["start", "analyze", "@orchestrator", "a ", "an ", "the "]:
            head = head.replace(token, "").replace(token.title(), "")
        candidate = head.strip(" ,.")
        if candidate:
            business_type = candidate
        if tail.strip():
            city = tail.strip(" ,.")
    return business_type, city


def _mentions_me(msg: PlatformMessage, display_name: str) -> bool:
    """True if this agent is addressed.

    Band only delivers a message to agents that were @mentioned (by handle), so
    a delivered message is almost always meant for us. We still verify by
    matching either the configured Band handle (e.g. zrald/scout) or the
    human-readable display name (e.g. Location Scout) in the content, which also
    makes the offline FakeAgentTools tests work without real handles.
    """
    from band_bridge import AGENT_HANDLES

    content = msg.content or ""
    handle = AGENT_HANDLES.get(display_name, display_name)
    return (f"@{display_name}" in content) or (f"@{handle}" in content) or (handle in content)


# ---------------------------------------------------------------------------
# Adapters
# ---------------------------------------------------------------------------

class _BaseBandAdapter(SimpleAdapter[HistoryProvider]):
    """Common plumbing: build a bridge and run the wrapped agent's logic."""

    AGENT_DISPLAY_NAME = "Agent"

    def __init__(self):
        super().__init__(history_converter=None)

    async def on_message(
        self,
        msg: PlatformMessage,
        tools: AgentToolsProtocol,
        history: HistoryProvider,
        participants_msg: Optional[str],
        contacts_msg: Optional[str],
        *,
        is_session_bootstrap: bool,
        room_id: str,
    ) -> None:
        # Ignore our own emitted messages to avoid loops.
        if (msg.sender_name or "") == self.AGENT_DISPLAY_NAME:
            return
        state = await get_room_state(room_id)
        bridge = BandRoomBridge(room_id, tools, agent_name=self.AGENT_DISPLAY_NAME)
        try:
            await self.handle(msg, bridge, state)
        except Exception as e:
            logger.exception(f"[{self.AGENT_DISPLAY_NAME}] handler error: {e}")
            await bridge.post_status(f"{self.AGENT_DISPLAY_NAME} hit an error: {e}")

    async def handle(self, msg: PlatformMessage, bridge: BandRoomBridge, state: RoomState) -> None:
        raise NotImplementedError


# Capabilities the Orchestrator needs for this workflow, mapped to the agent
# display names that satisfy them. Recruitment matches discovered peers against
# these capability keywords rather than hardcoding who joins the room.
REQUIRED_CAPABILITIES = {
    "Location Scout": ["scout", "location", "geo", "zone", "site"],
    "Competitor Analyst": ["competitor", "analyst", "saturation", "market"],
    "Business Planner": ["planner", "business", "strategy", "finance"],
}


class OrchestratorBandAdapter(_BaseBandAdapter):
    AGENT_DISPLAY_NAME = "Orchestrator"

    async def handle(self, msg, bridge, state):
        # Orchestrator reacts to the initial user brief (or an @Orchestrator ping).
        from agents.orchestrator import OrchestratorAgent

        context = await ensure_context(state, msg)
        agent = OrchestratorAgent()
        # run_intro_only does the shared Bright Data research and posts the
        # recruiting intro WITHOUT the in-process fan-out.
        await agent.run_intro_only(bridge, context)

        # Dynamic, capability-based recruitment: query Band for available peers
        # and recruit the ones whose advertised capabilities match the roles
        # this workflow needs, instead of hardcoding who joins. Falls back to
        # the known roster if discovery is unavailable (offline tests).
        recruited = await self._discover_and_recruit(bridge)

        # Wait for the platform to fully register the joined agents before we mention them
        await asyncio.sleep(4.0)

        scout_in = "Location Scout" in recruited
        analyst_in = "Competitor Analyst" in recruited
        if scout_in or analyst_in:
            kickoff_targets = " ".join(
                f"@{name}" for name in ("Location Scout", "Competitor Analyst")
                if name in recruited
            )
        else:
            # Discovery returned nothing recruitable — fall back to the roster.
            kickoff_targets = "@Location Scout @Competitor Analyst"

        await bridge.post_text(
            sender=self.AGENT_DISPLAY_NAME,
            role="agent",
            content=(
                f"{kickoff_targets} — the shared market, traffic, demographic, "
                "and anchor context is committed to this room. Please begin "
                "your analyses in parallel."
            ),
        )

    async def _discover_and_recruit(self, bridge) -> list[str]:
        """Discover peers on Band and recruit those matching needed capabilities.

        Returns the list of agent display names recruited into the room. Uses
        the live `lookup_peers` / `add_participant` Band APIs through the
        bridge's tools; on any failure (e.g. offline FakeAgentTools without a
        seeded peer list) it degrades to recruiting the full known roster.
        """
        tools = getattr(bridge, "_tools", None)
        recruited: list[str] = []

        peers = []
        if tools is not None and hasattr(tools, "lookup_peers"):
            try:
                result = await tools.lookup_peers()
                if isinstance(result, dict):
                    peers = result.get("peers") or result.get("data") or []
                elif hasattr(result, "data"):
                    peers = result.data
                else:
                    peers = result or []
            except Exception as e:
                logger.debug(f"lookup_peers failed, falling back to roster: {e}")

        matched: Dict[str, str] = {}  # display name -> handle/identifier to recruit
        for peer in peers:
            fields = []
            for k in ("name", "handle", "description", "role", "capabilities"):
                if isinstance(peer, dict):
                    val = peer.get(k)
                else:
                    val = getattr(peer, k, None)
                if val is None:
                    fields.append("")
                elif isinstance(val, list):
                    fields.append(" ".join(str(x) for x in val))
                else:
                    fields.append(str(val))
            text = " ".join(fields).lower()

            if isinstance(peer, dict):
                identifier = peer.get("handle") or peer.get("id") or peer.get("name")
            else:
                identifier = getattr(peer, "handle", None) or getattr(peer, "id", None) or getattr(peer, "name", None)

            for role, keywords in REQUIRED_CAPABILITIES.items():
                if role in matched:
                    continue
                if any(kw in text for kw in keywords):
                    matched[role] = identifier or role

        if not matched:
            # Discovery unavailable/empty: recruit the known roster by name so
            # the workflow still runs (and offline tests still pass).
            matched = {role: AGENT_HANDLES.get(role, role) for role in REQUIRED_CAPABILITIES}
            discovery_note = "no peer directory available — recruiting known roster by capability spec"
        else:
            discovery_note = f"matched {len(matched)} of {len(REQUIRED_CAPABILITIES)} roles from {len(peers)} discovered peers"

        await bridge.post_orchestration_event(
            stage="recruitment",
            content=f"Orchestrator discovering peers on Band and recruiting by capability ({discovery_note}).",
            from_agent="Orchestrator",
            to_agents=list(matched.keys()),
            state="active",
            data={"discovered_peers": len(peers), "matched_roles": list(matched.keys())},
        )

        for role, identifier in matched.items():
            try:
                await tools.add_participant(identifier) if tools is not None else None
            except Exception as e:
                logger.debug(f"add_participant({identifier}) noop/failed: {e}")
            recruited.append(role)

        return recruited


class LocationScoutBandAdapter(_BaseBandAdapter):
    AGENT_DISPLAY_NAME = "Location Scout"

    async def handle(self, msg, bridge, state):
        if not _mentions_me(msg, "Location Scout"):
            return
        if not await state.claim_once(self.AGENT_DISPLAY_NAME):
            return
        from agents.location_scout import LocationScoutAgent

        context = state.context or await ensure_context(state, msg)
        context["_parallel_mode"] = True  # don't fan out in-process
        agent = LocationScoutAgent()
        await agent.run(bridge, context)
        state.scout_done.set()
        # Deterministic handoff to the Business Planner (parallel join target).
        await bridge.post_text(
            sender=self.AGENT_DISPLAY_NAME,
            role="agent",
            content="@Business Planner — zone, traffic, and demand-anchor findings are committed.",
        )


class CompetitorAnalystBandAdapter(_BaseBandAdapter):
    AGENT_DISPLAY_NAME = "Competitor Analyst"

    async def handle(self, msg, bridge, state):
        if not _mentions_me(msg, "Competitor Analyst"):
            return
        if not await state.claim_once(self.AGENT_DISPLAY_NAME):
            return
        from agents.competitor_analyst import CompetitorAnalystAgent

        # The analyst re-uses the shared context (zones from Orchestrator's
        # broadcast); it can also research zones itself if absent.
        context = state.context or await ensure_context(state, msg)
        context["_parallel_mode"] = True
        agent = CompetitorAnalystAgent()
        await agent.run(bridge, context)
        state.analyst_done.set()
        # Deterministic handoff to the Business Planner (parallel join target).
        await bridge.post_text(
            sender=self.AGENT_DISPLAY_NAME,
            role="agent",
            content="@Business Planner — competitor saturation and opportunity scores are committed.",
        )


class BusinessPlannerBandAdapter(_BaseBandAdapter):
    AGENT_DISPLAY_NAME = "Business Planner"

    async def handle(self, msg, bridge, state):
        if not _mentions_me(msg, "Business Planner"):
            return
        # The planner is mentioned by BOTH upstream agents; claim_once ensures
        # it only synthesizes a single consensus report per room.
        if not await state.claim_once(self.AGENT_DISPLAY_NAME):
            return

        from agents.business_planner import BusinessPlannerAgent

        # Merge join: ensure both upstream agents have committed before
        # synthesizing. Wait up to 120s for both, then proceed with whatever
        # context exists (graceful degradation).
        try:
            await asyncio.wait_for(
                asyncio.gather(state.scout_done.wait(), state.analyst_done.wait()),
                timeout=120.0,
            )
        except asyncio.TimeoutError:
            logger.warning("Business Planner proceeding before both upstream agents finished.")

        context = state.context
        agent = BusinessPlannerAgent()
        await agent.run(bridge, context)
