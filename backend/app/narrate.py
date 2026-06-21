import json

from openai import OpenAI

from app.config import settings
from app.schemas import Combo, Constraints, Menu


def narrate_combos(menu: Menu, constraints: Constraints, combos: list[Combo]) -> str:
    if settings.use_mock_narrate or not settings.has_openai_key:
        return _mock_summary(combos, constraints)

    client = OpenAI(api_key=settings.openai_api_key)
    payload = {
        "restaurant": menu.restaurant_name,
        "party_size": constraints.party_size,
        "budget_cents": constraints.budget_cents,
        "dietary_rules": [rule.value for rule in constraints.dietary_rules],
        "combos": [
            {
                "rank": combo.rank,
                "title": combo.title,
                "total_cents": combo.total_cents,
                "items": [f"{line.quantity}x {line.name}" for line in combo.line_items],
            }
            for combo in combos
        ],
    }

    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are Bro from Platter — warm, concise, responsible. "
                        "Write one sentence summarizing the combo results. "
                        "Never change totals or item counts. No markdown."
                    ),
                },
                {
                    "role": "user",
                    "content": f"Summarize these combos for the user:\n{json.dumps(payload)}",
                },
            ],
            max_tokens=120,
        )
    except Exception:
        # Narration is nice-to-have; combo math should never fail because copy did.
        return _mock_summary(combos, constraints)

    return (completion.choices[0].message.content or _mock_summary(combos, constraints)).strip()


def _mock_summary(combos: list[Combo], constraints: Constraints) -> str:
    parts = [f"Found {len(combos)} combos"]
    if "no_fish" in [rule.value for rule in constraints.dietary_rules]:
        parts.append("that skip fish")
    if constraints.vegetarian_count > 0:
        parts.append("and cover both vegetarians")
    if combos and combos[0].total_cents <= constraints.budget_cents:
        parts.append("Pick #1 to stay under budget.")
    return " ".join(parts) + "."
