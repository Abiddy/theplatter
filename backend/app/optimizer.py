"""Deterministic combo optimizer — the LLM never does math."""

from __future__ import annotations

from dataclasses import dataclass
from statistics import median
from uuid import UUID

from app.schemas import (
    Combo,
    ComboLineItem,
    Constraints,
    DietaryRule,
    Menu,
    MenuItem,
    OptimizeGoal,
)


@dataclass
class Candidate:
    line_items: list[ComboLineItem]
    total_cents: int
    item_count: int
    unique_dishes: int
    veg_item_count: int
    serving_score: float
    main_servings: float
    appetizer_servings: float
    dessert_servings: float
    drink_count: int
    duplicate_penalty: float
    score: float


def generate_combos(menu: Menu, constraints: Constraints) -> tuple[list[Combo], str, list[str]]:
    eligible = _filter_items(menu.all_items, constraints)
    reference_spend = _reference_spend_cents(constraints.party_size, eligible)
    candidates = _build_candidates(eligible, constraints)
    candidates.sort(key=lambda c: c.score, reverse=True)

    selected: list[Candidate] = []
    for candidate in candidates:
        if len(selected) >= 3:
            break
        if all(not _is_too_similar(existing, candidate) for existing in selected):
            selected.append(candidate)

    if not selected and candidates:
        selected = [max(candidates, key=lambda c: c.score)]

    combos = []
    for index, candidate in enumerate(selected):
        title, subtitle = _combo_metadata(index + 1, candidate, constraints)
        combos.append(
            Combo(
                rank=index + 1,
                is_top_pick=index == 0,
                title=title,
                subtitle=subtitle,
                line_items=candidate.line_items,
                total_cents=candidate.total_cents,
                savings_cents=max(0, min(constraints.budget_cents, reference_spend) - candidate.total_cents),
            )
        )

    return combos, _build_summary(combos, constraints), _build_constraint_tags(constraints)


def _filter_items(items: list[MenuItem], constraints: Constraints) -> list[MenuItem]:
    rules = set(constraints.dietary_rules)
    filtered: list[MenuItem] = []

    for item in items:
        if DietaryRule.vegan in rules and not item.is_vegan:
            continue
        if DietaryRule.vegetarian in rules and not (item.is_vegetarian or item.is_vegan):
            continue
        if DietaryRule.no_fish in rules and item.contains_fish:
            continue
        if DietaryRule.no_shellfish in rules and item.contains_fish:
            continue
        if DietaryRule.no_nuts in rules and item.contains_nuts:
            continue
        if DietaryRule.no_pork in rules and item.contains_pork:
            continue
        if DietaryRule.gluten_free in rules and not item.is_gluten_free:
            continue
        if DietaryRule.halal in rules and item.contains_pork:
            continue
        if DietaryRule.kosher in rules and item.contains_pork:
            continue
        filtered.append(item)

    return filtered


