from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import datetime
import pytz
from typing import Literal

from ..core.settings import settings
from ..core.logging import get_request_logger
from ..database import check_db_connection

router = APIRouter()


class HealthResponse(BaseModel):
    """Response model for health check endpoints"""
    status: Literal["ok", "degraded"]
    time: str
    version: str
    build_ts: str
    timezone: str
    database: Literal["ok", "failed"]


class VersionResponse(BaseModel):
    """Response model for version endpoint"""
    version: str
    build_ts: str
    project: str
    timezone: str
    environment: str


def get_seoul_time() -> str:
    """Get current time in Seoul timezone"""
    seoul_tz = pytz.timezone(settings.tz)
    return datetime.now(seoul_tz).isoformat()


@router.get("/healthz", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """Health check endpoint - returns server status with structured response"""
    try:
        # Check database connection
        db_ok = await check_db_connection()
        
        status = "ok" if db_ok else "degraded"
        
        response_data = HealthResponse(
            status=status,
            time=get_seoul_time(),
            version=settings.build_version,
            build_ts=settings.build_ts,
            timezone=settings.tz,
            database="ok" if db_ok else "failed"
        )
        
        if not db_ok:
            raise HTTPException(status_code=503, detail=response_data.dict())
            
        return response_data
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=503, detail="Service unavailable")


@router.get("/api/healthz", response_model=HealthResponse)
async def api_health_check() -> HealthResponse:
    """API health check - same as /healthz but under /api namespace"""
    return await health_check()


@router.get("/api/version", response_model=VersionResponse)
async def get_version() -> VersionResponse:
    """Get application version info with structured response"""
    return VersionResponse(
        version=settings.build_version,
        build_ts=settings.build_ts,
        project=settings.project_name,
        timezone=settings.tz,
        environment="development" if settings.debug_mode else "production"
    )