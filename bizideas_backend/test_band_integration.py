"""Offline smoke test for the Band adapters.

Uses the SDK's FakeAgentTools to drive each adapter without live credentials,
proving that (a) the real agent logic runs through BandRoomBridge and (b) the
agents emit Band messages with the correct @mention handoffs.

Run: python test_band_integration.py
"""

import asyncio
import datetime as _dt
import os

for _key in (
    "AIMLAPI_API_KEY",
    "FEATHERLESS_API_KEY",
    "GEMINI_API_KEY",
    "ANTHROPIC_API_KEY",
    "OPENAI_API_KEY",
    "GOOGLE_MAPS_API_KEY",
    "BRIGHTDATA_CUSTOMER_ID",
    "BRIGHTDATA_ZONE_NAME",
    "BRIGHTDATA_ZONE_PASSWORD",
    "BRIGHTDATA_API_KEY",
):
    os.environ[_key] = ""

from band.testing import FakeAgentTools
from band.core.types import PlatformMessage

from band_agents import (
    OrchestratorBandAdapter,
    LocationScoutBandAdapter,
    CompetitorAnalystBandAdapter,
    BusinessPlannerBandAdapter,
    get_room_state,
)
from band_bridge import BandRoomBridge
from agents.competitor_analyst import CompetitorAnalystAgent

ROOM = "test-room-1"


def make_msg(content: str, sender_name: str, sender_type: str = "user") -> PlatformMessage:
    return PlatformMessage(
        id="m1",
        room_id=ROOM,
        content=content,
        sender_id="u1",
        sender_type=sender_type,
        sender_name=sender_name,
        message_type="text",
        metadata={"business_type": "Coffee Shop", "city": "Naga City, Philippines"},
        created_at=_dt.datetime(2026, 6, 12, 23, 0, 0),
    )


async def drive(adapter, msg):
    tools = FakeAgentTools(room_id=ROOM)
    await adapter.on_message(
        msg=msg,
        tools=tools,
        history=None,
        participants_msg=None,
        contacts_msg=None,
        is_session_bootstrap=True,
        room_id=ROOM,
    )
    return tools


async def main():
    print("== 0. Cross-framework agent is configured ==")
    competitor = CompetitorAnalystAgent()
    assert competitor.REASONING_FRAMEWORK == "LangChain"
    assert competitor.reasoner.FRAMEWORK == "LangChain"
    print("   Competitor Analyst internal framework: LangChain OK")

    print("== 0b. Orchestrator recruits discovered peers by capability ==")
    peer_tools = FakeAgentTools(
        room_id=ROOM,
        peers=[
            {
                "name": "Metro Location Scout",
                "handle": "team/location-scout",
                "description": "Commercial zone, site, and traffic scouting",
            },
            {
                "name": "Market Saturation Analyst",
                "handle": "team/competitor-analyst",
                "description": "Competitor saturation and market gap analysis",
            },
            {
                "name": "Expansion Finance Planner",
                "handle": "team/business-planner",
                "description": "Business strategy, finance, and approval memo planning",
            },
            {
                "name": "Unrelated Bot",
                "handle": "team/random",
                "description": "General chat assistant",
            },
        ],
    )
    bridge = BandRoomBridge(ROOM, peer_tools, agent_name="Orchestrator", mirror=False)
    recruited = await OrchestratorBandAdapter()._discover_and_recruit(bridge)
    assert recruited == ["Location Scout", "Competitor Analyst", "Business Planner"]
    assert [p["handle"] for p in peer_tools.participants_added] == [
        "team/location-scout",
        "team/competitor-analyst",
        "team/business-planner",
    ]
    print("   Capability lookup recruited only the required agents: OK")

    print("== 1. Orchestrator reacts to user brief ==")
    tools = await drive(OrchestratorBandAdapter(), make_msg("Start a Coffee Shop in Naga City, Philippines", "User"))
    print(f"   Orchestrator sent {len(tools.messages_sent)} messages")
    joined0 = " ".join(m["content"] for m in tools.messages_sent)
    assert "Location Scout" in joined0, "Orchestrator must recruit Location Scout"
    print("   Orchestrator recruits Location Scout: OK")

    print("== 2. Location Scout reacts to @mention (parallel branch) ==")
    tools = await drive(LocationScoutBandAdapter(), make_msg("@Location Scout please map zones", "Orchestrator", "agent"))
    msgs = tools.messages_sent
    joined = " ".join(m["content"] for m in msgs)
    assert "Business Planner" in joined, "Scout must hand off to Business Planner"
    print(f"   Location Scout sent {len(msgs)} msgs; hands off to Business Planner: OK")

    print("== 3. Competitor Analyst reacts to @mention (parallel branch) ==")
    tools = await drive(CompetitorAnalystBandAdapter(), make_msg("@Competitor Analyst evaluate", "Orchestrator", "agent"))
    msgs = tools.messages_sent
    joined = " ".join(m["content"] for m in msgs)
    assert "Business Planner" in joined, "Analyst must hand off to Business Planner"
    print(f"   Competitor Analyst sent {len(msgs)} msgs; hands off to Business Planner: OK")

    print("== 4. Business Planner synthesizes ==")
    state = await get_room_state(ROOM)
    state.scout_done.set()
    state.analyst_done.set()
    tools = await drive(BusinessPlannerBandAdapter(), make_msg("@Business Planner compile", "Competitor Analyst", "agent"))
    msgs = tools.messages_sent
    print(f"   Business Planner sent {len(msgs)} msgs")

    print("\nALL HANDOFFS VERIFIED through Band tools (offline / no live creds).")


if __name__ == "__main__":
    asyncio.run(main())
