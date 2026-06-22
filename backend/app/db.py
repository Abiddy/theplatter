"""Database engine + session for the admin portal.

Uses Postgres in production (Railway DATABASE_URL) and falls back to a local
SQLite file for development so you can run the portal without Postgres.
"""

from __future__ import annotations

from collections.abc import Iterator

from sqlmodel import Session, SQLModel, create_engine

from app.config import settings

_db_url = settings.resolved_database_url
_connect_args = {"check_same_thread": False} if _db_url.startswith("sqlite") else {}

engine = create_engine(_db_url, echo=False, connect_args=_connect_args, pool_pre_ping=True)


def init_db() -> None:
    # Import models so SQLModel registers the tables before create_all.
    from app import models  # noqa: F401

    SQLModel.metadata.create_all(engine)


def get_session() -> Iterator[Session]:
    with Session(engine) as session:
        yield session
