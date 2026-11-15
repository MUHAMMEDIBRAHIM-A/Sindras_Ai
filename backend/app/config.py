"""Application configuration loaded from environment variables."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Database
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/synras_rag"

    # Gemini
    gemini_api_key: str = ""

    # JWT
    jwt_secret_key: str = "change_me"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 1440  # 24 hours

    # Upload
    max_upload_size_mb: int = 20

    # Chunking
    chunk_size: int = 500
    chunk_overlap: int = 50


settings = Settings()
