from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Any
import uvicorn

app = FastAPI(
    title="LLM Classroom Hub",
    description="AI 학습 서비스 허브 - 다양한 AI 튜터들을 한 곳에서",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 템플릿 설정
templates = Jinja2Templates(directory="../frontend/templates")

# 정적 파일 마운트
app.mount("/static", StaticFiles(directory="../frontend/static"), name="static")

# 서비스 정보 데이터 모델
class ServiceInfo(BaseModel):
    id: str
    name: str
    description: str
    url: str
    icon: str
    status: str  # "active", "beta", "coming_soon"
    category: str
    features: List[str]
    difficulty: str  # "beginner", "intermediate", "advanced"

# 서비스 목록 (향후 데이터베이스로 이전 가능)
SERVICES = [
    ServiceInfo(
        id="socratic",
        name="소크라테스 AI",
        description="질문을 통한 탐구식 학습. 비판적 사고력 개발에 최적화된 AI 튜터입니다.",
        url="https://socratic.llmclass.org",
        icon="🤔",
        status="active",
        category="탐구형 학습",
        features=["대화형 학습", "비판적 사고", "개념 탐구", "논리적 추론"],
        difficulty="intermediate"
    ),
    ServiceInfo(
        id="strategic",
        name="전략적 학습 AI",
        description="체계적이고 전략적인 학습 접근법을 제공하는 AI 튜터입니다.",
        url="https://strategic.llmclass.org",
        icon="🎯",
        status="active",
        category="체계적 학습",
        features=["학습 계획", "목표 설정", "진도 관리", "전략적 사고"],
        difficulty="beginner"
    ),
    ServiceInfo(
        id="fire",
        name="FIRE 학습법",
        description="Focus, Inquire, Reflect, Extend 방법론을 활용한 심화 학습 시스템입니다.",
        url="https://fire.llmclass.org",
        icon="🔥",
        status="active",
        category="심화 학습",
        features=["집중 학습", "탐구 질문", "성찰적 사고", "확장 적용"],
        difficulty="advanced"
    ),
    # 향후 추가될 서비스들
    ServiceInfo(
        id="math",
        name="수학 튜터 AI",
        description="개인 맞춤형 수학 학습과 문제 해결 능력을 기르는 AI 튜터입니다.",
        url="https://math.llmclass.org",
        icon="📊",
        status="coming_soon",
        category="교과목 학습",
        features=["단계별 설명", "문제 풀이", "개념 정리", "실전 연습"],
        difficulty="beginner"
    ),
    ServiceInfo(
        id="english",
        name="영어 회화 AI",
        description="자연스러운 대화를 통한 영어 실력 향상을 돕는 AI 튜터입니다.",
        url="https://english.llmclass.org",
        icon="🗣",
        status="coming_soon",
        category="언어 학습",
        features=["회화 연습", "발음 교정", "문법 설명", "어휘 확장"],
        difficulty="beginner"
    ),
    ServiceInfo(
        id="science",
        name="과학 탐구 AI",
        description="호기심을 자극하는 과학 실험과 탐구 활동을 안내하는 AI 튜터입니다.",
        url="https://science.llmclass.org",
        icon="🔬",
        status="coming_soon",
        category="교과목 학습",
        features=["실험 설계", "가설 검증", "데이터 분석", "과학적 사고"],
        difficulty="intermediate"
    )
]

@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    """메인 허브 페이지"""
    # 서비스들을 카테고리별로 그룹화
    services_by_category = {}
    for service in SERVICES:
        if service.category not in services_by_category:
            services_by_category[service.category] = []
        services_by_category[service.category].append(service)
    
    return templates.TemplateResponse("index.html", {
        "request": request,
        "services": SERVICES,
        "services_by_category": services_by_category,
        "total_services": len(SERVICES),
        "active_services": len([s for s in SERVICES if s.status == "active"]),
        "coming_soon_services": len([s for s in SERVICES if s.status == "coming_soon"])
    })

@app.get("/api/services")
async def get_services():
    """서비스 목록 API"""
    return {
        "services": SERVICES,
        "total": len(SERVICES),
        "active": len([s for s in SERVICES if s.status == "active"]),
        "coming_soon": len([s for s in SERVICES if s.status == "coming_soon"])
    }

@app.get("/api/services/{service_id}")
async def get_service(service_id: str):
    """특정 서비스 정보 API"""
    service = next((s for s in SERVICES if s.id == service_id), None)
    if service:
        return service
    return {"error": "Service not found"}

@app.get("/api/services/category/{category}")
async def get_services_by_category(category: str):
    """카테고리별 서비스 목록 API"""
    services = [s for s in SERVICES if s.category == category]
    return {
        "category": category,
        "services": services,
        "count": len(services)
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "llm_classroom_hub",
        "version": "1.0.0",
        "total_services": len(SERVICES)
    }

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8003,
        reload=True
    )