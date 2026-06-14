import asyncio
import json
from typing import Dict, Any, List
from agents.base import BaseAgent
from utils.city_keys import lookup_city
from utils.brightdata_client import BrightDataClient

# Competitor profile presets
COMPETITOR_PRESETS = {
    "naga city": {
        "Magsaysay Avenue": {
            "count": 14,
            "saturation": 9.2,
            "competitors": ["Starbucks", "Bo's Coffee", "The Coffee Bean & Tea Leaf", "Beanbag Cafe", "Local Brew Co.", "Café Plazuela", "Daily Grind"]
        },
        "Centro (Plaza Quince Martires)": {
            "count": 7,
            "saturation": 6.8,
            "competitors": ["Dunkin' Donuts", "Jollibee Coffee Corner", "Centro Brews", "Baker's Plaza", "Plaza Café"]
        },
        "Almeda Highway": {
            "count": 2,
            "saturation": 3.2,
            "competitors": ["Almeda Highway Café", "Highway Pitstop Coffee"]
        }
    },
    "legazpi": {
        "Landco Business Park": {
            "count": 11,
            "saturation": 8.7,
            "competitors": ["Starbucks Landco", "Bo's Coffee Legazpi", "The Coffee Bean", "Bicol Brew", "First Colonial Café"]
        },
        "Rawis Commercial Strip": {
            "count": 4,
            "saturation": 5.2,
            "competitors": ["Rawis Bistro", "Uni-Cup Café", "Office Brews"]
        },
        "Legazpi Boulevard": {
            "count": 1,
            "saturation": 2.1,
            "competitors": ["Boulevard Brew & View"]
        }
    },
    "daet": {
        "Vinzons Avenue": {
            "count": 8,
            "saturation": 7.9,
            "competitors": ["Starbucks Daet", "Bo's Coffee Vinzons", "Local Beans Daet", "Café de Daet"]
        },
        "Moreno District": {
            "count": 2,
            "saturation": 3.8,
            "competitors": ["Moreno Coffee Hub", "Med-Bites Cafe"]
        },
        "Bagasbas Beach Road": {
            "count": 3,
            "saturation": 5.5,
            "competitors": ["Bagasbas Surf Café", "Wave Coffee & Shakes"]
        }
    }
}

