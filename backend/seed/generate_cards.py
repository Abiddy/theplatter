"""Generate Discover recommendation cards from seed menus (offline / file-based).

For every menu in seed/restaurants/*.json, run each persona's constraints
through the SAME deterministic optimizer the app uses, then emit the top
combo as a recommendation card.

Note: the admin portal (/recs) is the primary way to manage data now. This
script remains useful for bulk/offline seeding from JSON files.

Usage:
    cd backend
    python seed/generate_cards.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

SEED_DIR = Path(__file__).resolve().parent
BACKEND_DIR = SEED_DIR.parent
REPO_ROOT = BACKEND_DIR.parent
REST_DIR = SEED_DIR / "restaurants"
OUT_DIR = REPO_ROOT / "platter" / "Resources"
OUT_FILE = OUT_DIR / "discover_recommendations.json"

sys.path.insert(0, str(BACKEND_DIR))

from app.personas import build_cards_for_menu  # noqa: E402
from app.schemas import Menu  # noqa: E402


def is_stub(raw: dict) -> bool:
    for section in raw.get("sections", []):
        for item in section.get("items", []):
            if item.get("name", "").startswith("TODO") or item.get("price_cents", 0) <= 0:
                return True
    return False


def load_menus() -> list[dict]:
    menus: list[dict] = []
    for path in sorted(REST_DIR.glob("*.json")):
        raw = json.loads(path.read_text())
        if is_stub(raw):
            print(f"  skip (stub/incomplete): {path.name}")
            continue
        menus.append(raw)
    return menus


def main() -> None:
    menus = load_menus()
    if not menus:
        print("No complete menus found in seed/restaurants/. Fill in a menu first.")
        sys.exit(1)

    all_cards: list[dict] = []
    for raw in menus:
        menu = Menu(sections=raw["sections"], restaurant_name=raw["restaurant_name"])
        cards = build_cards_for_menu(
            menu,
            restaurant_name=raw["restaurant_name"],
            cuisine=raw.get("cuisine", "Restaurant"),
            distance_miles=raw.get("distance_miles", 1.0),
            image_seed=raw.get("image_seed", 0),
            is_verified=raw.get("is_verified", False),
        )
        all_cards.extend(cards)
        print(f"  {raw['restaurant_name']}: {len(cards)} cards")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT_FILE.write_text(json.dumps(all_cards, indent=2))
    print(f"\nWrote {len(all_cards)} cards from {len(menus)} restaurants")
    print(f"-> {OUT_FILE}")


if __name__ == "__main__":
    main()
