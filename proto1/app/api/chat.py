from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Dict, Optional
from app.services.openai_service import openai_service
from app.services.tutor_service import tutor_service
import json

router = APIRouter()

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    model: str = "gpt-4o-mini"
    topic: Optional[str] = "일반적인 주제"

class ChatResponse(BaseModel):
    response: str
    model: str
    tutor_feedback: Optional[Dict] = None

@router.post("/chat", response_model=ChatResponse)
async def chat_with_gpt(request: ChatRequest):
    try:
        messages = [{"role": msg.role, "content": msg.content} for msg in request.messages]
        response = await openai_service.chat_completion(messages, request.model, request.topic)
        
        # 튜터 피드백 생성
        tutor_feedback = None
        if len(messages) > 0:
            last_user_message = ""
            for msg in reversed(messages):
                if msg["role"] == "user":
                    last_user_message = msg["content"]
                    break
            
            if last_user_message:
                tutor_feedback = await tutor_service.analyze_conversation(
                    messages, 
                    last_user_message, 
                    response,
                    request.topic
                )
        
        return ChatResponse(
            response=response, 
            model=request.model,
            tutor_feedback=tutor_feedback
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/chat/stream")
async def stream_chat_with_gpt(request: ChatRequest):
    try:
        messages = [{"role": msg.role, "content": msg.content} for msg in request.messages]
        
        async def generate():
            async for chunk in openai_service.stream_chat_completion(messages, request.model):
                yield f"data: {json.dumps({'content': chunk})}\n\n"
            yield f"data: {json.dumps({'content': '[DONE]'})}\n\n"
        
        return StreamingResponse(
            generate(), 
            media_type="text/plain",
            headers={"Cache-Control": "no-cache", "Connection": "keep-alive"}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))