"""Database models for the admin portal.

A single `RestaurantRecord` row holds everything for one restaurant: its
Places metadata, the rough menu text you pasted, the structured menu (JSON),
and the generated recommendation cards (JSON). Keeping menu + recs as JSON
columns keeps the schema simple for an internal tool.
"""

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID, uuid4

from sqlalchemy import Column
from sqlalchemy.types import JSON
from sqlmodel import Field, SQLModel


class RestaurantRecord(SQLModel, table=True):
    __tablename__ = "restaurants"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    place_id: Optional[str] = Field(default=None, index=True)
    name: str = Field(index=True)
    cuisine: str = "Restaurant"
    address: str = ""
    lat: Optional[float] = None
    lng: Optional[float] = None
    rating: float = 0.0
    review_count: int = 0
    price_tier: str = "$$"
    distance_miles: float = 1.0
    image_seed: int = 0
    is_verified: bool = False

    # Workflow status: "draft" (no menu yet) | "published" (has menu + recs)
    status: str = Field(default="draft", index=True)

    raw_menu_text: str = ""
    menu_json: dict = Field(default_factory=dict, sa_column=Column(JSON))
    recommendations_json: list = Field(default_factory=list, sa_column=Column(JSON))

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
