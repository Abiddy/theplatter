import base64
import json
from datetime import datetime

from openai import OpenAI

from app.config import settings
from app.schemas import Menu, MenuCourse, MenuItem, MenuSection, MenuSource, ParseMenuResponse

MENU_SCHEMA = {
    "type": "object",
    "properties": {
        "restaurant_name": {"type": ["string", "null"]},
        "sections": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "items": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "name": {"type": "string"},
                                "description": {"type": ["string", "null"]},
                                "price_cents": {"type": "integer"},
                                "course": {
                                    "type": "string",
                                    "enum": ["appetizer", "main", "side", "dessert", "drink", "unknown"],
                                },
                                "is_shareable": {"type": "boolean"},
                                "serves_min": {"type": "integer"},
                                "serves_max": {"type": "integer"},
                                "is_vegetarian": {"type": "boolean"},
                                "is_vegan": {"type": "boolean"},
                                "contains_fish": {"type": "boolean"},
                                "contains_nuts": {"type": "boolean"},
                                "contains_pork": {"type": "boolean"},
                                "is_gluten_free": {"type": "boolean"},
                            },
                            "required": [
                                "name",
                                "description",
                                "price_cents",
                                "course",
                                "is_shareable",
                                "serves_min",
                                "serves_max",
                                "is_vegetarian",
                                "is_vegan",
                                "contains_fish",
                                "contains_nuts",
                                "contains_pork",
                                "is_gluten_free",
                            ],
                            "additionalProperties": False,
                        },
                    },
                },
                "required": ["name", "items"],
                "additionalProperties": False,
            },
        },
        "warnings": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["restaurant_name", "sections", "warnings"],
    "additionalProperties": False,
}


def mock_menu(restaurant_name: str | None = None) -> ParseMenuResponse:
    menu = Menu(
        restaurant_name=restaurant_name or "Scanned Restaurant",
        sections=[
            MenuSection(
                name="Pizza",
                items=[
                    MenuItem(
                        name="Margherita Pizza",
                        price_cents=1800,
                        course=MenuCourse.main,
                        is_shareable=True,
                        serves_min=1,
                        serves_max=2,
                        is_vegetarian=True,
                    )
                ],
            ),
            MenuSection(
                name="Pasta & Risotto",
                items=[
                    MenuItem(
                        name="Risotto ai Funghi",
                        price_cents=2400,
                        course=MenuCourse.main,
                        serves_min=1,
                        serves_max=1,
                        is_vegetarian=True,
                    ),
                    MenuItem(
                        name="Spaghetti alle Vongole",
                        price_cents=2600,
                        course=MenuCourse.main,
                        serves_min=1,
                        serves_max=1,
                        contains_fish=True,
                    ),
                ],
            ),
            MenuSection(
                name="Antipasti",
                items=[
                    MenuItem(
                        name="Bruschetta al Pomodoro",
                        price_cents=900,
                        course=MenuCourse.appetizer,
                        is_shareable=True,
                        serves_min=1,
                        serves_max=2,
                        is_vegetarian=True,
                        is_vegan=True,
                    ),
                    MenuItem(
                        name="Burrata e Prosciutto",
                        price_cents=1600,
                        course=MenuCourse.appetizer,
                        is_shareable=True,
                        serves_min=1,
                        serves_max=2,
                        contains_pork=True,
                    ),
                ],
            ),
            MenuSection(
                name="Bevande",
                items=[
                    MenuItem(name="Acqua Naturale", price_cents=500, course=MenuCourse.drink),
                    MenuItem(name="House Red Wine", price_cents=1200, course=MenuCourse.drink),
                ],
            ),
        ],
        scanned_at=datetime.utcnow(),
        source=MenuSource.camera,
    )
    return ParseMenuResponse(menu=menu, confidence=0.95, warnings=[])


async def parse_menu_image(
    image_bytes: bytes,
    source: MenuSource,
    restaurant_name: str | None = None,
) -> ParseMenuResponse:
    if settings.use_mock_parse or not settings.has_openai_key:
        response = mock_menu(restaurant_name)
        response.menu.source = source
        return response

    client = OpenAI(api_key=settings.openai_api_key)
    encoded = base64.b64encode(image_bytes).decode("utf-8")

    completion = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "system",
                "content": (
                    "Extract every menu item and price from this restaurant menu image. "
                    "Return JSON only. Prices must be integer cents. "
                    "Infer dietary flags conservatively from item names and descriptions. "
                    "Also classify each item course and whether it is shareable. "
                    "Estimate serves_min and serves_max conservatively: most entrees serve 1, "
                    "pizzas/share plates can serve 2-4, drinks serve 1."
                ),
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": "Parse this menu into structured sections and items with price_cents.",
                    },
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{encoded}"},
                    },
                ],
            },
        ],
        response_format={
            "type": "json_schema",
            "json_schema": {
                "name": "menu_parse",
                "schema": MENU_SCHEMA,
                "strict": True,
            },
        },
    )

    payload = json.loads(completion.choices[0].message.content or "{}")
    sections = [
        MenuSection(
            name=section["name"],
            items=[
                MenuItem(
                    name=item["name"],
                    description=item.get("description"),
                    price_cents=item["price_cents"],
                    course=item.get("course", MenuCourse.unknown),
                    is_shareable=item.get("is_shareable", False),
                    serves_min=item.get("serves_min", 1),
                    serves_max=item.get("serves_max", 1),
                    is_vegetarian=item.get("is_vegetarian", False),
                    is_vegan=item.get("is_vegan", False),
                    contains_fish=item.get("contains_fish", False),
                    contains_nuts=item.get("contains_nuts", False),
                    contains_pork=item.get("contains_pork", False),
                    is_gluten_free=item.get("is_gluten_free", False),
                )
                for item in section.get("items", [])
            ],
        )
        for section in payload.get("sections", [])
    ]

    menu = Menu(
        restaurant_name=payload.get("restaurant_name") or restaurant_name,
        sections=sections,
        scanned_at=datetime.utcnow(),
        source=source,
    )

    return ParseMenuResponse(
        menu=menu,
        confidence=0.9,
        warnings=payload.get("warnings", []),
    )
