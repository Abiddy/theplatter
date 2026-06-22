from pathlib import Path

from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse

from app.admin import router as admin_router
from app.db import init_db
from app.menu_parse import parse_menu_image
from app.narrate import narrate_combos
from app.optimizer import generate_combos
from app.schemas import (
    GenerateCombosRequest,
    GenerateCombosResponse,
    MenuSource,
    ParseMenuResponse,
)

app = FastAPI(title="Platter API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(admin_router)

TEMPLATES_DIR = Path(__file__).resolve().parent / "templates"


@app.on_event("startup")
def on_startup() -> None:
    init_db()


@app.get("/recs", response_class=HTMLResponse)
async def recs_portal() -> HTMLResponse:
    return HTMLResponse((TEMPLATES_DIR / "recs.html").read_text())


@app.get("/health")
async def health() -> dict[str, str | bool]:
    from app.config import settings

    return {
        "status": "ok",
        "openai_configured": settings.has_openai_key,
        "places_configured": settings.has_places_key,
        "mock_parse": settings.use_mock_parse,
        "mock_narrate": settings.use_mock_narrate,
    }


@app.post("/v1/menus/parse", response_model=ParseMenuResponse)
async def parse_menu(
    image: UploadFile = File(...),
    source: MenuSource = Form(MenuSource.camera),
    restaurant_name: str | None = Form(None),
) -> ParseMenuResponse:
    image_bytes = await image.read()
    return await parse_menu_image(image_bytes, source=source, restaurant_name=restaurant_name)


@app.post("/v1/combos/generate", response_model=GenerateCombosResponse)
async def create_combos(request: GenerateCombosRequest) -> GenerateCombosResponse:
    combos, _, tags = generate_combos(request.menu, request.constraints)
    summary = narrate_combos(request.menu, request.constraints, combos)
    return GenerateCombosResponse(combos=combos, ai_summary=summary, constraint_tags=tags)
