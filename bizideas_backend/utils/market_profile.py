import logging
from dataclasses import asdict, dataclass
from typing import Any, Dict, Optional

import httpx
from babel import Locale
from babel.core import get_global
from babel.numbers import format_currency, get_currency_symbol, get_territory_currencies

logger = logging.getLogger("MarketProfile")


COUNTRY_ALIASES = {
    "usa": "US",
    "u.s.a.": "US",
    "united states": "US",
    "united states of america": "US",
    "uk": "GB",
    "u.k.": "GB",
    "united kingdom": "GB",
    "uae": "AE",
    "u.a.e.": "AE",
    "united arab emirates": "AE",
    "philippines": "PH",
    "japan": "JP",
    "france": "FR",
    "germany": "DE",
    "italy": "IT",
    "spain": "ES",
    "canada": "CA",
    "australia": "AU",
    "singapore": "SG",
    "malaysia": "MY",
    "thailand": "TH",
    "indonesia": "ID",
    "vietnam": "VN",
    "india": "IN",
    "china": "CN",
    "south korea": "KR",
    "korea": "KR",
    "mexico": "MX",
    "brazil": "BR",
    "south africa": "ZA",
    "saudi arabia": "SA",
    "qatar": "QA",
    "netherlands": "NL",
    "switzerland": "CH",
    "sweden": "SE",
    "norway": "NO",
    "denmark": "DK",
    "new zealand": "NZ",
}

CITY_COUNTRY_HINTS = {
    "new york": "US",
    "los angeles": "US",
    "san francisco": "US",
    "london": "GB",
    "paris": "FR",
    "tokyo": "JP",
    "osaka": "JP",
    "dubai": "AE",
    "abu dhabi": "AE",
    "singapore": "SG",
    "sydney": "AU",
    "melbourne": "AU",
    "toronto": "CA",
    "vancouver": "CA",
    "berlin": "DE",
    "munich": "DE",
    "rome": "IT",
    "madrid": "ES",
    "barcelona": "ES",
    "amsterdam": "NL",
    "zurich": "CH",
    "stockholm": "SE",
    "oslo": "NO",
    "copenhagen": "DK",
    "mumbai": "IN",
    "delhi": "IN",
    "bangalore": "IN",
    "shanghai": "CN",
    "beijing": "CN",
    "seoul": "KR",
    "bangkok": "TH",
    "kuala lumpur": "MY",
    "jakarta": "ID",
    "ho chi minh": "VN",
    "hanoi": "VN",
    "mexico city": "MX",
    "sao paulo": "BR",
    "rio de janeiro": "BR",
    "cape town": "ZA",
    "johannesburg": "ZA",
    "manila": "PH",
    "naga city": "PH",
    "naga": "PH",
    "legazpi": "PH",
    "daet": "PH",
}

COUNTRY_DEFAULT_LANGUAGE = {
    "AE": "ar",
    "AU": "en",
    "BR": "pt",
    "CA": "en",
    "CH": "de",
    "CN": "zh",
    "DE": "de",
    "DK": "da",
    "ES": "es",
    "FR": "fr",
    "GB": "en",
    "ID": "id",
    "IN": "en",
    "IT": "it",
    "JP": "ja",
    "KR": "ko",
    "MX": "es",
    "MY": "ms",
    "NL": "nl",
    "NO": "no",
    "NZ": "en",
    "PH": "en",
    "QA": "ar",
    "SA": "ar",
    "SE": "sv",
    "SG": "en",
    "TH": "th",
    "US": "en",
    "VN": "vi",
    "ZA": "en",
}

USD_TO_LOCAL_APPROX = {
    "AED": 3.67,
    "AUD": 1.52,
    "BRL": 5.35,
    "CAD": 1.37,
    "CHF": 0.91,
    "CNY": 7.25,
    "DKK": 6.85,
    "EUR": 0.92,
    "GBP": 0.79,
    "HKD": 7.82,
    "IDR": 16300,
    "INR": 83.5,
    "JPY": 157,
    "KRW": 1380,
    "MXN": 18.2,
    "MYR": 4.70,
    "NOK": 10.7,
    "NZD": 1.65,
    "PHP": 58.0,
    "QAR": 3.64,
    "SAR": 3.75,
    "SEK": 10.4,
    "SGD": 1.35,
    "THB": 36.5,
    "USD": 1.0,
    "VND": 25400,
    "ZAR": 18.2,
}

CURRENCY_SYMBOL_OVERRIDES = {
    "AED": "د.إ",
    "AUD": "$",
    "BRL": "R$",
    "CAD": "$",
    "CHF": "CHF",
    "CNY": "¥",
    "DKK": "kr",
    "EUR": "€",
    "GBP": "£",
    "HKD": "$",
    "IDR": "Rp",
    "INR": "₹",
    "JPY": "¥",
    "KRW": "₩",
    "MXN": "$",
    "MYR": "RM",
    "NOK": "kr",
    "NZD": "$",
    "PHP": "₱",
    "QAR": "ر.ق",
    "SAR": "﷼",
    "SEK": "kr",
    "SGD": "$",
    "THB": "฿",
    "USD": "$",
    "VND": "₫",
    "ZAR": "R",
}

GLOBAL_CITY_COORDS = {
    "new york": (40.7128, -74.0060),
    "london": (51.5072, -0.1276),
    "paris": (48.8566, 2.3522),
    "tokyo": (35.6762, 139.6503),
    "dubai": (25.2048, 55.2708),
    "singapore": (1.3521, 103.8198),
    "sydney": (-33.8688, 151.2093),
    "toronto": (43.6532, -79.3832),
    "berlin": (52.5200, 13.4050),
    "madrid": (40.4168, -3.7038),
    "manila": (14.5995, 120.9842),
    "naga city": (13.6218, 123.1948),
    "legazpi": (13.1387, 123.7353),
    "daet": (14.1122, 122.9553),
}


