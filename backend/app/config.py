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

    @property
    def has_openai_key(self) -> bool:
        key = self.openai_api_key.strip()
        return key.startswith("sk-") and key != "sk-your-key-here"


settings = Settings()
