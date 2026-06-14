import asyncio
import os
import logging
import httpx
import re
from typing import List, Dict, Any
from dotenv import load_dotenv
from urllib.parse import urlencode
from utils.city_keys import lookup_city
from utils.market_profile import usd_to_local

load_dotenv()
logger = logging.getLogger("BrightDataClient")

# Mocks and presets removed per user directive to ensure live Bright Data research
LOCAL_EVENTS_PRESETS = {}
LAND_MARKET_PRESETS = {}
ANCHOR_PRESETS = {}


class BrightDataClient:
    _active_zone_lookup_done = False
    _active_zone_cache: str | None = None
    _active_zone_lookup_error: str | None = None

    def __init__(self):
        self.api_key = os.getenv("BRIGHTDATA_API_KEY")
        self.zone_name = os.getenv("BRIGHTDATA_ZONE_NAME") or ""
        self.last_serp_error = None
        self.last_diagnostics = {
            "provider": "Bright Data",
            "status": "not_started",
            "source": "none",
            "events_count": 0,
        }
        self.last_land_diagnostics = {
            "provider": "Bright Data",
            "status": "not_started",
            "source": "none",
            "zones_count": 0,
            "live_listing_count": 0,
        }
        self.last_traffic_diagnostics = {
            "provider": "Bright Data",
            "status": "not_started",
            "source": "none",
            "zones_count": 0,
            "evidence_count": 0,
        }
        self.last_competitor_diagnostics = {
            "provider": "Bright Data",
            "status": "not_started",
            "source": "none",
            "zones_count": 0,
            "competitor_evidence_count": 0,
        }
        self.last_demographics_diagnostics = {
            "provider": "Bright Data",
            "status": "not_started",
            "source": "none",
            "evidence_count": 0,
            "population": None,
        }
        self.last_anchor_diagnostics = {
            "provider": "Bright Data",
            "status": "not_started",
            "source": "none",
            "zones_count": 0,
            "anchor_evidence_count": 0,
        }
        
        self.customer_id = os.getenv("BRIGHTDATA_CUSTOMER_ID")
        self.password = os.getenv("BRIGHTDATA_ZONE_PASSWORD")
        self.proxy_host = os.getenv("BRIGHTDATA_PROXY_HOST", "brd.superproxy.io")
        self.proxy_port = os.getenv("BRIGHTDATA_PROXY_PORT", "22225")

        self.proxy_url = None
        if self.customer_id and self.password and self.zone_name:
            # Bright Data proxy auth format: brd-customer-<id>-zone-<zone>:<password>
            proxy_user = f"brd-customer-{self.customer_id}-zone-{self.zone_name}"
            self.proxy_url = f"http://{proxy_user}:{self.password}@{self.proxy_host}:{self.proxy_port}"

        if self.proxy_url:
            logger.info("Bright Data client initialized with proxy zone '%s'.", self.zone_name)
        elif self.api_key:
            logger.info("Bright Data client initialized with API Key for direct SERP requests.")
        else:
            logger.warning("Bright Data credentials missing in .env. Live web evidence will be unavailable.")

    async def _resolve_zone_name(self) -> str | None:
        if self.zone_name:
            return self.zone_name
        if not self.api_key:
            return None

        if BrightDataClient._active_zone_lookup_done:
            self.zone_name = BrightDataClient._active_zone_cache or ""
            self.last_serp_error = BrightDataClient._active_zone_lookup_error
            return self.zone_name or None

        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.get(
                    "https://api.brightdata.com/zone/get_active_zones",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Accept": "application/json",
                    },
                )
            if response.status_code != 200:
                self.last_serp_error = f"active_zone_lookup_failed_{response.status_code}"
                BrightDataClient._active_zone_lookup_error = self.last_serp_error
                BrightDataClient._active_zone_lookup_done = True
                logger.error(f"Bright Data active-zone lookup failed with status {response.status_code}.")
                return None

            zones = response.json()
            if not isinstance(zones, list) or not zones:
                self.last_serp_error = "no_active_zones"
                BrightDataClient._active_zone_lookup_error = self.last_serp_error
                BrightDataClient._active_zone_lookup_done = True
                logger.error("Bright Data API key is valid, but the account has no active zones.")
                return None

            serp_zone = None
            for zone in zones:
                zone_type = str(zone.get("type") or "").lower()
                zone_name = str(zone.get("name") or "")
                if zone_name and ("serp" in zone_type or "serp" in zone_name.lower()):
                    serp_zone = zone_name
                    break

            if not serp_zone:
                self.last_serp_error = "no_active_serp_zone"
                BrightDataClient._active_zone_lookup_error = self.last_serp_error
                BrightDataClient._active_zone_lookup_done = True
                logger.error("Bright Data account has active zones, but no SERP-compatible zone was found.")
                return None

            self.zone_name = serp_zone
            BrightDataClient._active_zone_cache = serp_zone
            BrightDataClient._active_zone_lookup_error = None
            BrightDataClient._active_zone_lookup_done = True
            logger.info("Bright Data SERP zone auto-discovered from active zones.")
            return self.zone_name
        except Exception as e:
            self.last_serp_error = "active_zone_lookup_error"
            BrightDataClient._active_zone_lookup_error = self.last_serp_error
            BrightDataClient._active_zone_lookup_done = True
            logger.error(f"Bright Data active-zone lookup failed: {e}")
            return None

    def _empty_serp_status(self, with_credentials: str, without_credentials: str) -> str:
        if self.last_serp_error:
            return self.last_serp_error
        return with_credentials if (self.api_key or self.proxy_url) else without_credentials

    def _parse_serp_json(self, data: Any) -> List[Dict[str, Any]]:
        """
        Parses structured SERP JSON results returned by Bright Data.
        Supports both 'organic' and 'organic_results' arrays.
        """
        if not isinstance(data, dict):
            logger.debug("Bright Data response is not a JSON object/dict.")
            return []
            
        results = None
        if "organic" in data and isinstance(data["organic"], list):
            results = data["organic"]
        elif "organic_results" in data and isinstance(data["organic_results"], list):
            results = data["organic_results"]
        elif "results" in data and isinstance(data["results"], list):
            results = data["results"]
            
        if not results:
            logger.warning("No organic search results found in Bright Data JSON response.")
            return []
            
        parsed_events = []
        for res in results[:3]:
            title = res.get("title") or res.get("name") or "Local Event"
            snippet = res.get("description") or res.get("snippet") or res.get("text") or "Local activity details"
            
            # Simple heuristics to extract approximate period
            period = "Annual / Seasonal"
            for month in ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]:
                if month.lower() in snippet.lower() or month.lower() in title.lower():
                    period = month
                    break
                    
            parsed_events.append({
                "name": title,
                "period": period,
                "impact": snippet,
                "type": "Live Event Research"
            })
            
        return parsed_events

    def _extract_serp_results(self, data: Any) -> List[Dict[str, Any]]:
        if not isinstance(data, dict):
            return []

        for key in ("organic", "organic_results", "results"):
            results = data.get(key)
            if isinstance(results, list):
                return results
        return []

    def _search_params(self, query: str, market_profile: Dict[str, Any]) -> Dict[str, str]:
        country = str(market_profile.get("country_code") or "US").lower()
        language = str(market_profile.get("language_code") or "en").lower()
        return {"q": query, "gl": country, "hl": language}

    def _parse_duckduckgo_html(self, html: str) -> List[Dict[str, Any]]:
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(html, "html.parser")
        results = []
        for result in soup.select("div.result"):
            title_elem = result.select_one("a.result__a") or result.select_one("a.result__url")
            snippet_elem = result.select_one("a.result__snippet") or result.select_one(".result__snippet")
            if title_elem:
                title = title_elem.get_text().strip()
                url = title_elem.get("href") or ""
                snippet = snippet_elem.get_text().strip() if snippet_elem else ""
                results.append({
                    "title": title,
                    "link": url,
                    "url": url,
                    "description": snippet,
                    "snippet": snippet,
                })
        return results

    async def _unlocker_fetch(self, target_url: str) -> str | None:
        """
        Fetch a URL's raw HTML through the Bright Data Web Unlocker API request
        endpoint (zone is IP-whitelisted to the VPS). Returns HTML or None.
        """
        if not (self.api_key and self.zone_name):
            return None
        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    "https://api.brightdata.com/request",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json",
                    },
                    json={"zone": self.zone_name, "url": target_url, "format": "raw"},
                )
            if response.status_code == 200:
                self.last_serp_error = None
                return response.text
            self.last_serp_error = f"unlocker_status_{response.status_code}"
            logger.error(f"Bright Data Web Unlocker returned {response.status_code}: {response.text[:200]}")
        except Exception as e:
            self.last_serp_error = "unlocker_error"
            logger.error(f"Bright Data Web Unlocker request failed: {e}")
        return None

    async def _query_serp(self, query: str, market_profile: Dict[str, Any] | None = None) -> List[Dict[str, Any]]:
        market_profile = market_profile or {}
        ddg_url = "https://html.duckduckgo.com/html/?" + urlencode({"q": query})
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }

        # Method 1: DuckDuckGo HTML via Bright Data Web Unlocker (live, reliable).
        html = await self._unlocker_fetch(ddg_url)
        if html:
            results = self._parse_duckduckgo_html(html)
            if results:
                logger.info(f"Bright Data Web Unlocker retrieved {len(results)} live results for: {query}")
                return results

        # Method 2: Direct DuckDuckGo (no proxy) as last-resort live source.
        try:
            async with httpx.AsyncClient(timeout=12.0) as client:
                response = await client.post("https://html.duckduckgo.com/html/", data={"q": query}, headers=headers)
            if response.status_code == 200:
                results = self._parse_duckduckgo_html(response.text)
                if results:
                    logger.info(f"Direct DuckDuckGo retrieved {len(results)} live results for: {query}")
                    return results
        except Exception as e:
            logger.error(f"Direct DuckDuckGo search failed: {e}")

        return []

    def _result_text(self, result: Dict[str, Any]) -> str:
        return " ".join([
            str(result.get("title") or result.get("name") or ""),
            str(result.get("description") or result.get("snippet") or result.get("text") or ""),
        ]).strip()

    def _result_evidence(self, result: Dict[str, Any], query: str = "") -> Dict[str, Any]:
        title = result.get("title") or result.get("name") or "SERP result"
        snippet = result.get("description") or result.get("snippet") or result.get("text") or ""
        url = result.get("link") or result.get("url") or ""
        return {
            "title": str(title)[:120],
            "snippet": str(snippet)[:260],
            "url": url,
            "search_query": query,
        }

    def _parse_population(self, text: str) -> int | None:
        if not text:
            return None

        candidates = []
        pattern = re.compile(
            r"\b([0-9]{1,3}(?:,[0-9]{3})+|[0-9]+(?:\.[0-9]+)?)\s*"
            r"(billion|bn|million|m|thousand|k)?\b",
            re.IGNORECASE,
        )
        for match in pattern.finditer(text.replace("\xa0", " ")):
            raw_value = match.group(1).replace(",", "")
            suffix = (match.group(2) or "").lower()
            try:
                value = float(raw_value)
            except ValueError:
                continue

            if suffix in ("billion", "bn"):
                value *= 1_000_000_000
            elif suffix in ("million", "m"):
                value *= 1_000_000
            elif suffix in ("thousand", "k"):
                value *= 1_000
            elif "." in raw_value and value < 100:
                continue

            parsed = int(value)
            if 5_000 <= parsed <= 1_000_000_000:
                candidates.append(parsed)

        return max(candidates) if candidates else None

    async def research_demographics(
        self,
        city: str,
        market_profile: Dict[str, Any] | None = None,
    ) -> Dict[str, Any]:
        """
        Research population and demographic evidence for the target city using Bright Data SERP.
        Returns only live SERP evidence or an explicit unverified status.
        """
        market_profile = market_profile or {}
        country_name = market_profile.get("country_name") or ""
        
        # Enhanced queries for better population research - always get latest data
        queries = [
            f"{city} {country_name} total population",
            f"{city} {country_name} population census official",
            f"how many people live in {city} {country_name}",
            f"{city} population latest demographics {country_name}",
            f"{city} {country_name} current population statistics",
            f"{city} student population university enrollment {country_name}",
        ]

        evidence = []
        seen = set()
        parsed_population = None
        all_population_candidates = []
        
        # Search through all queries to find population data
        for query in queries:
            results = await self._query_serp(query, market_profile)
            for result in results[:5]:  # Check top 5 results per query
                item = self._result_evidence(result, query)
                normalized = re.sub(r"[^a-z0-9]+", "", f"{item['title']} {item['url']}".lower())
                if normalized in seen:
                    continue
                seen.add(normalized)
                evidence.append(item)

                # Try to extract population from both title and snippet
                population_candidate = self._parse_population(
                    f"{item.get('title', '')} {item.get('snippet', '')}"
                )
                if population_candidate:
                    all_population_candidates.append(population_candidate)
                    print(f"[DEBUG] Found population candidate: {population_candidate:,} from query: {query}")

        # Use the most common population value (mode) or median if available
        if all_population_candidates:
            # Remove outliers - keep values within reasonable range for cities
            filtered_candidates = [p for p in all_population_candidates if 10_000 <= p <= 50_000_000]
            if filtered_candidates:
                # Sort and take median value for accuracy
                filtered_candidates.sort()
                median_index = len(filtered_candidates) // 2
                parsed_population = filtered_candidates[median_index]
                print(f"[DEBUG] Using median population: {parsed_population:,} from {len(filtered_candidates)} candidates")
            elif all_population_candidates:
                # If no values in range, take the most reasonable one
                parsed_population = max(all_population_candidates)
                print(f"[DEBUG] Using max population: {parsed_population:,}")

        # Extract student population info
        parsed_student_pop = None
        parsed_school_market_desc = None
        for item in evidence:
            snippet_lower = item.get("snippet", "").lower()
            title_lower = item.get("title", "").lower()
            combined = f"{title_lower} {snippet_lower}"
            if "student" in combined or "enroll" in combined or "university" in combined or "school" in combined:
                match = re.search(r"\b([0-9]{1,3}(?:,[0-9]{3})+|[0-9]+\s*(?:k|thousand)?)\s*(?:students|enrolled|enrollment|youth)", combined, re.IGNORECASE)
                if match:
                    parsed_student_pop = f"{match.group(1)} students/youth"
                    parsed_school_market_desc = item.get("snippet", "")[:180] + "..."
                    break

        evidence_count = len(evidence)
        
        # Status and confidence are derived ONLY from live scraped evidence.
        # No fabricated population is ever injected — if nothing is parsed the
        # figure is reported as Unavailable so the UI never shows fake data.
        if parsed_population and evidence_count >= 2:
            status = "live"
            source = "Bright Data Live Research"
            confidence = "high" if evidence_count >= 4 else "medium"
            print(f"[SUCCESS] Population research for {city}: {parsed_population:,} (confidence: {confidence}, evidence: {evidence_count} sources)")
        elif parsed_population:
            status = "live"
            source = "Bright Data Live Research"
            confidence = "low"
            print(f"[PARTIAL] Population research for {city}: {parsed_population:,} (single live source)")
        elif evidence_count > 0:
            status = "unverified"
            source = "Bright Data Live Research (population not parsed)"
            confidence = "unverified"
            print(f"[WARNING] Could not parse a population figure from {evidence_count} live items for {city}")
        else:
            status = "unverified"
            source = "Live research unavailable"
            confidence = "unverified"
            print(f"[UNVERIFIED] No live research results for {city}; population reported as Unavailable")

        self.last_demographics_diagnostics = {
            "provider": "Bright Data",
            "status": status,
            "source": source,
            "evidence_count": evidence_count,
            "population": parsed_population,
            "queries_count": len(queries),
            "candidates_found": len(all_population_candidates),
        }
        
        return {
            "city": city,
            "population": parsed_population,
            "population_label": f"{parsed_population:,}" if parsed_population else "Unavailable",
            "student_population": parsed_student_pop or "Unavailable",
            "school_market_desc": parsed_school_market_desc or "",
            "source": source,
            "confidence": confidence,
            "evidence": evidence[:6],
            "search_queries": queries[:3],  # Only show first 3 queries in output
        }

    async def research_anchor_places(
        self,
        city: str,
        zones: List[Dict[str, Any]],
        market_profile: Dict[str, Any] | None = None,
    ) -> List[Dict[str, Any]]:
        """
        Research demand anchors near each candidate zone: malls, markets,
        colleges, schools, and transit hubs. Counts are evidence result
        counts, not a guaranteed complete registry of places.
        """
        market_profile = market_profile or {}
        country_name = market_profile.get("country_name") or ""
        categories = {
            "malls": {
                "query": "malls shopping centers near {zone} {city} {country}",
                "weight": 1.5,
            },
            "public_markets": {
                "query": "public markets grocery markets near {zone} {city} {country}",
                "weight": 1.2,
            },
            "colleges_universities": {
                "query": "colleges universities near {zone} {city} {country}",
                "weight": 1.35,
            },
            "schools": {
                "query": "schools high schools elementary schools near {zone} {city} {country}",
                "weight": 0.9,
            },
            "transit_hubs": {
                "query": "train station bus terminal transit hub near {zone} {city} {country}",
                "weight": 1.1,
            },
        }

        async def query_category(zone: Dict[str, Any], category: str, meta: Dict[str, Any]) -> tuple[str, str, List[Dict[str, Any]]]:
            query = meta["query"].format(
                zone=zone.get("name") or "",
                city=city,
                country=country_name,
            ).strip()
            results = await self._query_serp(query, market_profile)
            evidence = []
            seen = set()
            for result in results[:3]:
                item = self._result_evidence(result, query)
                normalized = re.sub(r"[^a-z0-9]+", "", f"{item['title']} {item['url']}".lower())
                if not item["title"] or normalized in seen:
                    continue
                seen.add(normalized)
                evidence.append(item)
            return category, query, evidence

        researched_zones = []
        total_evidence = 0
        for zone in zones:
            tasks = [
                query_category(zone, category, meta)
                for category, meta in categories.items()
            ]
            category_results = await asyncio.gather(*tasks)

            anchors: Dict[str, List[Dict[str, Any]]] = {}
            counts: Dict[str, int] = {}
            queries = []
            weighted_score = 0.0
            for category, query, evidence in category_results:
                anchors[category] = evidence
                counts[category] = len(evidence)
                queries.append(query)
                total_evidence += len(evidence)
                weighted_score += min(len(evidence), 3) * float(categories[category]["weight"])

            # No fabricated anchors: zones with no live evidence stay at zero.
            zone_evidence = sum(counts.values())
            anchor_score = round(min(10.0, weighted_score), 1) if zone_evidence else 0.0
            if zone_evidence:
                source = "Bright Data Live Research"
                confidence = "medium" if zone_evidence >= 6 else "low"
                anchor_summary = (
                    f"Bright Data returned {zone_evidence} nearby demand-anchor evidence result(s) "
                    f"around {zone.get('name')}."
                )
            else:
                source = "Live research unavailable"
                confidence = "unverified"
                anchor_summary = (
                    "No live demand-anchor evidence was returned for this zone. "
                    "Validate nearby malls, markets, schools, colleges, and transit manually before committing."
                )

            researched_zones.append({
                "zone_name": zone.get("name"),
                "anchor_score": anchor_score,
                "anchor_summary": anchor_summary,
                "anchor_counts": counts,
                "anchors": anchors,
                "source": source,
                "confidence": confidence,
                "search_queries": queries,
            })

        status = "live" if total_evidence else self._empty_serp_status(
            "unverified_no_live_results",
            "missing_credentials",
        )
        self.last_anchor_diagnostics = {
            "provider": "Bright Data",
            "status": status,
            "source": "serp_anchor_research" if total_evidence else "none",
            "zones_count": len(researched_zones),
            "anchor_evidence_count": total_evidence,
            "categories": list(categories.keys()),
        }
        return researched_zones

    def _traffic_score_from_evidence(self, results: List[Dict[str, Any]]) -> float:
        keyword_weights = {
            "foot traffic": 1.2,
            "pedestrian": 1.0,
            "busy": 0.8,
            "shopping": 0.8,
            "retail": 0.7,
            "station": 0.9,
            "transit": 0.8,
            "tourist": 0.8,
            "office": 0.7,
            "university": 0.7,
            "mall": 0.9,
            "downtown": 0.7,
            "central business": 1.0,
            "commercial": 0.8,
            "nightlife": 0.6,
            "restaurant": 0.5,
        }
        score = 4.8 + min(len(results), 8) * 0.28
        combined = " ".join(self._result_text(item).lower() for item in results[:8])
        for keyword, weight in keyword_weights.items():
            if keyword in combined:
                score += weight
        return round(min(9.6, max(1.0, score)), 1)

    def _zone_name_from_result(self, result: Dict[str, Any], city: str, index: int) -> str:
        title = str(result.get("title") or result.get("name") or "").strip()
        if title:
            title = re.split(r"\s[-|:]\s", title)[0]
            title = re.sub(r"\b(best|top|guide|where to|things to do|places to visit)\b", "", title, flags=re.I)
            title = title.replace(city, "").strip(" -:|,")
            title = re.sub(r"\s{2,}", " ", title).strip()
            if 4 <= len(title) <= 60:
                return title
        labels = ["Commercial Core", "Transit Retail Corridor", "Lifestyle Retail District"]
        return labels[min(index, len(labels) - 1)]

    async def research_commercial_zones(
        self,
        city: str,
        business_type: str,
        market_profile: Dict[str, Any] | None = None,
    ) -> List[Dict[str, Any]]:
        market_profile = market_profile or {}
        lat = float(market_profile.get("lat") or 0.0)
        lng = float(market_profile.get("lng") or 0.0)
        country_name = market_profile.get("country_name") or ""
        queries = [
            f"high foot traffic commercial district {city} {country_name} {business_type}",
            f"best retail streets shopping district {city} {country_name}",
            f"busy transit university office corridor {city} {country_name} {business_type}",
        ]

        zones = []
        evidence_count = 0
        offsets = [(0.0048, 0.0048), (-0.0045, -0.0045), (-0.0025, 0.0075)]
        for index, query in enumerate(queries):
            results = await self._query_serp(query, market_profile)
            evidence = []
            for result in results[:4]:
                title = result.get("title") or result.get("name") or "SERP result"
                snippet = result.get("description") or result.get("snippet") or result.get("text") or ""
                url = result.get("link") or result.get("url") or ""
                evidence.append({
                    "title": title,
                    "snippet": snippet[:260],
                    "url": url,
                })

            # No fabricated zones: candidates without live evidence are marked
            # unverified with a zero traffic score, never invented names/scores.
            if evidence:
                evidence_count += len(evidence)
                name = self._zone_name_from_result(results[0], city, index)
                score = self._traffic_score_from_evidence(results)
                source = "Bright Data Live Research"
                confidence = "medium" if len(evidence) >= 3 else "low"
                description = (
                    evidence[0]["snippet"]
                    or f"Bright Data returned live commercial search evidence for {name}."
                )
            else:
                name = f"{city} Candidate Zone {index + 1} (Unverified)"
                score = 0.0
                source = "Live research unavailable"
                confidence = "unverified"
                description = (
                    "No live search evidence was available for this candidate zone. "
                    "Do not treat this as a validated high-traffic site until live data is captured."
                )

            off_lat, off_lng = offsets[index]
            zones.append({
                "name": name,
                "lat": round(lat + off_lat, 6),
                "lng": round(lng + off_lng, 6),
                "traffic_score": score,
                "traffic_source": source,
                "traffic_confidence": confidence,
                "traffic_evidence": evidence,
                "search_query": query,
                "description": description,
            })

        status = "live" if evidence_count else self._empty_serp_status(
            "fallback_after_error",
            "missing_credentials",
        )
        self.last_traffic_diagnostics = {
            "provider": "Bright Data",
            "status": status,
            "source": "serp_traffic_research" if evidence_count else "none",
            "zones_count": len(zones),
            "evidence_count": evidence_count,
        }
        return zones

    async def research_competitors(
        self,
        city: str,
        zones: List[Dict[str, Any]],
        business_type: str,
        market_profile: Dict[str, Any] | None = None,
    ) -> List[Dict[str, Any]]:
        market_profile = market_profile or {}
        enriched_zones = []
        evidence_count = 0

        for zone in zones:
            query = f"{business_type} competitors near {zone.get('name')} {city}"
            results = await self._query_serp(query, market_profile)
            competitors = []
            seen = set()
            for result in results[:10]:
                title = result.get("title") or result.get("name") or ""
                snippet = result.get("description") or result.get("snippet") or result.get("text") or ""
                url = result.get("link") or result.get("url") or ""
                normalized = re.sub(r"[^a-z0-9]+", "", title.lower())
                if not title or normalized in seen:
                    continue
                seen.add(normalized)
                competitors.append({
                    "name": title[:90],
                    "snippet": snippet[:220],
                    "url": url,
                    "source": "Bright Data Live Research",
                })

            # No fabricated competitors: zero live results stays at zero.
            comp_count = len(competitors)
            evidence_count += comp_count

            traffic_score = float(zone.get("traffic_score") or 0.0)
            if comp_count:
                saturation = round(min(9.5, 1.8 + comp_count * 0.65), 1)
                source = "Bright Data Live Research"
                confidence = "medium" if comp_count >= 4 else "low"
            else:
                saturation = 0.0
                source = "Live research unavailable"
                confidence = "unverified"

            opp_score = round((traffic_score * 0.62) + ((10.0 - saturation) * 0.38), 2) if traffic_score else 0.0
            enriched_zones.append({
                **zone,
                "competitor_count": comp_count,
                "saturation_score": saturation,
                "opp_score": opp_score,
                "competitors": [item["name"] for item in competitors],
                "competitor_evidence": competitors,
                "competitor_source": source,
                "competitor_confidence": confidence,
                "competitor_search_query": query,
            })

        enriched_zones.sort(key=lambda x: x.get("opp_score", 0), reverse=True)
        status = "live" if evidence_count else self._empty_serp_status(
            "fallback_after_error",
            "missing_credentials",
        )
        self.last_competitor_diagnostics = {
            "provider": "Bright Data",
            "status": status,
            "source": "serp_competitor_research" if evidence_count else "none",
            "zones_count": len(enriched_zones),
            "competitor_evidence_count": evidence_count,
        }
        return enriched_zones

    def _parse_price(self, text: str, market_profile: Dict[str, Any]) -> int | None:
        if not text:
            return None

        currency_code = re.escape(str(market_profile.get("currency_code") or "USD"))
        currency_symbol = re.escape(str(market_profile.get("currency_symbol") or "$"))
        pattern = re.compile(
            rf"(?:{currency_symbol}|{currency_code}|USD|\$|EUR|€|GBP|£|JPY|¥|PHP|₱)\s*([0-9][0-9,.]*)\s*(million|m|M|k|K|billion|b)?",
            re.IGNORECASE,
        )
        match = pattern.search(text.replace(",", ""))
        if not match:
            return None

        try:
            value = float(match.group(1))
        except ValueError:
            return None

        suffix = (match.group(2) or "").lower()
        if suffix in ("billion", "b"):
            value *= 1_000_000_000
        elif suffix in ("million", "m"):
            value *= 1_000_000
        elif suffix == "k":
            value *= 1_000
        return int(value)

    def _lot_size_for_business(self, business_type: str) -> int:
        normalized = business_type.lower()
        if "work" in normalized or "office" in normalized:
            return 220
        if "retail" in normalized or "boutique" in normalized:
            return 150
        if "restaurant" in normalized:
            return 180
        return 120

    def _default_land_estimate(self, city: str, zone: Dict[str, Any], market_profile: Dict[str, Any]) -> Dict[str, int]:

        traffic = float(zone.get("traffic_score", 7.0))
        country_code = market_profile.get("country_code", "US")
        country_cost_index = {
            "CH": 1.8, "SG": 1.65, "GB": 1.35, "US": 1.25, "JP": 1.2,
            "AE": 1.15, "FR": 1.1, "DE": 1.05, "AU": 1.05, "CA": 1.0,
            "ES": 0.85, "IT": 0.85, "KR": 0.9, "PH": 0.45, "TH": 0.55,
            "MY": 0.55, "ID": 0.45, "VN": 0.4, "IN": 0.35, "BR": 0.5,
            "MX": 0.55, "ZA": 0.45,
        }.get(country_code, 0.75)
        land_usd_per_sqm = (450 + traffic * 180) * country_cost_index
        rent_usd_per_sqm_month = (9 + traffic * 2.8) * country_cost_index
        return {
            "land_price_per_sqm": usd_to_local(land_usd_per_sqm, market_profile),
            "rent_per_sqm_month": usd_to_local(rent_usd_per_sqm_month, market_profile),
        }

    def _land_decision(self, years_to_purchase: float, opp_score: float) -> str:
        if years_to_purchase <= 5.5 and opp_score >= 7.0:
            return "BUY / LAND-BANK"
        if years_to_purchase <= 8.0 and opp_score >= 6.5:
            return "LEASE WITH PURCHASE OPTION"
        return "LEASE FIRST"

    async def _query_land_serp(self, query: str, market_profile: Dict[str, Any] | None = None) -> List[Dict[str, Any]]:
        # Land listings use the same live SERP pipeline (Bright Data SERP zone if
        # available, otherwise DuckDuckGo via the Bright Data proxy).
        return await self._query_serp(query, market_profile)

    async def research_land_listings(
        self,
        city: str,
        zones: List[Dict[str, Any]],
        business_type: str,
        market_profile: Dict[str, Any] | None = None,
    ) -> List[Dict[str, Any]]:
        """
        Research commercial lots near candidate zones and calculate rent-vs-own economics.
        Live listing snippets are used when Bright Data succeeds. If no live
        listing price is extractable, estimates are clearly marked unverified.
        """
        researched_zones = []
        live_listing_count = 0
        required_lot_sqm = self._lot_size_for_business(business_type)
        market_profile = market_profile or {}
        country_name = market_profile.get("country_name") or "target country"

        for zone in zones:
            query = f"commercial lot for sale near {zone.get('name')} {city} {country_name} price"
            raw_results = await self._query_land_serp(query, market_profile)
            listings = []

            for result in raw_results[:3]:
                title = result.get("title") or result.get("name") or "Commercial lot listing"
                snippet = result.get("description") or result.get("snippet") or result.get("text") or ""
                url = result.get("link") or result.get("url") or ""
                parsed_price = self._parse_price(f"{title} {snippet}", market_profile)
                listings.append({
                    "title": title,
                    "snippet": snippet[:240],
                    "url": url,
                    "parsed_price_php": parsed_price,
                    "source": "Bright Data Live Research",
                })

            estimate = self._default_land_estimate(city, zone, market_profile)
            parsed_prices = [item["parsed_price_php"] for item in listings if item.get("parsed_price_php")]
            has_live_price = bool(parsed_prices)
            land_purchase_estimate = int(sum(parsed_prices) / len(parsed_prices)) if parsed_prices else (
                estimate["land_price_per_sqm"] * required_lot_sqm
            )

            # No fabricated listings: count only real scraped listings. When none
            # are found, the economics below are explicitly an unverified estimate.
            live_listing_count += len(listings)

            monthly_rent = estimate["rent_per_sqm_month"] * required_lot_sqm
            annual_rent = monthly_rent * 12
            years_to_purchase = round(land_purchase_estimate / annual_rent, 1) if annual_rent else 0
            carrying_monthly = int(land_purchase_estimate * 0.009)
            opp_score = float(zone.get("opp_score", 0))
            decision = self._land_decision(years_to_purchase, opp_score)

            lat = zone.get("lat")
            lng = zone.get("lng")
            maps_url = f"https://www.google.com/maps/search/?api=1&query={lat},{lng}" if lat and lng else ""

            researched_zones.append({
                "zone_name": zone.get("name"),
                "lat": lat,
                "lng": lng,
                "google_maps_url": maps_url,
                "target_lot_sqm": required_lot_sqm,
                "estimated_rent_php_month": monthly_rent,
                "estimated_rent_php_year": annual_rent,
                "estimated_land_php_per_sqm": estimate["land_price_per_sqm"],
                "estimated_land_purchase_php": land_purchase_estimate,
                "ownership_carrying_cost_php_month": carrying_monthly,
                "years_of_rent_to_purchase": years_to_purchase,
                "decision": decision,
                "site_note": (
                    f"Prioritize frontage within 80-150 meters of the mapped coordinate in {zone.get('name')}. "
                    "Prefer corner or near-crosswalk parcels with delivery access and visible pedestrian approach."
                ),
                "search_query": query,
                "listings": listings,
                "price_basis": "live_listing" if has_live_price else "unverified_estimate",
                "source": "Bright Data Live Research" if has_live_price else "Unverified planning estimate - live listing unavailable",
            })

        status = "live" if live_listing_count else self._empty_serp_status(
            "fallback_after_error",
            "fallback_missing_credentials",
        )
        self.last_land_diagnostics = {
            "provider": "Bright Data",
            "status": status,
            "source": "land_listing_serp" if live_listing_count else "unverified_planning_estimates",
            "zones_count": len(researched_zones),
            "live_listing_count": live_listing_count,
        }
        return researched_zones

    async def research_local_events(self, city: str, market_profile: Dict[str, Any] | None = None) -> List[Dict[str, Any]]:
        """
        Research local events and festivals using the live Bright Data SERP
        pipeline. Returns ONLY live scraped events; if nothing is found it
        returns an empty list (no fabricated/preset events).
        """
        logger.info(f"Researching events for: {city}")
        market_profile = market_profile or {}
        country_name = market_profile.get("country_name") or ""

        query = f"major events festivals calendar in {city} {country_name}".strip()
        results = await self._query_serp(query, market_profile)

        parsed_events = []
        seen = set()
        for res in results[:6]:
            title = res.get("title") or res.get("name")
            if not title:
                continue
            snippet = res.get("description") or res.get("snippet") or res.get("text") or ""
            normalized = re.sub(r"[^a-z0-9]+", "", title.lower())
            if normalized in seen:
                continue
            seen.add(normalized)

            period = "Annual / Seasonal"
            for month in ["January", "February", "March", "April", "May", "June", "July",
                          "August", "September", "October", "November", "December"]:
                if month.lower() in snippet.lower() or month.lower() in title.lower():
                    period = month
                    break

            parsed_events.append({
                "name": str(title)[:120],
                "period": period,
                "impact": str(snippet)[:240] or "Live event evidence from Bright Data research.",
                "type": "Live Event Research",
            })

        if parsed_events:
            self.last_diagnostics = {
                "provider": "Bright Data",
                "status": "live",
                "source": "Bright Data Live Research",
                "events_count": len(parsed_events),
            }
            logger.info(f"Scraped {len(parsed_events)} live events for {city}.")
        else:
            self.last_diagnostics = {
                "provider": "Bright Data",
                "status": "unverified",
                "source": "Live research unavailable",
                "events_count": 0,
            }
            logger.info(f"No live events found for {city}; returning empty (no fabricated events).")

        return parsed_events
