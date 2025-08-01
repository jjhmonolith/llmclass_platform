from pydantic_settings import BaseSettings
from typing import Optional, List
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
    
    # OpenAPI Documentation
    docs_enabled: bool = True
    docs_auth_enabled: bool = False
    docs_auth_user: str = "admin"
    docs_auth_password: str = "secret"
    
    # CORS
    cors_origins: List[str] = ["*"]
    
    @property
    def database_url(self) -> str:
        return f"postgresql://{self.postgres_user}:{self.postgres_password}@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
    
    @property
    def effective_cors_origins(self) -> List[str]:
        """Get CORS origins based on debug mode"""
        if self.debug_mode:
            return ["*"]
        return [f"https://{self.public_domain}", f"http://localhost:3000"]
    
    @property
    def docs_url(self) -> Optional[str]:
        """Get docs URL if enabled"""
        return "/api/docs" if self.docs_enabled else None
    
    @property
    def redoc_url(self) -> Optional[str]:
        """Get redoc URL if enabled"""
        return "/api/redoc" if self.docs_enabled else None
    
    class Config:
        env_file = ".env"
        case_sensitive = False


# Global settings instance
settings = Settings()