import asyncio
import json
from typing import Dict, Any, List
from agents.base import BaseAgent
from utils.brightdata_client import BrightDataClient
from utils.city_keys import lookup_city

# Curated sample city data. Unknown global cities use geocoded generic zones.
SAMPLE_CITIES = {
    "naga city": {
        "center": {"lat": 13.6218, "lng": 123.1948},
        "zones": [
            {
                "name": "Magsaysay Avenue",
                "lat": 13.6276,
                "lng": 123.1979,
                "traffic_score": 9.5,
                "description": "High foot traffic nightlife, dining, and lifestyle hub. Attracts college students, professionals, and weekend crowds."
            },
            {
                "name": "Centro (Plaza Quince Martires)",
                "lat": 13.6218,
                "lng": 123.1878,
                "traffic_score": 8.8,
                "description": "Traditional commercial center. Dense pedestrian traffic from commuters, local markets, and cathedral visitors."
            },
            {
                "name": "Almeda Highway",
                "lat": 13.6166,
                "lng": 123.2100,
                "traffic_score": 7.2,
                "description": "Expanding development corridor near universities and residential subdivisions. High vehicular traffic."
            }
        ]
    },
    "legazpi": {
        "center": {"lat": 13.1387, "lng": 123.7353},
        "zones": [
            {
                "name": "Landco Business Park",
                "lat": 13.1398,
                "lng": 123.7441,
                "traffic_score": 9.2,
                "description": "Premier business district near malls and transport terminals. Constant flow of shoppers and corporate workers."
            },
            {
                "name": "Rawis Commercial Strip",
                "lat": 13.1610,
                "lng": 123.7420,
                "traffic_score": 7.8,
                "description": "Located near government offices and regional universities. Busy during office hours and school days."
            },
            {
                "name": "Legazpi Boulevard",
                "lat": 13.1330,
                "lng": 123.7540,
                "traffic_score": 6.9,
                "description": "Scenic seaside boulevard. Popular for morning/evening fitness, leisure walkers, and tourists."
            }
        ]
    },
    "daet": {
        "center": {"lat": 14.1122, "lng": 122.9553},
        "zones": [
            {
                "name": "Vinzons Avenue",
                "lat": 14.1170,
                "lng": 122.9550,
                "traffic_score": 9.0,
                "description": "Central highway traversing Daet's commercial core. Heavy pedestrian activity around shops and schools."
            },
            {
                "name": "Moreno District",
                "lat": 14.1030,
                "lng": 122.9640,
                "traffic_score": 7.5,
                "description": "Rapidly expanding commercial and health sector area. High traffic from hospitals and business offices."
            },
            {
                "name": "Bagasbas Beach Road",
                "lat": 14.1350,
                "lng": 122.9870,
                "traffic_score": 6.8,
                "description": "Famous surfing spot. Extreme high traffic on weekends, summer, and holidays; quieter on weekdays."
            }
        ]
    }
}

class LocationScoutAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="Location Scout",
            role="Geographic Analyst & Traffic Expert"
        )

    async def run(self, room: Any, context: Dict[str, Any]) -> None:
        business_type = context.get("business_type", "Coffee Shop")
        city = context.get("city", "New York, United States")
        market_profile = context.get("market_profile", {})
        country_name = market_profile.get("country_name", "the target market")
        language_name = market_profile.get("language_name", "English")

        await room.add_participant(self.name)
        await asyncio.sleep(1.5)  # Simulate analytical processing

        zones = context.get("zones") or []
        traffic_diagnostics = context.get("traffic_diagnostics", {})
        if not zones:
            await room.post_orchestration_event(
                stage="SCRAPE",
                content="Location Scout routing SERP request via Bright Data SuperProxy...",
                from_agent="Location Scout",
                to_agents=["Band Mesh"],
                state="active"
            )
            await asyncio.sleep(0.4)
            brightdata_client = BrightDataClient()
            zones = await brightdata_client.research_commercial_zones(city, business_type, market_profile)
            traffic_diagnostics = brightdata_client.last_traffic_diagnostics
            context["zones"] = zones
            context["traffic_diagnostics"] = traffic_diagnostics

        center_lat = float(market_profile.get("lat") or 0.0)
        center_lng = float(market_profile.get("lng") or 0.0)
        city_data = {"center": {"lat": center_lat, "lng": center_lng}, "zones": zones}

        # Reuse shared Bright Data research from Orchestrator when available.
        brightdata_diagnostics = context.get("brightdata_diagnostics")
        events = context.get("events")
        if not events:
            brightdata_client = BrightDataClient()
            events = await brightdata_client.research_local_events(city, market_profile)
            brightdata_diagnostics = brightdata_client.last_diagnostics
        context["events"] = events
        context["brightdata_diagnostics"] = brightdata_diagnostics

        demographics = context.get("demographics") or {}
        demographics_diagnostics = context.get("demographics_diagnostics", {})
        if not demographics:
            demographics_client = BrightDataClient()
            demographics = await demographics_client.research_demographics(city, market_profile)
            demographics_diagnostics = demographics_client.last_demographics_diagnostics
            context["demographics"] = demographics
            context["demographics_diagnostics"] = demographics_diagnostics

        anchor_research = context.get("anchor_research") or []
        anchor_diagnostics = context.get("anchor_diagnostics", {})
        if zones and not anchor_research:
            anchor_client = BrightDataClient()
            anchor_research = await anchor_client.research_anchor_places(city, zones, market_profile)
            anchor_diagnostics = anchor_client.last_anchor_diagnostics
            context["anchor_research"] = anchor_research
            context["anchor_diagnostics"] = anchor_diagnostics

        anchor_lookup = {item.get("zone_name"): item for item in anchor_research}
        anchor_lines = []
        for item in anchor_research:
            counts = item.get("anchor_counts") or {}
            anchor_lines.append(
                f"- {item.get('zone_name')}: anchor score {item.get('anchor_score', 0)}/10; "
                f"malls={counts.get('malls', 0)}, markets={counts.get('public_markets', 0)}, "
                f"colleges/universities={counts.get('colleges_universities', 0)}, schools={counts.get('schools', 0)}, "
                f"transit hubs={counts.get('transit_hubs', 0)}; source={item.get('source')}; confidence={item.get('confidence')}"
            )

        # Call LLM to embellish the analysis if key exists
        system_instruction = (
            f"You are the Location Scout Agent. Your goal is to evaluate geographic zones for a {business_type} "
            f"in {city}, {country_name}. Detail 3 locations, explaining their specific foot traffic profiles and potential. "
            "For each zone, explain how nearby malls, public markets, colleges, schools, and transit hubs could support demand. "
            "Specifically analyze the schools/student market demographic suitability (e.g. university crowds, school hours traffic, and study-sip spots). "
            "Use population and anchor-place evidence only when Bright Data returned it; otherwise mark it as unverified. "
            f"Write in {language_name} when possible and use globally relevant commercial terminology. "
            f"Also, review these local events/festivals and explain how they create seasonal customer surges: "
            + ", ".join([f"{e['name']} ({e['period']})" for e in events])
        )
        
        prompt = (
            f"Explain the geographic suitability of these 3 locations in {city} for a {business_type}:\n"
            + "\n".join([
                f"- {z['name']}: Bright Data traffic score {z['traffic_score']}/10; "
                f"source={z.get('traffic_source')}; confidence={z.get('traffic_confidence')}. "
                f"Evidence basis: {z['description']}. "
                f"Nearby anchor evidence: {anchor_lookup.get(z.get('name'), {}).get('anchor_summary', 'No anchor research available')}"
                for z in zones
            ])
            + f"\n\nPopulation research for {city}: {demographics.get('population_label', 'Unavailable')} "
            + f"(source={demographics.get('source')}; confidence={demographics.get('confidence')}).\n"
            + f"Student Market Demographics: {demographics.get('student_population', 'Unavailable')} - {demographics.get('school_market_desc', '')}.\n"
            + "Nearby malls, markets, schools, colleges, and transit evidence by zone:\n"
            + ("\n".join(anchor_lines) if anchor_lines else "- No live nearby-anchor evidence returned.")
            + f"\n\nAlso analyze the seasonal impact of these researched local events:\n"
            + "\n".join([f"- {e['name']} ({e['period']}): {e['impact']}" for e in events])
        )

        llm_response = await self.call_llm(prompt, system_instruction)

        if not llm_response:
            # Build clean fallback text report
            llm_response = (
                f"📊 **Geographic Scouting Report for {business_type} in {city}**\n\n"
                f"I have mapped the target area and identified 3 key commercial zones. "
                f"Here is my assessment of pedestrian flow and suitability:\n\n"
            )
            for z in zones:
                llm_response += (
                    f"📍 **{z['name']}**\n"
                    f"• *Coordinates:* {z['lat']}, {z['lng']}\n"
                    f"• *Bright Data Traffic Score:* **{z['traffic_score']}/10**\n"
                    f"• *Source:* {z.get('traffic_source')} ({z.get('traffic_confidence')})\n"
                    f"• *Evidence Basis:* {z['description']}\n\n"
                )
            llm_response += (
                f"Population evidence for {city}: {demographics.get('population_label', 'Unavailable')} "
                f"({demographics.get('source')}, {demographics.get('confidence')}).\n"
                f"Student/Schools Demographics: {demographics.get('student_population', 'Estimated 15-20%')} - {demographics.get('school_market_desc', '')}.\n\n"
                "Nearby demand-anchor evidence:\n"
            )
            for item in anchor_research:
                counts = item.get("anchor_counts") or {}
                llm_response += (
                    f"• **{item.get('zone_name')}**: anchor score {item.get('anchor_score', 0)}/10; "
                    f"malls {counts.get('malls', 0)}, markets {counts.get('public_markets', 0)}, "
                    f"colleges/universities {counts.get('colleges_universities', 0)}, schools {counts.get('schools', 0)}, "
                    f"transit {counts.get('transit_hubs', 0)}. {item.get('anchor_summary')}\n"
                )
            
            llm_response += f"🗓️ **Researched Local Event Calibrations (Bright Data Scraped):**\n"
            for e in events:
                llm_response += f"• **{e['name']}** ({e['period']}): {e['impact']}\n"
                
            llm_response += f"\n**@Competitor Analyst**, please review these 3 zones and evaluate the competitor saturation."

        # Pass zones to context for next agent
        context["zones"] = zones
        await room.post_orchestration_event(
            stage="location_package_ready",
            content="Location Scout committed zone, event, population, and demand-anchor findings to the Band room.",
            from_agent="Location Scout",
            to_agents=["Competitor Analyst", "Business Planner"],
            state="complete",
            data={
                "handoff": "Location package -> downstream agents",
                "zone_count": len(zones),
                "event_count": len(events or []),
                "anchor_zone_count": len(anchor_research or []),
                "traffic_status": traffic_diagnostics.get("status"),
                "demographics_status": demographics_diagnostics.get("status"),
                "anchor_status": anchor_diagnostics.get("status"),
            },
        )

        # Post structured data message
        await room.post_data(
            sender=self.name,
            content=llm_response,
            data={
                "action": "location_scout_results",
                "center": city_data["center"],
                "zones": zones,
                "events": events,
                "demographics": demographics,
                "anchor_research": anchor_research,
                "brightdata_diagnostics": brightdata_diagnostics,
                "traffic_diagnostics": traffic_diagnostics,
                "demographics_diagnostics": demographics_diagnostics,
                "anchor_diagnostics": anchor_diagnostics,
                "diagnostics": self.last_call_diagnostics
            }
        )
        if not context.get("_parallel_mode"):
            from agents.competitor_analyst import CompetitorAnalystAgent
            analyst = CompetitorAnalystAgent()
            asyncio.create_task(analyst.run(room, context))