@dataclass
class MarketProfile:
    input_location: str
    city_label: str
    country_code: str
    country_name: str
    locale_code: str
    language_code: str
    language_name: str
    currency_code: str
    currency_symbol: str
    usd_to_local_rate: float
    lat: Optional[float] = None
    lng: Optional[float] = None
    source: str = "inferred"

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


def _normalize(value: str) -> str:
    return " ".join(value.lower().replace(",", " ").split())


def _territory_name(country_code: str, locale_code: str = "en") -> str:
    try:
        territory_names = Locale.parse(locale_code).territories
        return territory_names.get(country_code, country_code)
    except Exception:
        return country_code


def _language_name(language_code: str, locale_code: str = "en") -> str:
    try:
        language_names = Locale.parse(locale_code).languages
        return language_names.get(language_code, language_code)
    except Exception:
        return language_code


def _infer_country_from_text(location: str) -> Optional[str]:
    pieces = [piece.strip().lower() for piece in location.split(",") if piece.strip()]
    for piece in reversed(pieces):
        if piece in COUNTRY_ALIASES:
            return COUNTRY_ALIASES[piece]

    normalized = _normalize(location)
    for city, country in CITY_COUNTRY_HINTS.items():
        if normalized == city or normalized.startswith(f"{city} "):
            return country
    return None


def _currency_for_country(country_code: str) -> str:
    try:
        currencies = get_territory_currencies(country_code, tender=True)
        if currencies:
            return currencies[0]
    except Exception:
        logger.debug("Unable to resolve currency for territory %s", country_code)
    return "USD"


def _locale_code(language_code: str, country_code: str) -> str:
    return f"{language_code}_{country_code}"


async def _geocode_location(location: str) -> Dict[str, Any]:
    normalized = _normalize(location)
    for city, coords in GLOBAL_CITY_COORDS.items():
        if normalized == city or normalized.startswith(f"{city} "):
            return {
                "lat": coords[0],
                "lng": coords[1],
                "country_code": CITY_COUNTRY_HINTS.get(city),
                "source": "local_city_hint",
            }

    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            response = await client.get(
                "https://nominatim.openstreetmap.org/search",
                params={
                    "q": location,
                    "format": "jsonv2",
                    "limit": 1,
                    "addressdetails": 1,
                },
                headers={"User-Agent": "BizIdeas/1.0 global-market-profile"},
            )
        if response.status_code != 200:
            return {}
        results = response.json()
        if not results:
            return {}
        result = results[0]
        address = result.get("address") or {}
        country_code = (address.get("country_code") or "").upper() or None
        return {
            "lat": float(result["lat"]),
            "lng": float(result["lon"]),
            "country_code": country_code,
            "city_label": (
                address.get("city")
                or address.get("town")
                or address.get("municipality")
                or address.get("county")
                or location
            ),
            "source": "nominatim",
        }
    except Exception as exc:
        logger.warning("Global geocoding failed for %s: %s", location, exc)
        return {}


async def build_market_profile(
    location: str,
    user_locale: Optional[str] = None,
    user_country: Optional[str] = None,
) -> MarketProfile:
    geocoded = await _geocode_location(location)
    country_code = (
        (geocoded.get("country_code") or "").upper()
        or _infer_country_from_text(location)
        or (user_country or "").upper()
        or "US"
    )

    language_code = None
    if user_locale:
        language_code = user_locale.replace("-", "_").split("_")[0].lower()
    language_code = language_code or COUNTRY_DEFAULT_LANGUAGE.get(country_code, "en")

    locale_code = _locale_code(language_code, country_code)
    currency_code = _currency_for_country(country_code)
    currency_symbol = CURRENCY_SYMBOL_OVERRIDES.get(currency_code)
    if not currency_symbol:
        try:
            currency_symbol = get_currency_symbol(currency_code, locale=locale_code)
        except Exception:
            currency_symbol = get_global("currency_symbols").get(currency_code, currency_code)

    city_label = geocoded.get("city_label") or location.split(",")[0].strip() or location
    profile = MarketProfile(
        input_location=location,
        city_label=city_label,
        country_code=country_code,
        country_name=_territory_name(country_code, locale_code),
        locale_code=locale_code,
        language_code=language_code,
        language_name=_language_name(language_code, locale_code),
        currency_code=currency_code,
        currency_symbol=currency_symbol,
        usd_to_local_rate=USD_TO_LOCAL_APPROX.get(currency_code, 1.0),
        lat=geocoded.get("lat"),
        lng=geocoded.get("lng"),
        source=geocoded.get("source", "text_inference"),
    )
    return profile


def localize_amount(amount: float, profile: Dict[str, Any]) -> str:
    currency_code = profile.get("currency_code") or "USD"
    locale_code = profile.get("locale_code") or "en_US"
    symbol = profile.get("currency_symbol") or CURRENCY_SYMBOL_OVERRIDES.get(currency_code) or currency_code
    try:
        formatted = format_currency(amount, currency_code, locale=locale_code)
        if currency_code in formatted and symbol != currency_code:
            formatted = formatted.replace(currency_code, symbol)
        return formatted
    except Exception:
        return f"{symbol}{amount:,.0f}"


def usd_to_local(amount_usd: float, profile: Dict[str, Any]) -> int:
    return int(round(amount_usd * float(profile.get("usd_to_local_rate") or 1.0)))
