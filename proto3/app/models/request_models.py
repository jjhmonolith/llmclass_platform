from pydantic import BaseModel
from typing import Optional, Dict, Any

class OneshotRequest(BaseModel):
    prompt: str
    model: str = "gpt-4o-mini"
    temperature: float = 0.7
    maxTokens: int = 1000

class Settings(BaseModel):
    topic: str = "환경 문제"
    difficulty: str = "중급"
    schoolLevel: str = "중학생"

class EvaluatePromptRequest(BaseModel):
    currentPrompt: str
    learningObjective: str
    previousPrompt: Optional[str] = None
    idealPrompt: Optional[str] = None
    settings: Settings = Settings()

class RTCFScore(BaseModel):
    score: int
    feedback: str

class RTCFScores(BaseModel):
    role: RTCFScore
    task: RTCFScore
    context: RTCFScore
    format: RTCFScore

class EvaluationResult(BaseModel):
    rtcf_scores: RTCFScores
    improvements: list[str]
    suggestions: list[str]
    motivational_comment: str