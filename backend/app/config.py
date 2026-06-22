from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    openai_api_key: str = Field(default="", validation_alias="OPENAI_API_KEY")
    use_mock_parse: bool = Field(default=False, validation_alias="PLATTER_USE_MOCK_PARSE")
    use_mock_narrate: bool = Field(default=False, validation_alias="PLATTER_USE_MOCK_NARRATE")
    google_places_api_key: str = Field(default="", validation_alias="GOOGLE_PLACES_API_KEY")
    database_url: str = Field(default="", validation_alias="DATABASE_URL")

    @property
    def has_openai_key(self) -> bool:
        key = self.openai_api_key.strip()
        return key.startswith("sk-") and key != "sk-your-key-here"

    @property
    def has_places_key(self) -> bool:
        return len(self.google_places_api_key.strip()) > 0

    @property
    def resolved_database_url(self) -> str:
        """Normalize Railway's postgres URL for SQLAlchemy; fall back to local SQLite."""
        url = self.database_url.strip()
        if not url:
            return "sqlite:///./platter_admin.db"
        if url.startswith("postgres://"):
            url = url.replace("postgres://", "postgresql+psycopg2://", 1)
        elif url.startswith("postgresql://"):
            url = url.replace("postgresql://", "postgresql+psycopg2://", 1)
        return url


settings = Settings()
