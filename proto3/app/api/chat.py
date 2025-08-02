from fastapi import APIRouter, HTTPException
from app.models.request_models import OneshotRequest, EvaluatePromptRequest
from app.services.openai_service import OpenAIService
from datetime import datetime

router = APIRouter()

def get_openai_service():
    return OpenAIService()

@router.post("/oneshot")
async def oneshot_llm(request: OneshotRequest):
    """One-shot LLM API 엔드포인트"""
    import logging
    
    logger = logging.getLogger(__name__)
    logger.info(f"OneShot API 호출 - prompt 길이: {len(request.prompt) if request.prompt else 0}")
    
    try:
        if not request.prompt:
            raise HTTPException(status_code=400, detail="Prompt is required")
        
        if len(request.prompt.strip()) == 0:
            raise HTTPException(status_code=400, detail="Prompt cannot be empty")
        
        logger.info(f"OpenAI 서비스 초기화 중...")
        openai_service = get_openai_service()
        
        logger.info(f"OneShot 생성 중 - model: {request.model}, temp: {request.temperature}, max_tokens: {request.maxTokens}")
        result = openai_service.generate_oneshot(
            prompt=request.prompt,
            model=request.model,
            temperature=request.temperature,
            max_tokens=request.maxTokens
        )
        
        logger.info(f"OneShot 결과: success={result.get('success', False)}")
        
        if not result.get("success", False):
            error_msg = result.get("error", "Unknown error occurred")
            logger.error(f"OpenAI 서비스 오류: {error_msg}")
            raise HTTPException(status_code=500, detail=f"AI response generation failed: {error_msg}")
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"OneShot API 예상치 못한 오류: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/evaluate-prompt")
async def evaluate_prompt(request: EvaluatePromptRequest):
    """RTCF 기준 프롬프트 평가 API 엔드포인트"""
    if not request.currentPrompt or not request.learningObjective:
        raise HTTPException(
            status_code=400, 
            detail="Current prompt and learning objective are required"
        )
    
    try:
        openai_service = get_openai_service()
        
        # 설정을 딕셔너리로 변환
        settings = request.settings.model_dump()
        
        # 이상적인 프롬프트 생성 (제공되지 않은 경우)
        ideal_prompt = request.idealPrompt
        if not ideal_prompt:
            ideal_prompt = openai_service.generate_ideal_prompt(
                request.learningObjective, settings
            )
        
        # RTCF 평가 수행
        evaluation_result = openai_service.evaluate_prompt(
            current_prompt=request.currentPrompt,
            learning_objective=request.learningObjective,
            settings=settings,
            previous_prompt=request.previousPrompt
        )
        
        return {
            "success": True,
            "evaluation": evaluation_result,
            "idealPrompt": ideal_prompt,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Evaluation failed: {str(e)}")

@router.get("/health")
async def health_check():
    """헬스 체크 엔드포인트"""
    return {
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
        "service": "llm-classroom-proto3"
    }

@router.post("/test-oneshot")
async def test_oneshot():
    """OneShot API 테스트 엔드포인트"""
    import logging
    
    logger = logging.getLogger(__name__)
    logger.info("OneShot 테스트 API 호출")
    
    try:
        # 간단한 테스트 프롬프트
        test_request = OneshotRequest(
            prompt="안녕하세요! 간단한 인사말로 응답해주세요.",
            model="gpt-4o-mini",
            temperature=0.7,
            maxTokens=100
        )
        
        logger.info("테스트 프롬프트로 OneShot API 호출")
        result = await oneshot_llm(test_request)
        
        return {
            "test_status": "success",
            "api_working": True,
            "sample_response": result.get("response", "")[:100] + "..." if result.get("response") else "No response",
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"OneShot 테스트 실패: {str(e)}")
        return {
            "test_status": "failed",
            "api_working": False,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }