"""Personas drive auto-generated recommendation cards.

Each menu is run through every persona's constraints using the SAME
deterministic optimizer the app uses. The optimizer does the math; the
persona just supplies context (party size, budget, diet, goals) and the
card's title / subtitle / tags.
"""

from __future__ import annotations

import json
import uuid
from dataclasses import dataclass

from app.optimizer import generate_combos
from app.schemas import Constraints, DietaryRule, Menu, OptimizeGoal

# Fixed namespace so card IDs stay stable across regenerations (hearts persist).
CARD_NAMESPACE = uuid.UUID("8f1b9d2e-1a2b-4c3d-9e4f-abc123def456")


@dataclass
class Persona:
    key: str
    title: str
    subtitle: str
    context_tags: list[str]
    constraints: Constraints


PERSONAS: list[Persona] = [
    Persona(
        key="date_night",
        title="Date Night for 2",
        subtitle="Shared plates for two",
        context_tags=["Date Night", "Romantic"],
        constraints=Constraints(party_size=2, budget_cents=7500, optimize_goals=[OptimizeGoal.best_value]),
    ),
    Persona(
        key="family_feast",
        title="Family Feast for 4",
        subtitle="Fill everyone up",
        context_tags=["Group Friendly", "Family Style"],
        constraints=Constraints(
            party_size=4,
            budget_cents=9000,
            optimize_goals=[OptimizeGoal.family_style, OptimizeGoal.most_food],
        ),
    ),
    Persona(
        key="solo_quick",
        title="Solo Quick Bite",
        subtitle="One person, one great order",
        context_tags=["Solo", "Quick Bite"],
        constraints=Constraints(party_size=1, budget_cents=2500, optimize_goals=[OptimizeGoal.best_value]),
    ),
    Persona(
        key="veg_share",
        title="Vegetarian Share",
        subtitle="Meat-free picks for the table",
        context_tags=["Vegetarian", "Healthy"],
        constraints=Constraints(
            party_size=3,
            budget_cents=8000,
            dietary_rules=[DietaryRule.vegetarian],
            optimize_goals=[OptimizeGoal.best_variety],
        ),
    ),
    Persona(
        key="best_value_2",
        title="Best Value for 2",
        subtitle="Maximize food per dollar",
        context_tags=["Best Value"],
        constraints=Constraints(party_size=2, budget_cents=4000, optimize_goals=[OptimizeGoal.best_value]),
    ),
]


def stable_card_id(restaurant_name: str, persona_key: str) -> str:
    return str(uuid.uuid5(CARD_NAMESPACE, f"{restaurant_name}|{persona_key}"))


def build_cards_for_menu(
    menu: Menu,
    *,
    restaurant_name: str,
    cuisine: str,
    distance_miles: float,
    image_seed: int,
    is_verified: bool,
) -> list[dict]:
    """Run every persona through the optimizer and return Discover card dicts (snake_case)."""
    cards: list[dict] = []

    for persona in PERSONAS:
        combos, _summary, _tags = generate_combos(menu, persona.constraints)
        if not combos:
            continue
        top = combos[0]
        top.title = persona.title
        top.subtitle = persona.subtitle

        cards.append(
            {
                "id": stable_card_id(restaurant_name, persona.key),
                "restaurant_name": restaurant_name,
                "cuisine": cuisine,
                "distance_miles": distance_miles,
                "image_seed": image_seed,
                "is_verified": is_verified,
                "combo": json.loads(top.model_dump_json()),
                "party_size": persona.constraints.party_size,
                "budget_cents": persona.constraints.budget_cents,
                "context_tags": persona.context_tags,
                "base_heart_count": 0,
            }
        )

    return cards
