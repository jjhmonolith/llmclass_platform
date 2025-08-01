import secrets
from fastapi import HTTPException, Depends, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from typing import Optional

from .settings import settings

security = HTTPBasic()


def verify_docs_credentials(credentials: HTTPBasicCredentials = Depends(security)) -> str:
    """Verify credentials for documentation access"""
    is_correct_username = secrets.compare_digest(
        credentials.username, settings.docs_auth_user
    )
    is_correct_password = secrets.compare_digest(
        credentials.password, settings.docs_auth_password
    )
    
    if not (is_correct_username and is_correct_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid documentation credentials",
            headers={"WWW-Authenticate": "Basic"},
        )
    
    return credentials.username


def get_docs_dependency() -> Optional[callable]:
    """Get dependency for documentation endpoints based on settings"""
    if settings.docs_auth_enabled:
        return Depends(verify_docs_credentials)
    return None