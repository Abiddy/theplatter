"""Admin + app-facing API for the recommendations portal."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlmodel import Session, select

from app.db import get_session
from app.menu_parse import parse_menu_text
from app.models import RestaurantRecord
from app.personas import build_cards_for_menu
from app.places import search_places
from app.schemas import Menu

router = APIRouter()


# ---------- request/response models ----------

class PlaceResult(BaseModel):
    place_id: str
    name: str
    address: str
    rating: float
    review_count: int
    price_tier: str
    cuisine: str
    lat: float | None
    lng: float | None
    distance_miles: float


class PreviewRequest(BaseModel):
    name: str
    cuisine: str = "Restaurant"
    distance_miles: float = 1.0
    image_seed: int = 0
    is_verified: bool = True
    raw_menu_text: str


class PreviewResponse(BaseModel):
    menu: Menu
    recommendations: list[dict]
    warnings: list[str] = []


class SaveRequest(BaseModel):
    place_id: str | None = None
    name: str
    cuisine: str = "Restaurant"
    address: str = ""
    lat: float | None = None
    lng: float | None = None
    rating: float = 0.0
    review_count: int = 0
    price_tier: str = "$$"
    distance_miles: float = 1.0
    image_seed: int = 0
    is_verified: bool = True
    raw_menu_text: str
    menu: dict
    recommendations: list[dict]


# ---------- Places search ----------

@router.get("/admin/places/search", response_model=list[PlaceResult])
async def places_search(q: str) -> list[dict]:
    if not q.strip():
        return []
    try:
        return await search_places(q.strip())
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc))
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=502, detail=f"Places lookup failed: {exc}")


# ---------- Generate menu + recs (preview, no save) ----------

@router.post("/admin/generate", response_model=PreviewResponse)
def generate_preview(request: PreviewRequest) -> PreviewResponse:
    if not request.raw_menu_text.strip():
        raise HTTPException(status_code=400, detail="Menu text is empty.")

    try:
        parsed = parse_menu_text(request.raw_menu_text, restaurant_name=request.name)
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc))
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=502, detail=f"Menu parse failed: {exc}")

    cards = build_cards_for_menu(
        parsed.menu,
        restaurant_name=request.name,
        cuisine=request.cuisine,
        distance_miles=request.distance_miles,
        image_seed=request.image_seed,
        is_verified=request.is_verified,
    )

    return PreviewResponse(menu=parsed.menu, recommendations=cards, warnings=parsed.warnings)


# ---------- Save reviewed restaurant ----------

@router.post("/admin/restaurants")
def save_restaurant(request: SaveRequest, session: Session = Depends(get_session)) -> dict:
    existing = None
    if request.place_id:
        existing = session.exec(
            select(RestaurantRecord).where(RestaurantRecord.place_id == request.place_id)
        ).first()
    if existing is None:
        existing = session.exec(
            select(RestaurantRecord).where(RestaurantRecord.name == request.name)
        ).first()

    record = existing or RestaurantRecord(name=request.name)
    record.place_id = request.place_id
    record.name = request.name
    record.cuisine = request.cuisine
    record.address = request.address
    record.lat = request.lat
    record.lng = request.lng
    record.rating = request.rating
    record.review_count = request.review_count
    record.price_tier = request.price_tier
    record.distance_miles = request.distance_miles
    record.image_seed = request.image_seed
    record.is_verified = request.is_verified
    record.raw_menu_text = request.raw_menu_text
    record.menu_json = request.menu
    record.recommendations_json = request.recommendations
    record.status = "published" if request.recommendations else "draft"
    record.updated_at = datetime.utcnow()

    session.add(record)
    session.commit()
    session.refresh(record)
    return {"id": str(record.id), "status": record.status, "cards": len(record.recommendations_json)}


@router.get("/admin/restaurants")
def list_restaurants(session: Session = Depends(get_session)) -> list[dict]:
    records = session.exec(select(RestaurantRecord).order_by(RestaurantRecord.updated_at.desc())).all()
    return [
        {
            "id": str(r.id),
            "place_id": r.place_id,
            "name": r.name,
            "cuisine": r.cuisine,
            "status": r.status,
            "distance_miles": r.distance_miles,
            "card_count": len(r.recommendations_json or []),
            "menu_item_count": sum(len(s.get("items", [])) for s in (r.menu_json or {}).get("sections", [])),
            "updated_at": r.updated_at.isoformat(),
        }
        for r in records
    ]


@router.get("/admin/restaurants/{restaurant_id}")
def get_restaurant(restaurant_id: UUID, session: Session = Depends(get_session)) -> dict:
    record = session.get(RestaurantRecord, restaurant_id)
    if record is None:
        raise HTTPException(status_code=404, detail="Restaurant not found.")
    return {
        "id": str(record.id),
        "name": record.name,
        "cuisine": record.cuisine,
        "distance_miles": record.distance_miles,
        "status": record.status,
        "menu": record.menu_json or {},
        "recommendations": record.recommendations_json or [],
    }


@router.delete("/admin/restaurants/{restaurant_id}")
def delete_restaurant(restaurant_id: UUID, session: Session = Depends(get_session)) -> dict:
    record = session.get(RestaurantRecord, restaurant_id)
    if record is None:
        raise HTTPException(status_code=404, detail="Restaurant not found.")
    session.delete(record)
    session.commit()
    return {"deleted": str(restaurant_id)}


# ---------- App-facing: all published recommendation cards ----------

@router.get("/v1/discover/recommendations")
def discover_recommendations(session: Session = Depends(get_session)) -> list[dict]:
    records = session.exec(
        select(RestaurantRecord).where(RestaurantRecord.status == "published")
    ).all()
    cards: list[dict] = []
    for record in records:
        cards.extend(record.recommendations_json or [])
    return cards
