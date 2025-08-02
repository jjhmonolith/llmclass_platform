from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.api import chat
import os
import logging
from dotenv import load_dotenv

# 환경변수 로드
load_dotenv()

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('llm-classroom.log', encoding='utf-8')
    ]
)

logger = logging.getLogger(__name__)

app = FastAPI(
    title="LLM Classroom Proto3",
    description="RTCF 프롬프트 학습 플랫폼 - 단일 서버 구조",
    version="3.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API 라우터 추가
app.include_router(chat.router, prefix="/api", tags=["chat"])

@app.get("/api")
async def api_root():
    return {"message": "Welcome to LLM Classroom Proto3 API"}

@app.get("/")
async def root():
    from fastapi.responses import RedirectResponse
    return RedirectResponse(url="/index.html")

# Static files for frontend (이것은 마지막에 와야 함)
app.mount("/", StaticFiles(directory="frontend", html=True), name="static")


if __name__ == "__main__":
    import uvicorn
    import os
    
    # OpenAI API 키 검증
    openai_api_key = os.getenv("OPENAI_API_KEY")
    if not openai_api_key:
        logger.error("❌ OPENAI_API_KEY 환경변수가 설정되지 않았습니다!")
        print("❌ 오류: OPENAI_API_KEY 환경변수가 설정되지 않았습니다.")
        print("다음 명령어로 설정하세요:")
        print("export OPENAI_API_KEY=your_api_key_here")
        exit(1)
    elif len(openai_api_key) < 40:
        logger.warning("⚠️ OPENAI_API_KEY가 너무 짧습니다. 올바른 키인지 확인하세요.")
    else:
        logger.info("✅ OPENAI_API_KEY 확인됨")
    
    # 환경변수에서 설정 읽기
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8002))
    reload = os.getenv("ENV", "development") != "production"
    
    logger.info(f"🚀 Starting LLM Classroom Proto3 server...")
    logger.info(f"📍 Host: {host}")
    logger.info(f"🌐 Port: {port}")
    logger.info(f"🔄 Reload: {reload}")
    logger.info(f"🌍 Environment: {os.getenv('ENV', 'development')}")
    
    print(f"🚀 Starting LLM Classroom Proto3 server...")
    print(f"📍 Host: {host}")
    print(f"🌐 Port: {port}")
    print(f"🔄 Reload: {reload}")
    print(f"🌍 Environment: {os.getenv('ENV', 'development')}")
    print(f"📝 로그 파일: llm-classroom.log")
    
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=reload,
        log_level="info"
    )