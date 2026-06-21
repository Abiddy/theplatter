from datetime import datetime
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class MenuSource(str, Enum):
    camera = "camera"
    photo = "photo"
    verified = "verified"


class DietaryRule(str, Enum):
    vegetarian = "vegetarian"
    gluten_free = "gluten_free"
    no_nuts = "no_nuts"
    vegan = "vegan"
    no_fish = "no_fish"
    no_pork = "no_pork"
    halal = "halal"
    kosher = "kosher"
    no_shellfish = "no_shellfish"
    dairy_free = "dairy_free"
    egg_free = "egg_free"
    soy_free = "soy_free"
    sesame_free = "sesame_free"
    no_beef = "no_beef"
    no_lamb = "no_lamb"
    no_alcohol = "no_alcohol"
    no_spicy = "no_spicy"
    low_sodium = "low_sodium"
    low_carb = "low_carb"
    keto = "keto"
    paleo = "paleo"
    pescatarian = "pescatarian"
    diabetic_friendly = "diabetic_friendly"


class OptimizeGoal(str, Enum):
    best_value = "best_value"
    most_food = "most_food"
    best_variety = "best_variety"
    healthy = "healthy"
    high_protein = "high_protein"
    family_style = "family_style"
    kid_friendly = "kid_friendly"
    dessert_included = "dessert_included"


class MenuCourse(str, Enum):
    appetizer = "appetizer"
    main = "main"
    side = "side"
    dessert = "dessert"
    drink = "drink"
    unknown = "unknown"


class MenuItem(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    name: str
    description: Optional[str] = None
    price_cents: int
    course: MenuCourse = MenuCourse.unknown
    is_shareable: bool = False
    serves_min: int = 1
    serves_max: int = 1
    tags: list[DietaryRule] = []
    is_vegetarian: bool = False
    contains_fish: bool = False
    contains_nuts: bool = False
    contains_pork: bool = False
    is_vegan: bool = False
    is_gluten_free: bool = False


class MenuSection(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    name: str
    items: list[MenuItem]


class Menu(BaseModel):
    restaurant_name: Optional[str] = None
    sections: list[MenuSection]
    scanned_at: datetime = Field(default_factory=datetime.utcnow)
    source: MenuSource = MenuSource.camera

    @property
    def all_items(self) -> list[MenuItem]:
        return [item for section in self.sections for item in section.items]


class Constraints(BaseModel):
    party_size: int = 2
    budget_cents: int = 10_000
    dietary_rules: list[DietaryRule] = []
    vegetarian_count: int = 0
    optimize_goals: list[OptimizeGoal] = [OptimizeGoal.best_value]
    free_text_notes: str = ""


class ComboLineItem(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    menu_item_id: UUID
    name: str
    quantity: int
    line_total_cents: int


class Combo(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    rank: int
    is_top_pick: bool
    title: str
    subtitle: str
    line_items: list[ComboLineItem]
    total_cents: int
    savings_cents: int


class ParseMenuResponse(BaseModel):
    menu: Menu
    confidence: float = 1.0
    warnings: list[str] = []


class GenerateCombosRequest(BaseModel):
    menu: Menu
    constraints: Constraints


class GenerateCombosResponse(BaseModel):
    combos: list[Combo]
    ai_summary: str
    constraint_tags: list[str]
