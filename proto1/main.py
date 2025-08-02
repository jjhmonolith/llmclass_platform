from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.api import chat, initial
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="LLM Classroom",
    description="학생들이 LLM 사용법과 활용을 배울 수 있는 온라인 에듀테크 도구",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(chat.router, prefix="/api/v1/chat", tags=["chat"])
app.include_router(initial.router, prefix="/api/v1/chat", tags=["initial"])

@app.get("/api")
async def api_root():
    return {"message": "Welcome to LLM Classroom API"}

@app.get("/")
async def root():
    # 서브도메인에서는 바로 메인 페이지 제공
    from fastapi.responses import RedirectResponse
    return RedirectResponse(url="/topic-selection.html")

# Static files for frontend (이것은 마지막에 와야 함)
app.mount("/", StaticFiles(directory="frontend", html=True), name="static")

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8001,
        reload=True
    )