class CompetitorAnalystAgent(BaseAgent):
    """Cross-framework agent: reasons with a LangChain LCEL chain.

    Unlike the other three agents (which use the native raw-Python
    `BaseAgent.call_llm` pipeline), this agent's internal brain is built with
    LangChain. It still collaborates with the rest of the team through the same
    Band room — proving agents from *different frameworks* can discover each
    other, share context, and hand off work via Band.
    """

    REASONING_FRAMEWORK = "LangChain"

    def __init__(self):
        super().__init__(
            name="Competitor Analyst",
            role="Market Saturation Specialist"
        )
        from agents.langchain_reasoner import LangChainReasoner
        self.reasoner = LangChainReasoner()

    async def run(self, room: Any, context: Dict[str, Any]) -> None:
        business_type = context.get("business_type", "Coffee Shop")
        city = context.get("city", "New York, United States")
        zones = context.get("zones", [])
        events = context.get("events", [])
        brightdata_diagnostics = context.get("brightdata_diagnostics", {})
        traffic_diagnostics = context.get("traffic_diagnostics", {})
        demographics = context.get("demographics") or {}
        demographics_diagnostics = context.get("demographics_diagnostics", {})
        anchor_research = context.get("anchor_research") or []
        anchor_diagnostics = context.get("anchor_diagnostics", {})
        market_profile = context.get("market_profile", {})
        country_name = market_profile.get("country_name", "the target market")
        language_name = market_profile.get("language_name", "English")

        await room.add_participant(self.name)
        await asyncio.sleep(1.8)  # Simulate scanning competitor databases

        brightdata_client = BrightDataClient()
        if not zones:
            zones = await brightdata_client.research_commercial_zones(city, business_type, market_profile)
            traffic_diagnostics = brightdata_client.last_traffic_diagnostics
            context["zones"] = zones
            context["traffic_diagnostics"] = traffic_diagnostics

        if not demographics:
            demographics_client = BrightDataClient()
            demographics = await demographics_client.research_demographics(city, market_profile)
            demographics_diagnostics = demographics_client.last_demographics_diagnostics
            context["demographics"] = demographics
            context["demographics_diagnostics"] = demographics_diagnostics

        if zones and not anchor_research:
            anchor_client = BrightDataClient()
            anchor_research = await anchor_client.research_anchor_places(city, zones, market_profile)
            anchor_diagnostics = anchor_client.last_anchor_diagnostics
            context["anchor_research"] = anchor_research
            context["anchor_diagnostics"] = anchor_diagnostics

        await room.post_orchestration_event(
            stage="SCRAPE",
            content="Competitor Analyst scanning local listings via Bright Data Web Unlocker...",
            from_agent="Competitor Analyst",
            to_agents=["Band Mesh"],
            state="active"
        )
        await asyncio.sleep(0.4)
        enriched_zones = await brightdata_client.research_competitors(city, zones, business_type, market_profile)
        competitor_diagnostics = brightdata_client.last_competitor_diagnostics
        context["enriched_zones"] = enriched_zones
        context["competitor_diagnostics"] = competitor_diagnostics
        anchor_lookup = {item.get("zone_name"): item for item in anchor_research}
        await room.post_orchestration_event(
            stage="competitor_package_ready",
            content="Competitor Analyst committed saturation and opportunity scores to the Band room.",
            from_agent="Competitor Analyst",
            to_agents=["Business Planner"],
            state="complete",
            data={
                "handoff": "Competitor package -> Business Planner",
                "zone_count": len(enriched_zones),
                "competitor_status": competitor_diagnostics.get("status"),
                "competitor_evidence_count": competitor_diagnostics.get("competitor_evidence_count", 0),
                "best_zone": enriched_zones[0].get("name") if enriched_zones else "",
            },
        )

        # Format prompt
        system_instruction = (
            f"You are the Competitor Analyst Agent. Your task is to analyze competitive presence in these zones "
            f"for a {business_type} in {city}, {country_name}. Compare foot traffic and saturation, highlighting where the gap "
            "remains attractive because of nearby demand anchors such as malls, public markets, colleges, schools, and transit hubs. "
            "Use population and anchor-place evidence only when Bright Data returned it; otherwise mark it as unverified. "
            f"or blue ocean opportunity exists. Use the shared Bright Data local-event context to explain where "
            f"seasonal spikes may temporarily increase competition pressure. Write in {language_name} when possible."
        )

        prompt = (
            f"Analyze the market saturation for a {business_type} in {city} across these 3 zones:\n"
            + "\n".join([
                f"- {z['name']}: Traffic Score {z['traffic_score']}/10, Competitors: {z['competitor_count']} (Saturation: {z['saturation_score']}/10). "
                f"Calculated Opportunity Score: {z['opp_score']}/10. "
                f"Competitor source={z.get('competitor_source')}; confidence={z.get('competitor_confidence')}. "
                f"Demand-anchor evidence: {anchor_lookup.get(z.get('name'), {}).get('anchor_summary', 'No anchor research available')}."
                for z in enriched_zones
            ])
            + f"\n\nPopulation research for {city}: {demographics.get('population_label', 'Unavailable')} "
            + f"(source={demographics.get('source')}; confidence={demographics.get('confidence')})."
            + "\n\nShared Bright Data event context:\n"
            + "\n".join([f"- {e['name']} ({e['period']}): {e['impact']}" for e in events])
        )

        await room.post_orchestration_event(
            stage="ROUTE",
            content="Competitor Analyst reasoning via LangChain LCEL chain (cross-framework agent).",
            from_agent="Competitor Analyst",
            to_agents=["Band Mesh"],
            state="active",
            data={"framework": self.REASONING_FRAMEWORK},
        )
        await asyncio.sleep(0.4)

        llm_response, reasoner_diagnostics = await self.reasoner.run(prompt, system_instruction)
        # Record which framework produced this turn so the UI/diagnostics can
        # show that this agent is built differently from its peers.
        self.last_call_diagnostics = reasoner_diagnostics

        if not llm_response:
            # Build detailed fallback report
            llm_response = (
                f"🛡️ **Market Saturation & Competitor Analysis Report**\n\n"
                f"I have mapped all active local competitors matching **{business_type}** in our candidate zones. "
                f"Here are my findings and calculations of the **Opportunity Index**:\n\n"
            )
            for z in enriched_zones:
                opp_status = "🔥 Prime Opportunity (Low saturation, solid traffic)" if z["opp_score"] >= 7.0 else \
                             "⚖️ Balanced Market (Moderate competition)" if z["opp_score"] >= 6.0 else \
                             "⚠️ Highly Saturated (Intense competition)"
                llm_response += (
                    f"📍 **{z['name']}**\n"
                    f"• *Competitor Evidence Count:* {z['competitor_count']} Bright Data SERP results\n"
                    f"• *Saturation Index:* **{z['saturation_score']}/10**\n"
                    f"• *Opportunity Score:* **{z['opp_score']}/10** ({opp_status})\n"
                    f"• *Primary Competitor Evidence:* {', '.join(z['competitors'][:4]) or 'No live competitor evidence returned'}\n"
                    f"• *Source:* {z.get('competitor_source')} ({z.get('competitor_confidence')})\n\n"
                )
            llm_response += (
                f"🏆 **Recommendation:** **{enriched_zones[0]['name']}** offers the highest opportunity gap "
                f"with a score of **{enriched_zones[0]['opp_score']}/10**.\n\n"
                f"**@Business Planner**, I am handing off this analysis to you to project seasonal demand and build the final business plan."
            )

        # Post structured data message
        await room.post_data(
            sender=self.name,
            content=llm_response,
            data={
                "action": "competitor_analyst_results",
                "enriched_zones": enriched_zones,
                "events": events,
                "demographics": demographics,
                "anchor_research": anchor_research,
                "brightdata_diagnostics": brightdata_diagnostics,
                "traffic_diagnostics": traffic_diagnostics,
                "competitor_diagnostics": competitor_diagnostics,
                "demographics_diagnostics": demographics_diagnostics,
                "anchor_diagnostics": anchor_diagnostics,
                "diagnostics": self.last_call_diagnostics
            }
        )
        if not context.get("_parallel_mode"):
            from agents.business_planner import BusinessPlannerAgent
            planner = BusinessPlannerAgent()
            asyncio.create_task(planner.run(room, context))