def _build_candidates(items: list[MenuItem], constraints: Constraints) -> list[Candidate]:
    if not items:
        return []

    # Beam search keeps this fast for real menus. Each item can be skipped or
    # included in a sensible quantity; after every item we keep only the best
    # partial orders.
    beam: list[tuple[list[ComboLineItem], int, int]] = [([], 0, 0)]
    max_partial_states = 3_000
    hard_cap = int(constraints.budget_cents * 1.12)

    for item in sorted(items, key=lambda menu_item: menu_item.price_cents, reverse=True):
        next_beam: list[tuple[list[ComboLineItem], int, int]] = list(beam)
        for current, total, veg_count in beam:
            for qty in range(1, _max_quantity(item, constraints.party_size) + 1):
                next_total = total + item.price_cents * qty
                if next_total > hard_cap:
                    continue
                line = ComboLineItem(
                    menu_item_id=item.id,
                    name=item.name,
                    quantity=qty,
                    line_total_cents=item.price_cents * qty,
                )
                next_beam.append(
                    (
                        [*current, line],
                        next_total,
                        veg_count + (qty if item.is_vegetarian or item.is_vegan else 0),
                    )
                )

        # Approximate partial ordering: keep higher spend, more variety, and
        # fewer extreme repeats while the final scoring waits until the end.
        next_beam.sort(
            key=lambda state: (
                -abs(constraints.budget_cents * 0.94 - state[1]),
                len(state[0]),
                -_partial_duplicate_penalty(state[0]),
            ),
            reverse=True,
        )
        beam = _dedupe_states(next_beam[: max_partial_states * 2])[:max_partial_states]

    candidates: list[Candidate] = []
    item_lookup = {item.id: item for item in items}
    for current, total, veg_count in beam:
        if not current:
            continue
        candidate = _make_candidate(current, total, veg_count, constraints, item_lookup)
        if _is_plausible_meal(candidate, constraints):
            candidates.append(candidate)

    veg_needed = constraints.vegetarian_count
    if veg_needed == 0 and DietaryRule.vegetarian in constraints.dietary_rules:
        veg_needed = 1
    if veg_needed > 0:
        candidates = [c for c in candidates if c.veg_item_count >= veg_needed]

    return candidates


def _make_candidate(
    line_items: list[ComboLineItem],
    total: int,
    veg_count: int,
    constraints: Constraints,
    item_lookup: dict[object, MenuItem],
) -> Candidate:
    item_count = sum(line.quantity for line in line_items)
    unique = len({line.menu_item_id for line in line_items})
    serving_score = 0.0
    main_servings = 0.0
    appetizer_servings = 0.0
    dessert_servings = 0.0
    drink_count = 0
    duplicate_penalty = 0.0

    for line in line_items:
        item = item_lookup[line.menu_item_id]
        servings = _estimated_servings(item) * line.quantity
        serving_score += servings
        if item.course == "main":
            main_servings += servings
        elif item.course in {"appetizer", "side"}:
            appetizer_servings += servings
        elif item.course == "dessert":
            dessert_servings += servings
        elif item.course == "drink":
            drink_count += line.quantity

        sensible_qty = _sensible_quantity(item, constraints.party_size)
        duplicate_penalty += max(0, line.quantity - sensible_qty) * 12

    if unique == 1 and constraints.party_size > 1:
        duplicate_penalty += 28

    score = _score_candidate(
        total=total,
        budget=constraints.budget_cents,
        party_size=constraints.party_size,
        item_count=item_count,
        unique=unique,
        serving_score=serving_score,
        main_servings=main_servings,
        appetizer_servings=appetizer_servings,
        dessert_servings=dessert_servings,
        drink_count=drink_count,
        duplicate_penalty=duplicate_penalty,
        goals=set(constraints.optimize_goals),
    )

    return Candidate(
        line_items=line_items,
        total_cents=total,
        item_count=item_count,
        unique_dishes=unique,
        veg_item_count=veg_count,
        serving_score=serving_score,
        main_servings=main_servings,
        appetizer_servings=appetizer_servings,
        dessert_servings=dessert_servings,
        drink_count=drink_count,
        duplicate_penalty=duplicate_penalty,
        score=score,
    )


