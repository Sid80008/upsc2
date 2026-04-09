from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    """
    Production-ready settings for the UPSC backend.
    Loads values from environment variables or .env file.
    """
    app_name: str = "UPSC Backend"
    version: str = "1.0.0"
    api_prefix: str = "/api/v1"
    
    database_url: str = "sqlite:///./upsc.db"
    secret_key: str
    gemini_api_key: str = ""
    news_api_key: str = ""
    groq_api_key: str = ""
    
    # Phase 4/5: AI Scheduler & Trajectory
    use_ai_scheduler: bool = True
    gemini_timeout_seconds: int = 10
    ai_fallback_enabled: bool = True
    max_ai_retries: int = 1
    
    # Phase 7: Infrastructure settings
    environment: str = "development"
    allowed_origins: str = "*"  # Comma-separated list for CORS
    seed_user_password: str = "" # Optional seeding password
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 30

    SUBJECTS: List[str] = [
        "History", "Geography", "Polity", "Economy",
        "Environment", "Current Affairs", "Essay"
    ]

    class Config:
        env_file = ".env"
        env_file_encoding = 'utf-8'
        case_sensitive = False

settings = Settings()

