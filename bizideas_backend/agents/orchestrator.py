import asyncio
from typing import Dict, Any
from agents.base import BaseAgent
from utils.brightdata_client import BrightDataClient

class OrchestratorAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="Orchestrator",
            role="Project Manager & Coordinator"
        )

    async def _run_parallel_agents(self, room: Any, context: Dict[str, Any]) -> None:
        from agents.location_scout import LocationScoutAgent
        from agents.competitor_analyst import CompetitorAnalystAgent
        from agents.business_planner import BusinessPlannerAgent

        context["_parallel_mode"] = True
        await room.post_status("Parallel research started: Location Scout and Competitor Analyst are working at the same time.")
        await room.post_orchestration_event(
            stage="parallel_handoff",
            content="Orchestrator dispatched the shared brief to Location Scout and Competitor Analyst in parallel.",
            from_agent="Orchestrator",
            to_agents=["Location Scout", "Competitor Analyst"],
            state="active",
            data={
                "handoff": "Orchestrator -> Location Scout + Competitor Analyst",
                "shared_context_keys": [
                    "events",
                    "zones",
                    "demographics",
                    "anchor_research",
                    "market_profile",
                ],
            },
        )

        await asyncio.gather(
            LocationScoutAgent().run(room, context),
            CompetitorAnalystAgent().run(room, context),
        )

        await room.post_status("Parallel research complete. Business Planner is synthesizing the final report.")
        await room.post_orchestration_event(
            stage="merge_handoff",
            content="Location Scout and Competitor Analyst outputs were merged into one Band context package for Business Planner.",
            from_agent="Location Scout + Competitor Analyst",
            to_agents=["Business Planner"],
            state="active",
            data={
                "handoff": "Parallel research merge -> Business Planner",
                "zone_count": len(context.get("enriched_zones") or context.get("zones") or []),
                "event_count": len(context.get("events") or []),
            },
        )
        await BusinessPlannerAgent().run(room, context)
        await room.post_orchestration_event(
            stage="consensus_closed",
            content="Business Planner finalized consensus and published the PDF deliverable back into the Band room.",
            from_agent="Business Planner",
            to_agents=["User"],
            state="complete",
            data={
                "handoff": "Business Planner -> User",
                "deliverable": "business_plan_pdf",
            },
        )

    async def run_intro_only(self, room: Any, context: Dict[str, Any]) -> None:
        """Band mode: do shared research + post the recruiting intro, but do
        NOT fan out to the other agents in-process. Band routes the @mentions
        in the intro message to the real Location Scout and Competitor Analyst
        agents over the live room."""
        context["_band_mode"] = True
        await self.run(room, context)

    async def run(self, room: Any, context: Dict[str, Any]) -> None:
        business_type = context.get("business_type", "Coffee Shop")
        city = context.get("city", "New York, United States")
        market_profile = context.get("market_profile", {})
        country_name = market_profile.get("country_name", "the target market")
        language_name = market_profile.get("language_name", "English")
        currency_code = market_profile.get("currency_code", "USD")
        currency_symbol = market_profile.get("currency_symbol", "$")
        
        await room.add_participant(self.name)
        await room.post_orchestration_event(
            stage="orchestrator_claimed",
            content="Orchestrator joined the Band room and claimed the coordinator role.",
            from_agent="Band Mesh",
            to_agents=["Orchestrator"],
            state="active",
            data={"handoff": "Band Mesh -> Orchestrator"},
        )
        await asyncio.sleep(1.0)  # Micro-animation timing

        events_client = BrightDataClient()
        traffic_client = BrightDataClient()
        demographics_client = BrightDataClient()
        registration_client = BrightDataClient()

        country = market_profile.get("country_name") or (city.split(",")[-1].strip() if "," in city else city)
        registration_query = f"how to register a {business_type} business in {city} {country} requirements process taxes permits"

        events, zones, demographics, registration_results = await asyncio.gather(
            events_client.research_local_events(city, market_profile),
            traffic_client.research_commercial_zones(city, business_type, market_profile),
            demographics_client.research_demographics(city, market_profile),
            registration_client._query_serp(registration_query, market_profile),
        )
        anchor_client = BrightDataClient()
        anchor_research = await anchor_client.research_anchor_places(city, zones, market_profile)
        context["events"] = events
        context["zones"] = zones
        context["demographics"] = demographics
        context["anchor_research"] = anchor_research
        context["registration_evidence"] = registration_results
        context["registration_query"] = registration_query
        context["brightdata_diagnostics"] = events_client.last_diagnostics
        context["traffic_diagnostics"] = traffic_client.last_traffic_diagnostics
        context["demographics_diagnostics"] = demographics_client.last_demographics_diagnostics
        context["anchor_diagnostics"] = anchor_client.last_anchor_diagnostics
        
        reg_status = "live" if registration_results else ("fallback" if registration_client.last_serp_error else "empty")
        
        await room.post_orchestration_event(
            stage="shared_context_ready",
            content="Orchestrator wrote shared market, traffic, population, anchor, and business registration context into the Band room.",
            from_agent="Orchestrator",
            to_agents=["Location Scout", "Competitor Analyst", "Business Planner"],
            state="complete",
            data={
                "handoff": "Shared context broadcast",
                "zone_count": len(zones),
                "event_count": len(events),
                "traffic_status": traffic_client.last_traffic_diagnostics.get("status"),
                "demographics_status": demographics_client.last_demographics_diagnostics.get("status"),
                "anchor_status": anchor_client.last_anchor_diagnostics.get("status"),
                "registration_status": reg_status,
            },
        )

        anchor_lines = []
        for item in anchor_research:
            counts = item.get("anchor_counts") or {}
            anchor_lines.append(
                f"- {item.get('zone_name')}: anchor evidence score {item.get('anchor_score', 0)}/10; "
                f"malls={counts.get('malls', 0)}, markets={counts.get('public_markets', 0)}, "
                f"colleges/universities={counts.get('colleges_universities', 0)}, schools={counts.get('schools', 0)}, "
                f"transit={counts.get('transit_hubs', 0)}; confidence={item.get('confidence')}"
            )

        system_instruction = (
            "You are the Orchestrator Agent of a multi-agent business scouting system. "
            "Your job is to initiate a new analysis by setting up the brief, recruiting the team, "
            "and outlining the goals. Introduce the session in a professional, collaborative tone. "
            "You have access to shared Bright Data local-event, demographic, traffic, and nearby-anchor research; mention that the same "
            "research context will be available to Location Scout, Competitor Analyst, and Business Planner. "
            "Explain that Location Scout and Competitor Analyst run in parallel, then Business Planner synthesizes their outputs."
            f"Write in {language_name} when possible. Use {currency_code} ({currency_symbol}) for money values."
        )
        
        prompt = (
            f"We are launching a location scouting and planning analysis for a new '{business_type}' "
            f"in '{city}', {country_name}. Please introduce the project, explain that we have recruited "
            f"@Location Scout, @Competitor Analyst, and @Business Planner, and explain the parallel workflow.\n\n"
            f"Market profile: language={language_name}, currency={currency_code} ({currency_symbol}), "
            f"country={country_name}, coordinates={market_profile.get('lat')}, {market_profile.get('lng')}.\n\n"
            f"Population research: {demographics.get('population_label', 'Unavailable')} "
            f"(source={demographics.get('source')}; confidence={demographics.get('confidence')}).\n\n"
            f"Business registration search results: {len(registration_results)} records found.\n\n"
            f"Shared Bright Data event context:\n"
            + "\n".join([f"- {e['name']} ({e['period']}): {e['impact']}" for e in events])
            + "\n\nBright Data traffic research candidates:\n"
            + "\n".join([
                f"- {z['name']}: traffic score {z['traffic_score']}/10; "
                f"source={z.get('traffic_source')}; confidence={z.get('traffic_confidence')}"
                for z in zones
            ])
            + "\n\nNearby demand anchors by zone:\n"
            + ("\n".join(anchor_lines) if anchor_lines else "- No live nearby-anchor evidence returned.")
        )
        import os
        model_label = "DeepSeek V4 Flash" if "deepseek" in os.getenv("AIMLAPI_MODEL", "").lower() else "Claude-Sonnet"
        await room.post_orchestration_event(
            stage="ROUTE",
            content=f"Orchestrator selecting AI/ML API ({model_label}) for task synthesis.",
            from_agent="Orchestrator",
            to_agents=["Band Mesh"],
            state="active"
        )
        await asyncio.sleep(0.4)

        llm_response = await self.call_llm(prompt, system_instruction)
        
        if not llm_response:
            # High-quality fallback text
            llm_response = (
                f"👋 Welcome! I am the **Orchestrator Agent**, and I am initiating a location analysis "
                f"for a proposed **{business_type}** in **{city}**.\n\n"
                f"To find the absolute best location and construct a comprehensive business strategy, "
                f"I have recruited our expert multi-agent panel. **@Location Scout Agent** and "
                f"**@Competitor Analyst Agent** will work in parallel on live Bright Data evidence; "
                f"then **@Business Planner Agent** will synthesize the final report.\n\n"
                f"Parallel research is starting now for a {business_type} in {city}."
            )

        await room.post_text(
            sender=self.name,
            role="agent",
            content=llm_response,
            data={
                "diagnostics": self.last_call_diagnostics,
                "events": events,
                "demographics": demographics,
                "anchor_research": anchor_research,
                "brightdata_diagnostics": events_client.last_diagnostics,
                "traffic_diagnostics": traffic_client.last_traffic_diagnostics,
                "demographics_diagnostics": demographics_client.last_demographics_diagnostics,
                "anchor_diagnostics": anchor_client.last_anchor_diagnostics,
                "zones": zones,
                "market_profile": market_profile,
            }
        )

        # In Band mode, the intro message's @mentions (Location Scout,
        # Competitor Analyst) are routed by the Band platform to those agents'
        # own processes — we must NOT also run them in-process.
        if not context.get("_band_mode"):
            asyncio.create_task(self._run_parallel_agents(room, context))