def _score_candidate(
    total: int,
    budget: int,
    party_size: int,
    item_count: int,
    unique: int,
    serving_score: float,
    main_servings: float,
    appetizer_servings: float,
    dessert_servings: float,
    drink_count: int,
    duplicate_penalty: float,
    goals: set[OptimizeGoal],
) -> float:
    budget_score = _budget_fit_score(total, budget)
    coverage_score = min(serving_score / max(1.0, party_size * 0.95), 1.2) * 32
    main_score = min(main_servings / max(1.0, party_size * 0.75), 1.0) * 24
    variety_score = min(unique / max(2, min(party_size, 5)), 1.0) * 16
    completeness_score = 0.0

    if main_servings >= party_size * 0.65:
        completeness_score += 12
    if party_size >= 2 and appetizer_servings > 0:
        completeness_score += 6
    if drink_count > 0 and total >= budget * 0.85:
        completeness_score += 3
    if OptimizeGoal.dessert_included in goals and dessert_servings > 0:
        completeness_score += 8

    # Goals without a menu-level signal yet (healthy, high_protein, ...) are
    # ignored for scoring; fall back to best_value if none of the core three.
    core = {OptimizeGoal.best_value, OptimizeGoal.most_food, OptimizeGoal.best_variety}
    effective = goals & core or {OptimizeGoal.best_value}

    score = budget_score + coverage_score + main_score + completeness_score
    if OptimizeGoal.best_value in effective:
        score += budget_score * 0.35 + variety_score * 0.35
    if OptimizeGoal.most_food in effective:
        score += coverage_score * 0.8 + item_count * 1.5
    if OptimizeGoal.best_variety in effective:
        score += variety_score * 1.2
    if OptimizeGoal.family_style in goals:
        score += min(appetizer_servings + main_servings, party_size) * 1.5

    return score - duplicate_penalty


def _budget_fit_score(total: int, budget: int) -> float:
    if budget <= 0:
        return 0
    utilization = total / budget
    if utilization <= 1.0:
        if utilization < 0.55:
            return utilization / 0.55 * 25
        if utilization < 0.85:
            return 25 + (utilization - 0.55) / 0.30 * 35
        # Sweet spot: 85-100%, peaking around 96%.
        return 60 + max(0, 1 - abs(0.96 - utilization) / 0.11) * 40

    # Slightly over can be useful as a "Feast" option, but should rarely win.
    if utilization <= 1.10:
        return 48 - (utilization - 1.0) / 0.10 * 35
    return -100


def _is_plausible_meal(candidate: Candidate, constraints: Constraints) -> bool:
    if candidate.total_cents > constraints.budget_cents * 1.12:
        return False
    if candidate.main_servings <= 0 and candidate.appetizer_servings <= 0:
        return False
    if candidate.serving_score < max(0.75, constraints.party_size * 0.55):
        return False
    if candidate.unique_dishes == 1 and constraints.party_size >= 3:
        # Single-item group orders are only OK if the item is plausibly shareable.
        return candidate.serving_score >= constraints.party_size * 0.9
    return True


def _estimated_servings(item: MenuItem) -> float:
    if item.serves_max and item.serves_max > 1:
        return float(item.serves_max)
    if item.is_shareable:
        return 2.0
    if item.course == "main":
        return 1.0
    if item.course in {"appetizer", "side"}:
        return 0.6
    if item.course == "dessert":
        return 0.45
    if item.course == "drink":
        return 0.1
    return 0.75


