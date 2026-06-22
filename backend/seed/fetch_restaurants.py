"""Fetch top restaurants in Gardena via Google Places API (New).

Usage:
    export GOOGLE_PLACES_API_KEY="your-key"
    python seed/fetch_restaurants.py

Outputs:
    seed/restaurants_gardena.json   -> the raw list (name, address, rating, etc.)
    seed/restaurants/<slug>.json    -> a STUB menu file for each restaurant
                                        (only created if it doesn't already exist)

You then fill in the `sections` of each stub menu by hand (copy from the
restaurant's website / DoorDash / Yelp, or scan it with the app).

Requires no extra dependencies — uses the standard library only.
"""

from __future__ import annotations

import json
import math
import os
import re
import sys
import time
import urllib.request
from pathlib import Path

SEED_DIR = Path(__file__).resolve().parent
REST_DIR = SEED_DIR / "restaurants"
LIST_OUT = SEED_DIR / "restaurants_gardena.json"

# Gardena, CA city center.
GARDENA_LAT = 33.8883
GARDENA_LNG = -118.3090
SEARCH_RADIUS_METERS = 4000
TARGET_COUNT = 50

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


def slugify(name: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return slug or "restaurant"


def distance_miles(lat: float | None, lng: float | None) -> float:
    """Great-circle distance from Gardena center, rounded to 0.1 mi."""
    if lat is None or lng is None:
        return 1.0
    earth_radius_mi = 3958.8
    d_lat = math.radians(lat - GARDENA_LAT)
    d_lng = math.radians(lng - GARDENA_LNG)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(GARDENA_LAT))
        * math.cos(math.radians(lat))
        * math.sin(d_lng / 2) ** 2
    )
    miles = earth_radius_mi * 2 * math.asin(math.sqrt(a))
    return round(miles, 1)


def fetch_page(api_key: str, page_token: str | None) -> dict:
    body: dict = {
        "textQuery": "restaurants in Gardena, CA",
        "locationBias": {
            "circle": {
                "center": {"latitude": GARDENA_LAT, "longitude": GARDENA_LNG},
                "radius": SEARCH_RADIUS_METERS,
            }
        },
        "maxResultCount": 20,
    }
    if page_token:
        body["pageToken"] = page_token

    request = urllib.request.Request(
        PLACES_ENDPOINT,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "X-Goog-Api-Key": api_key,
            "X-Goog-FieldMask": FIELD_MASK + ",nextPageToken",
        },
        method="POST",
    )
    with urllib.request.urlopen(request) as response:
        return json.loads(response.read().decode("utf-8"))


def main() -> None:
    api_key = os.environ.get("GOOGLE_PLACES_API_KEY")
    if not api_key:
        print("ERROR: set GOOGLE_PLACES_API_KEY first.")
        print('  export GOOGLE_PLACES_API_KEY="your-key"')
        sys.exit(1)

    REST_DIR.mkdir(parents=True, exist_ok=True)

    collected: list[dict] = []
    page_token: str | None = None

    while len(collected) < TARGET_COUNT:
        data = fetch_page(api_key, page_token)
        places = data.get("places", [])
        if not places:
            break

        for place in places:
            name = place.get("displayName", {}).get("text", "").strip()
            if not name:
                continue
            loc = place.get("location", {})
            collected.append(
                {
                    "name": name,
                    "address": place.get("formattedAddress", ""),
                    "rating": place.get("rating", 0.0),
                    "review_count": place.get("userRatingCount", 0),
                    "price_tier": PRICE_TIER.get(place.get("priceLevel", ""), "$$"),
                    "cuisine": (place.get("primaryType", "restaurant") or "restaurant")
                    .replace("_restaurant", "")
                    .replace("_", " ")
                    .title(),
                    "lat": loc.get("latitude"),
                    "lng": loc.get("longitude"),
                    "place_id": place.get("id", ""),
                }
            )

        page_token = data.get("nextPageToken")
        if not page_token:
            break
        # New Places API requires a short delay before the next page token is valid.
        time.sleep(2)

    collected = collected[:TARGET_COUNT]
    LIST_OUT.write_text(json.dumps(collected, indent=2))
    print(f"Wrote {len(collected)} restaurants -> {LIST_OUT.relative_to(SEED_DIR.parent)}")

    created = 0
    for index, restaurant in enumerate(collected):
        slug = slugify(restaurant["name"])
        path = REST_DIR / f"{slug}.json"
        if path.exists():
            continue
        stub = {
            "restaurant_name": restaurant["name"],
            "cuisine": restaurant["cuisine"],
            "distance_miles": distance_miles(restaurant.get("lat"), restaurant.get("lng")),
            "is_verified": False,
            "image_seed": index % 4,
            "sections": [
                {
                    "name": "TODO - add a section",
                    "items": [
                        {"name": "TODO - add an item", "price_cents": 0, "course": "main"}
                    ],
                }
            ],
        }
        path.write_text(json.dumps(stub, indent=2))
        created += 1

    print(f"Created {created} stub menu files in {REST_DIR.relative_to(SEED_DIR.parent)}/")
    print("Now fill in the `sections` for each stub, then run generate_cards.py")


if __name__ == "__main__":
    main()
