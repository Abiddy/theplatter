# Platter Seed Pipeline (Gardena)

Turn real restaurant menus into Discover recommendation cards — no hand-writing
cards. You write each **menu** once; the optimizer generates the cards.

```
1. fetch_restaurants.py   → pull top ~50 Gardena restaurants + create stub menus
2. (manual)               → fill in each menu's `sections`
3. generate_cards.py      → run menus × personas through the optimizer → cards JSON
4. (build app)            → cards auto-bundle into the iOS app
```

## 1. Fetch the restaurant list

Uses Google Places API (New). Get a key at
https://console.cloud.google.com → enable "Places API (New)".

```bash
export GOOGLE_PLACES_API_KEY="your-key"
cd backend
python seed/fetch_restaurants.py
```

This writes:
- `seed/restaurants_gardena.json` — the raw list
- `seed/restaurants/<slug>.json` — a **stub** menu per restaurant (only if missing)

## 2. Fill in menus (the manual part)

Edit each `seed/restaurants/<slug>.json`. Replace the TODO section with real
items. Copy from the restaurant's website / DoorDash / Yelp, or scan it with
the app. Prices are in **cents** (`1800` = $18.00).

Useful per-item flags: `course` (appetizer/main/side/dessert/drink),
`is_shareable`, `serves_min`, `serves_max`, `is_vegetarian`, `is_vegan`,
`contains_pork`, `contains_fish`, `contains_nuts`, `is_gluten_free`.

See `shin-sen-gumi-chanko.json`, `azuma-japanese.json`, `eatalian-cafe.json`
for complete examples. Stub/incomplete menus are skipped automatically.

## 3. Generate cards

```bash
cd backend
python seed/generate_cards.py
```

Writes `platter/Resources/discover_recommendations.json` (auto-bundled into the
app). Each restaurant produces up to 5 cards (one per persona in `personas.py`).

## 4. Run the app

The app loads the bundled JSON via `RecommendationSeed.load()`, falling back to
mock data if the file is missing. Rebuild in Xcode and open Discover.

## Personas

Edit `personas.py` to change which cards get generated (party size, budget,
diet, optimize goals, title/subtitle/tags). Card IDs are stable per
`restaurant + persona`, so user hearts survive regeneration.
