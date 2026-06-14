from typing import Any, Mapping, Optional, TypeVar

T = TypeVar("T")


def city_lookup_keys(city: str) -> list[str]:
    normalized = " ".join(city.lower().strip().split())
    keys = [normalized]

    if normalized.endswith(" city"):
        keys.append(normalized[:-5].strip())
    elif normalized:
        keys.append(f"{normalized} city")

    return list(dict.fromkeys(key for key in keys if key))


def lookup_city(mapping: Mapping[str, T], city: str, default: Optional[T] = None) -> Optional[T]:
    for key in city_lookup_keys(city):
        if key in mapping:
            return mapping[key]
    return default
