from .factory import create_app
from .core.settings import settings

# Create app using factory pattern
app = create_app()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=settings.backend_port,
        log_level=settings.log_level,
        access_log=settings.uvicorn_access_log,
        reload=settings.debug_mode
    )