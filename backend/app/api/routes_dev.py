from fastapi import APIRouter, Request, HTTPException
from datetime import datetime
import pytz

from ..core.settings import settings
from ..core.logging import get_request_logger, get_client_ip
from ..core.errors import APIError

router = APIRouter(prefix="/api/dev", tags=["development"])


def get_seoul_time() -> str:
    """Get current time in Seoul timezone"""
    seoul_tz = pytz.timezone(settings.tz)
    return datetime.now(seoul_tz).isoformat()


@router.get("/ping")
async def dev_ping(request: Request):
    """Development ping endpoint - returns request info"""
    request_logger = get_request_logger(request)
    request_id = getattr(request.state, "request_id", "unknown")
    
    await request_logger.ainfo("dev_ping_called", request_id=request_id)
    
    return {
        "message": "pong",
        "timestamp": get_seoul_time(),
        "request_id": request_id,
        "client_ip": get_client_ip(request),
        "user_agent": request.headers.get("user-agent", "unknown"),
        "version": settings.build_version,
        "environment": "development" if settings.debug_mode else "production"
    }


@router.get("/error")
async def dev_error(request: Request):
    """Development error endpoint - intentionally raises 500 error"""
    request_logger = get_request_logger(request)
    request_id = getattr(request.state, "request_id", "unknown")
    
    await request_logger.awarn("dev_error_called", request_id=request_id)
    
    # Intentionally raise an error to test error handling
    raise APIError(
        status_code=500,
        detail="This is an intentional test error",
        error_code="DEV_TEST_ERROR",
        extra_data={"request_id": request_id, "timestamp": get_seoul_time()}
    )


# Echo endpoint (development only)
if settings.enable_echo_endpoint:
    @router.get("/echo")
    @router.post("/echo")
    @router.put("/echo")
    @router.delete("/echo")
    async def echo_request(request: Request):
        """Echo request details (development only)"""
        request_logger = get_request_logger(request)
        request_id = getattr(request.state, "request_id", "unknown")
        
        await request_logger.ainfo("dev_echo_called", request_id=request_id)
        
        # Get request body if present
        body = None
        if request.method in ["POST", "PUT", "PATCH"]:
            try:
                body = await request.body()
                body = body.decode("utf-8") if body else None
            except:
                body = "<binary_data>"
        
        return {
            "method": request.method,
            "url": str(request.url),
            "path": request.url.path,
            "query_params": dict(request.query_params),
            "headers": dict(request.headers),
            "client_ip": get_client_ip(request),
            "body": body,
            "timestamp": get_seoul_time(),
            "request_id": request_id
        }