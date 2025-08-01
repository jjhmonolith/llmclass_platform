from fastapi import APIRouter, HTTPException
from datetime import datetime
import pytz

from ..core.settings import settings
from ..core.logging import get_request_logger
from ..database import check_db_connection

router = APIRouter()


def get_seoul_time() -> str:
    """Get current time in Seoul timezone"""
    seoul_tz = pytz.timezone(settings.tz)
    return datetime.now(seoul_tz).isoformat()


@router.get("/healthz")
async def health_check():
    """Health check endpoint - returns server status"""
    try:
        # Check database connection
        db_ok = await check_db_connection()
        
        status = "ok" if db_ok else "degraded"
        
        response_data = {
            "status": status,
            "time": get_seoul_time(),
            "version": settings.build_version,
            "build_ts": settings.build_ts,
            "timezone": settings.tz,
            "database": "ok" if db_ok else "failed"
        }
        
        if not db_ok:
            raise HTTPException(status_code=503, detail=response_data)
            
        return response_data
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=503, detail="Service unavailable")


@router.get("/api/healthz")
async def api_health_check():
    """API health check - same as /healthz but under /api namespace"""
    return await health_check()


@router.get("/api/version")
async def get_version():
    """Get application version info"""
    return {
        "version": settings.build_version,
        "build_ts": settings.build_ts,
        "project": settings.project_name,
        "timezone": settings.tz,
        "environment": "development" if settings.debug_mode else "production"
    }