def _max_quantity(item: MenuItem, party_size: int) -> int:
    if item.course == "drink":
        return min(max(party_size, 2), 8)
    if item.course == "dessert":
        return min(max(party_size // 2 + 1, 2), 5)
    if item.is_shareable or item.serves_max > 1:
        return min(max((party_size + max(item.serves_max, 1) - 1) // max(item.serves_max, 1) + 1, 2), 5)
    if item.course == "main":
        return min(max(party_size, 2), 6)
    return min(max(party_size // 2 + 2, 2), 5)


def _sensible_quantity(item: MenuItem, party_size: int) -> int:
    if item.course == "drink":
        return party_size
    if item.is_shareable or item.serves_max > 1:
        return max(1, (party_size + max(item.serves_max, 1) - 1) // max(item.serves_max, 1))
    if item.course == "main":
        return max(1, party_size)
    return max(1, party_size // 2 + 1)


def _partial_duplicate_penalty(line_items: list[ComboLineItem]) -> int:
    return sum(max(0, line.quantity - 2) for line in line_items)


def _dedupe_states(states: list[tuple[list[ComboLineItem], int, int]]) -> list[tuple[list[ComboLineItem], int, int]]:
    seen: set[tuple[tuple[str, int], ...]] = set()
    unique: list[tuple[list[ComboLineItem], int, int]] = []
    for state in states:
        signature = tuple(sorted((str(line.menu_item_id), line.quantity) for line in state[0]))
        if signature in seen:
            continue
        seen.add(signature)
        unique.append(state)
    return unique


def _reference_spend_cents(party_size: int, items: list[MenuItem]) -> int:
    if not items:
        return 0
    med = int(median([item.price_cents for item in items]))
    return med * party_size


def _is_too_similar(a: Candidate, b: Candidate) -> bool:
    a_ids = {line.menu_item_id for line in a.line_items}
    b_ids = {line.menu_item_id for line in b.line_items}
    overlap = len(a_ids & b_ids)
    union = max(1, len(a_ids | b_ids))
    return overlap / union > 0.72


def _combo_metadata(rank: int, candidate: Candidate, constraints: Constraints) -> tuple[str, str]:
    over_budget = candidate.total_cents > constraints.budget_cents
    under_budget = candidate.total_cents < int(constraints.budget_cents * 0.85)

    if rank == 1:
        spend = candidate.total_cents / max(1, constraints.budget_cents)
        veg = (
            f"{constraints.vegetarian_count} vegetarian"
            if constraints.vegetarian_count > 0
            else "balanced picks"
        )
        if spend >= 0.85:
            return "The Crowd Pleaser", f"Full spread for {constraints.party_size} people · {veg}"
        return "Smart Under-Budget Pick", f"Complete meal for {constraints.party_size} people · {veg}"
    if rank == 2:
        subtitle = "More food, slightly over — worth it?" if over_budget else "Hearty portions for the group"
        return "The Feast", subtitle
    if rank == 3:
        subtitle = "Under budget, leaves room for dessert." if under_budget else "Lighter spread, great variety"
        return "Light & Fresh", subtitle
    return f"Combo {rank}", "Curated for your group"


def _build_summary(combos: list[Combo], constraints: Constraints) -> str:
    parts = [f"Found {len(combos)} combos"]
    if DietaryRule.no_fish in constraints.dietary_rules:
        parts.append("that skip fish")
    if constraints.vegetarian_count > 0:
        parts.append("and cover both vegetarians")
    if combos and combos[0].total_cents <= constraints.budget_cents:
        parts.append("Pick #1 to stay under budget.")
    return " ".join(parts) + "."


_RULE_LABELS = {
    DietaryRule.vegetarian: "Vegetarian",
    DietaryRule.gluten_free: "Gluten-free",
    DietaryRule.no_nuts: "No Nuts",
    DietaryRule.vegan: "Vegan",
    DietaryRule.no_fish: "No Fish",
    DietaryRule.no_pork: "No Pork",
    DietaryRule.halal: "Halal",
    DietaryRule.kosher: "Kosher",
    DietaryRule.no_shellfish: "No Shellfish",
    DietaryRule.dairy_free: "Dairy-free",
    DietaryRule.egg_free: "Egg-free",
    DietaryRule.soy_free: "Soy-free",
    DietaryRule.sesame_free: "Sesame-free",
    DietaryRule.no_beef: "No Beef",
    DietaryRule.no_lamb: "No Lamb",
    DietaryRule.no_alcohol: "No Alcohol",
    DietaryRule.no_spicy: "Not Spicy",
    DietaryRule.low_sodium: "Low Sodium",
    DietaryRule.low_carb: "Low Carb",
    DietaryRule.keto: "Keto",
    DietaryRule.paleo: "Paleo",
    DietaryRule.pescatarian: "Pescatarian",
    DietaryRule.diabetic_friendly: "Diabetic-friendly",
}


def _build_constraint_tags(constraints: Constraints) -> list[str]:
    tags = [f"Party of {constraints.party_size}", f"${constraints.budget_cents // 100} max"]
    for rule in sorted(constraints.dietary_rules, key=lambda r: _RULE_LABELS[r]):
        tags.append(_RULE_LABELS[rule])
    if constraints.vegetarian_count > 1:
        tags.append(f"Vegetarian x{constraints.vegetarian_count}")
    return tags
