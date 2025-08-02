from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
from app.services.topic_service import topic_service

router = APIRouter()

class InitialMessageRequest(BaseModel):
    topic: str

class InitialMessageResponse(BaseModel):
    message: str

class InitialGuideResponse(BaseModel):
    guide_title: str
    guide_content: str
    starter_questions: List[str]

@router.post("/initial-message", response_model=InitialMessageResponse)
async def get_initial_message(request: InitialMessageRequest):
    try:
        message = topic_service.get_initial_message(request.topic)
        return InitialMessageResponse(message=message)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/initial-guide", response_model=InitialGuideResponse)
async def get_initial_guide(request: InitialMessageRequest):
    try:
        guide = await topic_service.get_initial_tutor_guide(request.topic)
        return InitialGuideResponse(**guide)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))