from pydantic_settings import BaseSettings
from typing import Optional
import os
from datetime import datetime


class Settings(BaseSettings):
    # Project info
    project_name: str = "mono-class-platform"
    public_domain: str = "platform.llmclass.org"
    
    # Server config
    backend_port: int = 8000
    log_level: str = "info"
    uvicorn_access_log: bool = True
    debug_mode: bool = False
    enable_echo_endpoint: bool = False
    
    # Build info
    build_version: str = "v0.1.0-dev"
    build_ts: str = datetime.utcnow().isoformat() + "Z"
    
    # Database
    postgres_host: str = "db"
    postgres_port: int = 5432
    postgres_db: str = "appdb"
    postgres_user: str = "appuser"
    postgres_password: str = "change_this_password_in_production"
    
    # Timezone
    tz: str = "Asia/Seoul"
    
    @property
    def database_url(self) -> str:
        return f"postgresql://{self.postgres_user}:{self.postgres_password}@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
    
    class Config:
        env_file = ".env"
        case_sensitive = False


# Global settings instance
settings = Settings()