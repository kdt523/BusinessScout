import asyncio
import os
from typing import Dict, Any, List
from agents.base import BaseAgent
from utils.pdf_generator import generate_business_plan_pdf
from utils.brightdata_client import BrightDataClient
from utils.market_profile import localize_amount, usd_to_local


SUMMARY_LABELS = {
    "en": {
        "title": "Final Business Plan & Feasibility Consensus",
        "localized_plan": "Localized business plan",
        "prime": "Prime Location Selected",
        "opportunity": "Opportunity Score",
        "traffic": "Foot Traffic Proxy",
        "competitors": "Competitor Count",
        "forecast": "Quarterly Demand Forecasting",
        "pdf": "Deliverable Status",
        "pdf_ok": "PDF Report generated successfully",
        "pdf_failed": "PDF generation failed",
        "site": "Site Acquisition",
        "rent": "rent est.",
        "buy": "buy est.",
        "download": "Download PDF Report",
    },
    "ja": {
        "title": "最終事業計画と実現可能性の合意",
        "localized_plan": "ローカライズされた事業計画",
        "prime": "最有力候補地",
        "opportunity": "機会スコア",
        "traffic": "歩行者交通量の指標",
        "competitors": "競合数",
        "forecast": "四半期需要予測",
        "pdf": "納品状況",
        "pdf_ok": "PDFレポートを生成しました",
        "pdf_failed": "PDF生成に失敗しました",
        "site": "用地取得",
        "rent": "推定賃料",
        "buy": "推定購入額",
        "download": "PDFレポートを開く",
    },
    "fr": {
        "title": "Plan d'affaires final et consensus de faisabilité",
        "localized_plan": "Plan d'affaires localisé",
        "prime": "Emplacement prioritaire",
        "opportunity": "Score d'opportunité",
        "traffic": "Indice de fréquentation piétonne",
        "competitors": "Nombre de concurrents",
        "forecast": "Prévisions trimestrielles de demande",
        "pdf": "Statut du livrable",
        "pdf_ok": "Rapport PDF généré",
        "pdf_failed": "Échec de génération du PDF",
        "site": "Acquisition du site",
        "rent": "loyer estimé",
        "buy": "achat estimé",
        "download": "Ouvrir le rapport PDF",
    },
    "es": {
        "title": "Plan de negocio final y consenso de viabilidad",
        "localized_plan": "Plan de negocio localizado",
        "prime": "Ubicación principal seleccionada",
        "opportunity": "Puntuación de oportunidad",
        "traffic": "Indicador de tráfico peatonal",
        "competitors": "Número de competidores",
        "forecast": "Pronóstico trimestral de demanda",
        "pdf": "Estado del entregable",
        "pdf_ok": "Informe PDF generado",
        "pdf_failed": "Error al generar el PDF",
        "site": "Adquisición del sitio",
        "rent": "alquiler estimado",
        "buy": "compra estimada",
        "download": "Abrir informe PDF",
    },
    "pt": {
        "title": "Plano de negócios final e consenso de viabilidade",
        "localized_plan": "Plano de negócios localizado",
        "prime": "Local principal selecionado",
        "opportunity": "Pontuação de oportunidade",
        "traffic": "Indicador de fluxo de pedestres",
        "competitors": "Número de concorrentes",
        "forecast": "Previsão trimestral de demanda",
        "pdf": "Status da entrega",
        "pdf_ok": "Relatório PDF gerado",
        "pdf_failed": "Falha ao gerar PDF",
        "site": "Aquisição do local",
        "rent": "aluguel estimado",
        "buy": "compra estimada",
        "download": "Abrir relatório PDF",
    },
}


def _labels(language_code: str) -> Dict[str, str]:
    return SUMMARY_LABELS.get((language_code or "en").split("-")[0].lower(), SUMMARY_LABELS["en"])

class BusinessPlannerAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="Business Planner",
            role="Strategic Enterprise Planner"
        )

    async def run(self, room: Any, context: Dict[str, Any]) -> None:
        business_type = context.get("business_type", "Coffee Shop")
        city = context.get("city", "New York, United States")
        enriched_zones = context.get("enriched_zones", [])
        market_profile = context.get("market_profile", {})
        language_code = market_profile.get("language_code", "en")
        language_name = market_profile.get("language_name", "English")
        currency_code = market_profile.get("currency_code", "USD")
        currency_symbol = market_profile.get("currency_symbol", "$")
        labels = _labels(language_code)

        if not enriched_zones:
            base_zones = context.get("zones", [])
            enriched_zones = []
            for zone in base_zones:
                enriched_zones.append({
                    **zone,
                    "competitor_count": 0,
                    "saturation_score": 0.0,
                    "opp_score": float(zone.get("traffic_score") or 0.0),
                    "competitors": [],
                    "competitor_source": "Live Bright Data unavailable",
                    "competitor_confidence": "unverified",
                    "competitor_evidence": [],
                })
        if not enriched_zones:
            enriched_zones = [{
                "name": "Live data unavailable",
                "lat": market_profile.get("lat"),
                "lng": market_profile.get("lng"),
                "traffic_score": 0.0,
                "description": "Bright Data did not return live traffic or competitor evidence for this run.",
                "traffic_source": "Live Bright Data unavailable",
                "traffic_confidence": "unverified",
                "traffic_evidence": [],
                "competitor_count": 0,
                "saturation_score": 0.0,
                "opp_score": 0.0,
                "competitors": [],
                "competitor_source": "Live Bright Data unavailable",
                "competitor_confidence": "unverified",
                "competitor_evidence": [],
            }]

        best_zone = enriched_zones[0]

        await room.add_participant(self.name)
        await asyncio.sleep(2.0)  # Simulate planning synthesis

        # 1. Scenario forecast. These are planning assumptions unless live events support them.
        seasonal_forecast = {
            "Q1 (Jan-Mar - Baseline Scenario)": "100% planning baseline; validate with POS/category benchmarks.",
            "Q2 (Apr-Jun - Warm Season Scenario)": "108% planning scenario; validate against local weather and event evidence.",
            "Q3 (Jul-Sep - Mid-Year Scenario)": "95% planning scenario; validate against local foot-traffic data.",
            "Q4 (Oct-Dec - Holiday Scenario)": "118% planning scenario; validate against local retail calendar and live events."
        }
        
        # Adjust forecast slightly for other business types
        if "retail" in business_type.lower():
            seasonal_forecast = {
                "Q1 (Jan-Mar - New Year)": "90% planning scenario; validate post-holiday demand.",
                "Q2 (Apr-Jun - School / Travel Prep)": "105% planning scenario; validate against category search and retail data.",
                "Q3 (Jul-Sep - Mid-Year)": "92% planning scenario; validate with local foot-traffic evidence.",
                "Q4 (Oct-Dec - Holiday Retail)": "130% planning scenario; validate against local holiday demand evidence."
            }
        elif "work" in business_type.lower():
            # Co-working space
            seasonal_forecast = {
                "Q1 (Jan-Mar - Semester / Project Kickoff)": "108% planning scenario; validate with local school and office calendars.",
                "Q2 (Apr-Jun - Mid-Year)": "95% planning scenario; validate student and corporate booking demand.",
                "Q3 (Jul-Sep - Project Peak)": "105% planning scenario; validate with coworking demand evidence.",
                "Q4 (Oct-Dec - Holiday Slowdown)": "92% planning scenario; validate with local office closure patterns."
            }

        # 2. Build Business Plan Content
        # We try to use LLM to write a custom proposal if key is available
        events = context.get("events", [])
        brightdata_diagnostics = context.get("brightdata_diagnostics", {})
        traffic_diagnostics = context.get("traffic_diagnostics", {})
        competitor_diagnostics = context.get("competitor_diagnostics", {})
        demographics = context.get("demographics") or {}
        demographics_diagnostics = context.get("demographics_diagnostics", {})
        anchor_research = context.get("anchor_research") or []
        anchor_diagnostics = context.get("anchor_diagnostics", {})

        if not demographics:
            demographics_client = BrightDataClient()
            demographics = await demographics_client.research_demographics(city, market_profile)
            demographics_diagnostics = demographics_client.last_demographics_diagnostics
            context["demographics"] = demographics
            context["demographics_diagnostics"] = demographics_diagnostics

        if enriched_zones and not anchor_research:
            anchor_client = BrightDataClient()
            anchor_research = await anchor_client.research_anchor_places(city, enriched_zones, market_profile)
            anchor_diagnostics = anchor_client.last_anchor_diagnostics
            context["anchor_research"] = anchor_research
            context["anchor_diagnostics"] = anchor_diagnostics

        anchor_lookup = {item.get("zone_name"): item for item in anchor_research}

        def anchor_count_summary(item: Dict[str, Any]) -> str:
            counts = item.get("anchor_counts") or {}
            return (
                f"malls={counts.get('malls', 0)}, markets={counts.get('public_markets', 0)}, "
                f"colleges/universities={counts.get('colleges_universities', 0)}, schools={counts.get('schools', 0)}, "
                f"transit={counts.get('transit_hubs', 0)}"
            )

        anchor_lines = [
            (
                f"- {item.get('zone_name')}: anchor evidence score {item.get('anchor_score', 0)}/10; "
                f"{anchor_count_summary(item)}; source={item.get('source')}; confidence={item.get('confidence')}"
            )
            for item in anchor_research
        ]
        demographics_summary = (
            f"Population research for {city}: {demographics.get('population_label', 'Unavailable')} "
            f"(source={demographics.get('source')}; confidence={demographics.get('confidence')})."
        )
        best_anchor = anchor_lookup.get(best_zone.get("name"), {})
        best_anchor_summary = (
            f"Nearby demand anchors for {best_zone.get('name')}: "
            f"{anchor_count_summary(best_anchor)}; score={best_anchor.get('anchor_score', 0)}/10; "
            f"confidence={best_anchor.get('confidence', 'unknown')}."
            if best_anchor
            else "Nearby demand-anchor evidence unavailable; validate malls, markets, schools, colleges, and transit manually."
        )
        events_str = "\n".join([f"- {e['name']} ({e['period']}): {e['impact']}" for e in events])
        brightdata_client = BrightDataClient()

        # Research business strategies and trends for the given business type using Bright Data SERP
        await room.post_orchestration_event(
            stage="STRATEGY_RESEARCH",
            content=f"Business Planner researching strategy and trends for {business_type} via Bright Data...",
            from_agent=self.name,
            to_agents=["Band Mesh"],
            state="active"
        )
        await asyncio.sleep(0.4)

        strategy_research_query = f"{business_type} business model trends best practices strategy"
        strategy_evidence = []
        strategy_diagnostics = {
            "provider": "Bright Data",
            "status": "live",
            "source": "none",
            "results_count": 0,
        }

        try:
            serp_results = await brightdata_client._query_serp(strategy_research_query, market_profile)
            if serp_results:
                for res in serp_results[:4]:
                    title = res.get("title") or res.get("name") or "Strategy Guide"
                    snippet = res.get("description") or res.get("snippet") or res.get("text") or "Details on business operations."
                    url = res.get("link") or res.get("url") or ""
                    strategy_evidence.append({
                        "title": title,
                        "snippet": snippet,
                        "url": url,
                        "search_query": strategy_research_query,
                    })
                strategy_diagnostics = {
                    "provider": "Bright Data",
                    "status": "live",
                    "source": "serp_strategy_research",
                    "results_count": len(strategy_evidence)
                }
            else:
                strategy_diagnostics = {
                    "provider": "Bright Data",
                    "status": "unverified_no_live_results",
                    "source": "none",
                    "results_count": 0,
                }
        except Exception as e:
            import logging
            logging.getLogger("BusinessPlanner").error(f"Failed to query strategy research: {e}")
            strategy_diagnostics = {
                "provider": "Bright Data",
                "status": f"error: {str(e)}",
                "source": "none",
                "results_count": 0,
            }

        # No fabricated strategy presets: if live research returned nothing, the
        # strategy evidence stays empty and is honestly marked unverified.
        if not strategy_evidence:
            strategy_diagnostics = {
                "provider": "Bright Data",
                "status": "unverified_no_live_results",
                "source": "Live research unavailable",
                "results_count": 0,
            }

        strategy_str = "\n".join([
            f"- {s['title']}: {s['snippet']} (source: {s['url']})"
            for s in strategy_evidence
        ]) or "- No live strategy evidence available (Bright Data returned no results)."

        land_research = await brightdata_client.research_land_listings(city, enriched_zones, business_type, market_profile)
        land_diagnostics = brightdata_client.last_land_diagnostics
        context["land_research"] = land_research
        context["land_diagnostics"] = land_diagnostics
        context["strategy_research"] = strategy_evidence
        context["strategy_diagnostics"] = strategy_diagnostics

        # Research business registration and compliance requirements using Bright Data SERP
        await room.post_orchestration_event(
            stage="REGISTRATION_RESEARCH",
            content=f"Business Planner researching business registration and compliance requirements for {business_type} in {city} via Bright Data...",
            from_agent=self.name,
            to_agents=["Band Mesh"],
            state="active"
        )
        await asyncio.sleep(0.4)

        country = market_profile.get("country_name") or (city.split(",")[-1].strip() if "," in city else city)
        registration_query = context.get("registration_query") or f"how to register a {business_type} business in {city} {country} requirements process taxes permits"
        registration_evidence = []
        
        # Read from context if available, otherwise fetch dynamically
        serp_results = context.get("registration_evidence")
        if serp_results is None:
            try:
                serp_results = await brightdata_client._query_serp(registration_query, market_profile)
            except Exception as e:
                import logging
                logging.getLogger("BusinessPlanner").error(f"Failed to query registration research: {e}")
                serp_results = []

        if serp_results:
            for res in serp_results[:5]:
                title = res.get("title") or res.get("name") or "Registration Guide"
                snippet = res.get("description") or res.get("snippet") or res.get("text") or "Details on registering a business."
                url = res.get("link") or res.get("url") or ""
                registration_evidence.append({
                    "title": title,
                    "snippet": snippet,
                    "url": url,
                    "search_query": registration_query,
                })
            registration_diagnostics = {
                "provider": "Bright Data",
                "status": "live",
                "source": "serp_registration_research",
                "results_count": len(registration_evidence)
            }
        else:
            registration_diagnostics = {
                "provider": "Bright Data",
                "status": "unverified_no_live_results",
                "source": "none",
                "results_count": 0,
            }

        # Synthesize a custom registration guide via LLM
        registration_sources_str = "\n".join([
            f"- {r['title']}: {r['snippet']} (Source: {r['url']})"
            for r in registration_evidence
        ])

        system_instruction_reg = (
            f"You are the Business Planner Agent. Write a highly detailed, comprehensive, step-by-step "
            f"business registration and tax compliance guide for starting a {business_type} in {city} ({country}). "
            f"Structure the guide logically with clear steps from business naming, local government registration, "
            f"obtaining necessary licenses and permits (e.g. food/health permits if it's a food business), tax registration, and ongoing compliance/taxation rules.\n"
            f"Use the following Bright Data SERP search evidence to inform your guide:\n{registration_sources_str}\n\n"
            f"Make sure to specify real local agencies (like DTI/SEC/BIR in the Philippines, DED in Dubai, IRS/Secretary of State in the US, Companies House in the UK, etc.) based on the target jurisdiction. "
            f"Do not invent facts if the country is not recognized, but synthesize a highly accurate compliance plan for the target country. "
            f"Structure the output in clean, readable Markdown format with headers, bold text, lists, and clear stages."
        )

        prompt_reg = (
            f"Write a step-by-step business registration and compliance guide for starting a {business_type} in {city} ({country}). "
            f"Provide a step-by-step checklist: \n"
            f"1. Business Name Registration (appropriate local registries)\n"
            f"2. Business Structure & Legal Entity setup\n"
            f"3. Local Government Permits & Licensing (e.g. mayor's permit, sanitary permits, zoning compliance, etc.)\n"
            f"4. Tax Registration & Compliance (local tax identification, sales tax/VAT, monthly/quarterly tax deadlines)\n"
            f"5. Industry-Specific Requirements (e.g., food safety, employee health certificates, environmental clearance)\n\n"
            f"If Bright Data evidence is limited, use your pre-trained knowledge of business law and registrations for {country} to make the guide extremely complete and useful."
        )

        registration_guide_md = await self.call_llm(prompt_reg, system_instruction_reg)

        if not registration_guide_md:
            registration_guide_md = f"""# Business Registration & Compliance Guide: {business_type} in {city}

## Step 1: Legal Entity & Business Name
- Determine if your business will operate as a Sole Proprietorship, Partnership, LLC, or Corporation.
- Register your business name with the appropriate local registry (e.g. Secretary of State, Department of Trade, or Commercial Registry).

## Step 2: Local Permits and Licenses
- Obtain a general Business License from your local municipality or city hall.
- Secure specific permits for your sector:
  - Food & beverage (if applicable): Health, food handling, sanitation, and safety clearances.
  - Retail/Commercial: Zoning permits and fire safety inspections.

## Step 3: Tax Registration & Compliance
- Apply for a national Tax Identification Number (TIN or EIN).
- Register for Value Added Tax (VAT) or Sales Tax with the local tax authority.
- Understand quarterly and annual tax reporting deadlines.

## Step 4: Employment & Labor Regulations
- Register as an employer for social security, health insurance, and accident cover.
- Ensure compliance with local minimum wage laws and working hours regulations.
"""
        context["registration_guide"] = registration_guide_md
        context["registration_diagnostics"] = registration_diagnostics

        system_instruction = (
            f"You are the Business Planner Agent. Write a comprehensive, investor-grade feasibility report for a {business_type} "
            f"located in {best_zone['name']}, {city}. Start with a Findings Summary, then provide detailed analysis for "
            f"Market Demand, Population and Demand Anchors (with a dedicated focus on the schools and student market segment), Location and Traffic Evidence, Competitor Saturation, Customer Segments, Positioning, Operations, "
            f"Marketing/Launch, Site Acquisition, Risk Controls, and Year 1 Financials. Use the shared Bright Data local-event, "
            f"demographic, nearby-anchor, traffic, competitor, land, and strategy evidence for every claim.\n"
            f"Incorporate these specific strategy trends and insights uncovered during research for {business_type}:\n{strategy_str}\n\n"
            "Explain how nearby malls, public markets, colleges, schools, and transit hubs help or weaken the opportunity. "
            "Detail how school calendars, student traffic patterns, and academic semesters impact revenue seasonality. "
            f"Also account for site acquisition: lease-vs-buy logic, mapped coordinates, and commercial land availability. "
            f"Do not invent facts. If live evidence is unavailable, say it is unverified and list what must be validated. "
            f"Write in {language_name} when possible and use {currency_code} ({currency_symbol}) for all money values."
        )

        prompt = (
            f"Write a comprehensive business feasibility report for a proposed {business_type} in {best_zone['name']}, {city}. "
            f"Integrate that it is the best opportunity with a score of {best_zone['opp_score']}/10, "
            f"with {best_zone['competitor_count']} Bright Data competitor evidence results. "
            f"Begin with a concise Findings Summary containing: recommended decision, best location, data confidence, "
            f"top opportunity, top risk, and immediate next steps. Then write detailed sections. "
            f"Do not use Markdown heading markers like # or ## in the final report text.\n\n"
            f"Bright Data event diagnostics: {brightdata_diagnostics}\n"
            f"Bright Data traffic diagnostics: {traffic_diagnostics}\n"
            f"Bright Data competitor diagnostics: {competitor_diagnostics}\n"
            f"Bright Data demographics diagnostics: {demographics_diagnostics}\n"
            f"Bright Data nearby-anchor diagnostics: {anchor_diagnostics}\n"
            f"Bright Data strategy diagnostics: {strategy_diagnostics}\n"
            f"{demographics_summary}\n"
            f"Student/Schools Demographics: {demographics.get('student_population', 'Unavailable')} - {demographics.get('school_market_desc', '')}.\n"
            f"Candidate zones and evidence:\n"
            + "\n".join([
                f"- {z['name']}: traffic={z.get('traffic_score')}/10 source={z.get('traffic_source')} "
                f"confidence={z.get('traffic_confidence')}; competitors={z.get('competitor_count')} "
                f"source={z.get('competitor_source')} confidence={z.get('competitor_confidence')}; "
                f"opportunity={z.get('opp_score')}/10; traffic evidence titles="
                f"{', '.join([str(e.get('title')) for e in (z.get('traffic_evidence') or [])[:3]])}; "
                f"competitor evidence titles={', '.join([str(e.get('name')) for e in (z.get('competitor_evidence') or [])[:5]])}; "
                f"nearby anchor summary={anchor_lookup.get(z.get('name'), {}).get('anchor_summary', 'No anchor research available')}"
                for z in enriched_zones
            ])
            + "\n\nNearby malls, markets, colleges, schools, and transit evidence by zone:\n"
            + ("\n".join(anchor_lines) if anchor_lines else "- No live nearby-anchor evidence returned; validate manually.")
            + "\n\n"
            f"Local events from Bright Data:\n{events_str or '- No live event evidence returned; mark event strategy as validation required.'}\n"
            f"Site acquisition research summary:\n"
            + "\n".join([
                f"- {item['zone_name']}: {item['decision']}; rent {localize_amount(item['estimated_rent_php_month'], market_profile)}/mo; "
                f"buy estimate {localize_amount(item['estimated_land_purchase_php'], market_profile)}; coordinates {item['lat']}, {item['lng']}; "
                f"source={item.get('source')}; live listings={len(item.get('listings') or [])}"
                for item in land_research
            ])
            + "\n"
            f"Make it comprehensive enough for a business owner to decide whether the opportunity is worth pursuing."
        )

        llm_response = await self.call_llm(prompt, system_instruction)

        # Structure plan detail sections
        plan_details = {}
        if llm_response:
            # Parse sections loosely or store the entire response
            plan_details = {
                "executive_summary": f"Proposed launch of a premium {business_type} in {best_zone['name']}, {city}.",
                "demographics": f"{demographics_summary}\nStudent/Schools Market: {demographics.get('student_population', 'Unavailable')} - {demographics.get('school_market_desc', '')}\n{best_anchor_summary}",
                "uvp": "Leveraging market gaps through premium features, high-retention services, and superior customer experience.",
                "marketing": "Launching local geo-targeted social campaigns and opening day specials to drive high foot traffic conversion.",
                "financials": "Projecting healthy year 1 profit margins based on the zone's high opportunity score.",
                "full_plan": llm_response
            }
        else:
            # Premium Fallback Plan Templates
            if "coffee" in business_type.lower() or "cafe" in business_type.lower():
                plan_details = {
                    "executive_summary": (
                        f"Establishing a modern, lifestyle-focused coffee brand in {best_zone['name']}, {city}. "
                        f"By positioning ourselves in the highest opportunity corridor (Index: {best_zone['opp_score']}/10), "
                        f"we capture high foot traffic while neutralizing saturation with a workspace-focused service design."
                    ),
                    "demographics": (
                        f"{demographics_summary}\n"
                        f"Student/Schools Market: {demographics.get('student_population', 'Unavailable')} - {demographics.get('school_market_desc', '')}\n"
                        f"{best_anchor_summary}\n"
                        "• Young Professionals & Freelancers: Requiring comfortable workspace and reliable internet.\n"
                        "• University Students: Seeking social hubs and late-night study spots.\n"
                        "• Shopping Pedestrians: Looking for high-quality beverage stops."
                    ),
                    "uvp": (
                        "• Specialized local and single-origin blends adapted to the target market.\n"
                        "• Integrated Power Outlets at every table and ultra-fast symmetric Wi-Fi (200 Mbps).\n"
                        "• Acoustic zoning separating social spaces from silent working zones."
                    ),
                    "marketing": (
                        "• 'Study & Sip' soft launch opening targeting local university students.\n"
                        "• Local micro-influencer product tastings and social media geotargeting.\n"
                        "• Pre-launch loyalty signups offering a free brew to build customer list."
                    ),
                    "financials": (
                        f"• Estimated Initial Capital Expenditure: {localize_amount(usd_to_local(31000, market_profile), market_profile)}\n"
                        f"• Projected Monthly Gross Revenue (Year 1): {localize_amount(usd_to_local(6000, market_profile), market_profile)}\n"
                        "• Payback / Breakeven Period: ~14 months\n"
                        "• Targeted Net Operating Profit Margin: 28%"
                    )
                }
            else:
                strategy_bullets = "\n".join([f"• **{s['title']}:** {s['snippet']}" for s in strategy_evidence])
                plan_details = {
                    "executive_summary": (
                        f"Launching a specialized {business_type} in {best_zone['name']}, {city}. "
                        f"Analyzing the location's opportunity rating of {best_zone['opp_score']}/10, we plan to capture "
                        f"substantial demand in this commercial area."
                    ),
                    "demographics": (
                        f"{demographics_summary}\n"
                        f"Student/Schools Market: {demographics.get('student_population', 'Unavailable')} - {demographics.get('school_market_desc', '')}\n"
                        f"{best_anchor_summary}\n"
                        "• Residents & Commuters within 2 kilometers.\n"
                        "• Corporate workers and local business owners.\n"
                        "• Digitally active young adults (ages 18-35)."
                    ),
                    "uvp": (
                        f"We integrate the following strategic insights:\n{strategy_bullets}"
                    ),
                    "marketing": (
                        "• Digital geo-fenced advertising on Facebook & Instagram.\n"
                        "• Ribbon cutting launch events featuring local community partnerships.\n"
                        "• Launch week promotional discounts for first-time visitors."
                    ),
                    "financials": (
                        f"• Estimated Initial Setup Costs: {localize_amount(usd_to_local(38000, market_profile), market_profile)}\n"
                        f"• Projected Monthly Gross Revenue (Year 1): {localize_amount(usd_to_local(7200, market_profile), market_profile)}\n"
                        "• Breakeven Estimate: ~16 months\n"
                        "• Target Profit Margin: 25%"
                    )
                }
        plan_details["registration_guide"] = registration_guide_md

        # 3. Generate PDF report
        # Create reports directory in static
        static_reports_dir = os.path.join("static", "reports")
        os.makedirs(static_reports_dir, exist_ok=True)
        
        pdf_filename = f"{room.room_id}_business_plan.pdf"
        pdf_path = os.path.join(static_reports_dir, pdf_filename)
        
        try:
            await room.post_orchestration_event(
                stage="COMPILING",
                content="ReportLab PDF engine compiling styled ledger...",
                from_agent="Business Planner",
                to_agents=["Band Mesh"],
                state="active"
            )
            await asyncio.sleep(0.4)
            generate_business_plan_pdf(
                file_path=pdf_path,
                room_id=room.room_id,
                business_type=business_type,
                city=city,
                zones=enriched_zones,
                seasonal_forecast=seasonal_forecast,
                plan_details=plan_details,
                events=events,
                land_research=land_research,
                demographics=demographics,
                anchor_research=anchor_research,
                brightdata_diagnostics=brightdata_diagnostics,
                traffic_diagnostics=traffic_diagnostics,
                competitor_diagnostics=competitor_diagnostics,
                demographics_diagnostics=demographics_diagnostics,
                anchor_diagnostics=anchor_diagnostics,
                land_diagnostics=land_diagnostics,
                market_profile=market_profile
            )
            import json
            import time
            metadata_path = os.path.join(static_reports_dir, f"{room.room_id}_metadata.json")
            with open(metadata_path, "w", encoding="utf-8") as f:
                json.dump({
                    "room_id": room.room_id,
                    "business_type": business_type,
                    "city": city,
                    "timestamp": time.time(),
                    "pdf_url": f"/api/rooms/{room.room_id}/pdf"
                }, f)
            pdf_url = f"/api/rooms/{room.room_id}/pdf"
            pdf_status = labels["pdf_ok"]
        except Exception as e:
            pdf_url = "#"
            pdf_status = f"{labels['pdf_failed']}: {e}"
        await room.post_orchestration_event(
            stage="planner_synthesis_ready",
            content="Business Planner synthesized the shared Band context into a consensus report and PDF package.",
            from_agent="Business Planner",
            to_agents=["User"],
            state="complete" if pdf_url != "#" else "blocked",
            data={
                "handoff": "Consensus report -> User",
                "pdf_ready": pdf_url != "#",
                "best_zone": best_zone.get("name"),
                "opportunity_score": best_zone.get("opp_score"),
                "land_status": land_diagnostics.get("status"),
            },
        )

        # 4. Post Final Message
        localized_plan = plan_details.get("full_plan", "").strip()
        if localized_plan:
            opening = f"📋 **{labels['title']}**\n\n{localized_plan}\n\n"
        else:
            opening = (
                f"📋 **{labels['title']}**\n\n"
                f"**{labels['localized_plan']}:** {business_type} - {city}\n\n"
                f"🌟 **Unique Value Proposition:**\n{plan_details.get('uvp', '')}\n\n"
                f"📈 **Year 1 Financial Target:**\n{plan_details.get('financials', '')}\n\n"
            )

        summary_markdown = (
            opening
            +
            f"📍 **{labels['prime']}:** **{best_zone['name']}** ({labels['opportunity']}: **{best_zone['opp_score']}/10**)\n"
            f"• *{labels['traffic']}:* {best_zone['traffic_score']}/10\n"
            f"• *{labels['competitors']}:* {best_zone['competitor_count']}\n\n"
            f"• *Population Evidence:* {demographics.get('population_label', 'Unavailable')} ({demographics.get('confidence', 'unknown')})\n"
            f"• *Nearby Demand Anchors:* {best_anchor_summary}\n\n"
            f"📅 **{labels['forecast']}:**\n"
            + "\n".join([f"• *{k}:* {v}" for k, v in seasonal_forecast.items()])
            + f"\n\n"
            f"📄 **{labels['pdf']}:** **{pdf_status}**\n"
            f"🏢 **{labels['site']}:** {land_research[0]['decision']} - {land_research[0]['zone_name']} "
            f"({labels['rent']} {localize_amount(land_research[0]['estimated_rent_php_month'], market_profile)}/mo vs "
            f"{labels['buy']} {localize_amount(land_research[0]['estimated_land_purchase_php'], market_profile)}).\n"
            f"🔗 [{labels['download']}]({pdf_url})"
        )

        await room.post_data(
            sender=self.name,
            content=summary_markdown,
            data={
                "action": "business_planner_results",
                "best_zone": best_zone,
                "zones": enriched_zones,
                "seasonal_forecast": seasonal_forecast,
                "plan_details": plan_details,
                "pdf_url": pdf_url,
                "events": events,
                "demographics": demographics,
                "anchor_research": anchor_research,
                "brightdata_diagnostics": brightdata_diagnostics,
                "traffic_diagnostics": traffic_diagnostics,
                "competitor_diagnostics": competitor_diagnostics,
                "demographics_diagnostics": demographics_diagnostics,
                "anchor_diagnostics": anchor_diagnostics,
                "land_research": land_research,
                "land_diagnostics": land_diagnostics,
                "strategy_research": strategy_evidence,
                "strategy_diagnostics": strategy_diagnostics,
                "registration_diagnostics": registration_diagnostics,
                "market_profile": market_profile,
                "diagnostics": self.last_call_diagnostics
            }
        )

        await room.post_status("Analysis Complete. Multi-agent collaboration session closed.")
