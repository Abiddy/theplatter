"""Google Places (New) search proxy.

The API key stays server-side; the portal calls our backend, never Google
directly. Returns a normalized list of restaurants for a text query like
"Gardena" or "sushi in Gardena".
"""

from __future__ import annotations

import math

import httpx

from app.config import settings

PLACES_ENDPOINT = "https://places.googleapis.com/v1/places:searchText"
FIELD_MASK = ",".join(
    [
        "places.displayName",
        "places.formattedAddress",
        "places.rating",
        "places.userRatingCount",
        "places.priceLevel",
        "places.primaryType",
        "places.location",
        "places.id",
    ]
)

PRICE_TIER = {
    "PRICE_LEVEL_INEXPENSIVE": "$",
    "PRICE_LEVEL_MODERATE": "$$",
    "PRICE_LEVEL_EXPENSIVE": "$$$",
    "PRICE_LEVEL_VERY_EXPENSIVE": "$$$$",
}

# Default origin for distance calc (Gardena, CA center).
ORIGIN_LAT = 33.8883
ORIGIN_LNG = -118.3090


def _distance_miles(lat: float | None, lng: float | None) -> float:
    if lat is None or lng is None:
        return 1.0
    earth_radius_mi = 3958.8
    d_lat = math.radians(lat - ORIGIN_LAT)
    d_lng = math.radians(lng - ORIGIN_LNG)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(ORIGIN_LAT)) * math.cos(math.radians(lat)) * math.sin(d_lng / 2) ** 2
    )
    return round(earth_radius_mi * 2 * math.asin(math.sqrt(a)), 1)


async def search_places(query: str) -> list[dict]:
    if not settings.has_places_key:
        raise RuntimeError("GOOGLE_PLACES_API_KEY is not configured on the server.")

    text_query = query if "restaurant" in query.lower() else f"restaurants in {query}"
    body = {"textQuery": text_query, "maxResultCount": 20}

    async with httpx.AsyncClient(timeout=15) as client:
        response = await client.post(
            PLACES_ENDPOINT,
            json=body,
            headers={
                "Content-Type": "application/json",
                "X-Goog-Api-Key": settings.google_places_api_key,
                "X-Goog-FieldMask": FIELD_MASK,
            },
        )
        response.raise_for_status()
        data = response.json()

    results: list[dict] = []
    for place in data.get("places", []):
        name = place.get("displayName", {}).get("text", "").strip()
        if not name:
            continue
        loc = place.get("location", {})
        lat, lng = loc.get("latitude"), loc.get("longitude")
        results.append(
            {
                "place_id": place.get("id", ""),
                "name": name,
                "address": place.get("formattedAddress", ""),
                "rating": place.get("rating", 0.0),
                "review_count": place.get("userRatingCount", 0),
                "price_tier": PRICE_TIER.get(place.get("priceLevel", ""), "$$"),
                "cuisine": (place.get("primaryType", "restaurant") or "restaurant")
                .replace("_restaurant", "")
                .replace("_", " ")
                .title(),
                "lat": lat,
                "lng": lng,
                "distance_miles": _distance_miles(lat, lng),
            }
        )

    return results
