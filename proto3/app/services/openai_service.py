from openai import OpenAI
import os
import json
from datetime import datetime
from typing import Optional

class OpenAIService:
    def __init__(self):
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY environment variable is not set")
        try:
            # 명시적으로 필요한 매개변수만 전달
            self.client = OpenAI(
                api_key=api_key,
                timeout=30.0
            )
        except Exception as e:
            print(f"OpenAI client initialization error: {e}")
            # 기본 설정으로 재시도
            self.client = OpenAI(api_key=api_key)
    
    def generate_oneshot(self, prompt: str, model: str = "gpt-4o-mini", 
                              temperature: float = 0.7, max_tokens: int = 1000):
        """One-shot LLM 응답 생성"""
        import logging
        
        logger = logging.getLogger(__name__)
        logger.info(f"OneShot 생성 시작 - model: {model}, prompt 길이: {len(prompt)}")
        
        try:
            # OpenAI API 키 확인
            if not hasattr(self, 'client') or self.client is None:
                raise ValueError("OpenAI client가 초기화되지 않았습니다.")
            
            logger.info("OpenAI API 호출 시작")
            completion = self.client.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                temperature=temperature,
                max_tokens=max_tokens
            )
            
            if not completion.choices or len(completion.choices) == 0:
                raise ValueError("OpenAI API에서 응답을 받지 못했습니다.")
            
            response_content = completion.choices[0].message.content
            if not response_content:
                raise ValueError("OpenAI API에서 빈 응답을 반환했습니다.")
            
            logger.info(f"OpenAI API 호출 성공 - 응답 길이: {len(response_content)}")
            
            return {
                "success": True,
                "response": response_content,
                "usage": completion.usage.model_dump() if completion.usage else None,
                "model": model,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"OneShot 생성 오류: {str(e)}", exc_info=True)
            
            # 더 구체적인 오류 메시지 제공
            error_message = str(e)
            if "api_key" in error_message.lower():
                error_message = "OpenAI API 키가 올바르지 않습니다."
            elif "quota" in error_message.lower() or "billing" in error_message.lower():
                error_message = "OpenAI API 사용량 한도에 도달했습니다."
            elif "rate_limit" in error_message.lower():
                error_message = "OpenAI API 요청 한도에 도달했습니다. 잠시 후 다시 시도해주세요."
            elif "model" in error_message.lower():
                error_message = f"모델 '{model}'을 사용할 수 없습니다."
            
            return {
                "success": False,
                "error": error_message,
                "original_error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    def generate_ideal_prompt(self, learning_objective: str, settings: dict):
        """이상적인 프롬프트 생성"""
        difficulty_guide = {
            '초급': '기본적이고 간단한 요소들을 포함한',
            '중급': '구체적이고 체계적인 요소들을 포함한', 
            '고급': '정교하고 전문적인 요소들을 포함한'
        }
        
        prompt = f"""다음 학습 목표에 대해 {settings['schoolLevel']}이 작성할 수 있는 이상적인 프롬프트를 생성해주세요:

**학습 목표**:
{learning_objective}

**학습자 정보**:
- 학교급: {settings['schoolLevel']}
- 난이도: {settings['difficulty']}
- 주제: {settings['topic']}

**이상적인 프롬프트 조건** ({settings['difficulty']} 수준):
- Role (역할): AI의 역할이 명확히 설정됨
- Task (작업): 수행할 작업이 구체적으로 기술됨  
- Context (맥락): 충분한 배경 정보와 맥락 제공
- Format (형식): 원하는 출력 형식이 명시됨

{difficulty_guide[settings['difficulty']]} {settings['schoolLevel']} 수준에 적합한 이상적인 프롬프트만 생성해주세요:"""

        try:
            completion = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3,
                max_tokens=500
            )
            return completion.choices[0].message.content
        except Exception as e:
            return f"이상적인 프롬프트 생성 중 오류가 발생했습니다: {str(e)}"
    
    def evaluate_prompt(self, current_prompt: str, learning_objective: str, 
                            settings: dict, previous_prompt: Optional[str] = None):
        """FIRE 프레임워크 기준으로 프롬프트 평가"""
        
        tone_style = {
            '초등학생': {
                'tone': '친근하고 격려 중심의 쉬운 말투로',
                'expectation': '초등학생이 이해할 수 있는 수준에서'
            },
            '중학생': {
                'tone': '친절하면서도 체계적인 설명으로',
                'expectation': '중학생 수준에서'
            },
            '고등학생': {
                'tone': '명확하고 효율적인 설명으로',
                'expectation': '고등학생 수준에서'
            },
            '대학생': {
                'tone': '전문적이고 논리적인 설명으로',
                'expectation': '대학생 수준에서'
            }
        }
        
        difficulty_standards = {
            '초급': {
                'description': '기본적인 요소 위주로',
                'criteria': '기본 요소가 포함되면 2점 이상'
            },
            '중급': {
                'description': '구체적이고 체계적인 요소 위주로',
                'criteria': '구체적 요소가 포함되면 2점 이상'
            },
            '고급': {
                'description': '정교하고 전문적인 요소 위주로',
                'criteria': '전문적 요소가 포함되면 2점 이상'
            }
        }
        
        previous_prompt_section = f"""**이전 프롬프트 (개선도 비교용)**:
"{previous_prompt}"

""" if previous_prompt else ""
        
        evaluation_prompt = f"""당신은 FIRE 프롬프트 평가 전문가입니다. 
{settings['schoolLevel']}을 대상으로 {tone_style[settings['schoolLevel']]['tone']} 피드백해주세요.

**FIRE 프레임워크 평가 기준 (각 요소 0-3점, 총 12점 만점)**

📘 FIRE 프롬프트 평가 프레임워크:
FIRE 프레임워크는 사용자가 효율적이고 목적에 부합하는 프롬프트를 설계할 수 있도록 돕는 구성 방식입니다.

**학습자 정보**:
- 학교급: {settings['schoolLevel']}
- 난이도: {settings['difficulty']}
- 주제: {settings['topic']}

**학생이 작성한 프롬프트**:
"{current_prompt}"

**달성해야 할 학습 목표**:
{learning_objective}

{previous_prompt_section}**FIRE 평가 기준 (각 0-3점)**:

**1. F: Focus (무엇을 알고 싶은가?)**
- 3점: 요청 주제가 명확하며, 작업의 구체적인 유형이 포함됨
- 2점: 주제는 있지만 작업 방식이 모호함
- 1점: 주제가 매우 모호하거나 넓음
- 0점: 요청 주제가 전혀 없음

**2. I: Input (어떤 정보를 주었는가?)**
- 3점: 명확한 배경정보, 맥락, 대상 수준 등을 제공함
- 2점: 배경이 부분적으로 포함됨
- 1점: 입력 정보가 매우 간략하거나 암시적임
- 0점: 문맥, 배경, 대상 정보 없음

**3. R: Rules (어떻게 표현되길 원하는가?)**
- 3점: 분량, 형식, 금지 조건 등이 구체적으로 명시됨
- 2점: 한두 가지 형식 조건이 명시됨
- 1점: 형식 요구는 있지만 모호하거나 불완전
- 0점: 출력 형식에 대한 언급 없음

**4. E: Effect (결과가 어떻게 쓰일 것인가?)**
- 3점: 출력 결과의 사용 목적이 명확히 언급됨
- 2점: 사용 맥락이 암시되지만 명확하진 않음
- 1점: 효과/목적이 매우 추상적임
- 0점: 결과 활용 맥락 전혀 없음

**총점 기준**:
- 10-12점: ✅ 우수 (목적에 부합하는 고성능 프롬프트)
- 7-9점: ☑️ 양호 (일부 개선 요소 있음)
- 4-6점: ⚠️ 개선 필요 (전반적으로 불완전)
- 0-3점: ❌ 부적절 (학습이 필요함)

**평가 가이드라인**:
- {tone_style[settings['schoolLevel']]['expectation']} 달성 가능한 현실적 평가 기준 적용
- {difficulty_standards[settings['difficulty']]['description']} 평가하되, {difficulty_standards[settings['difficulty']]['criteria']}
- {settings['schoolLevel']}이 스스로 개선할 수 있는 구체적 힌트 제공
- {tone_style[settings['schoolLevel']]['tone']} 동기부여와 함께 실질적 개선 방향 제시

다음 JSON 형식으로만 응답해주세요:
{{
  "fire_scores": {{
    "focus": {{ "score": 숫자(0-3), "feedback": "목적의 명확성 분석 및 개선 방향" }},
    "input": {{ "score": 숫자(0-3), "feedback": "맥락/자료 제공도 분석 및 개선 방향" }},
    "rules": {{ "score": 숫자(0-3), "feedback": "형식/조건 명시도 분석 및 개선 방향" }},
    "effect": {{ "score": 숫자(0-3), "feedback": "사용 목적 구체성 분석 및 개선 방향" }}
  }},
  "total_score": 숫자(0-12),
  "grade": "우수/양호/개선 필요/부적절 중 하나",
  "improvements": ["{('이전 프롬프트와 비교하여 개선된 점들' if previous_prompt else '첫 프롬프트는 빈 배열')}"],
  "suggestions": ["FIRE 요소 기반 구체적 개선 제안1", "FIRE 요소 기반 구체적 개선 제안2", "추가 개선 방안"],
  "motivational_comment": "프롬프트 작성 학습 동기를 높이는 격려 메시지"
}}"""

        try:
            completion = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": evaluation_prompt}],
                temperature=0.1,
                max_tokens=1000
            )
            
            raw_content = completion.choices[0].message.content
            # JSON 코드 블록에서 실제 JSON 추출
            json_match = (raw_content.find("```json") != -1 and 
                         raw_content[raw_content.find("```json")+7:raw_content.find("```", raw_content.find("```json")+7)]) or raw_content
            
            if raw_content.find("```json") != -1:
                json_string = raw_content[raw_content.find("```json")+7:raw_content.find("```", raw_content.find("```json")+7)].strip()
            else:
                # JSON 객체 찾기
                start = raw_content.find("{")
                end = raw_content.rfind("}") + 1
                json_string = raw_content[start:end] if start != -1 and end != 0 else raw_content
            
            evaluation_result = json.loads(json_string)
            return evaluation_result
            
        except Exception as e:
            # 기본 평가 결과 반환
            return {
                "fire_scores": {
                    "focus": {"score": 1, "feedback": "목적이 더 명확해야 합니다."},
                    "input": {"score": 1, "feedback": "맥락 정보가 부족합니다."},
                    "rules": {"score": 1, "feedback": "형식이나 조건이 불분명합니다."},
                    "effect": {"score": 1, "feedback": "사용 목적이 구체적이지 않습니다."}
                },
                "total_score": 4,
                "grade": "개선 필요",
                "improvements": ["기본 평가가 수행되었습니다."],
                "suggestions": ["더 구체적인 프롬프트를 작성해보세요."],
                "motivational_comment": "계속 노력해보세요!"
            }