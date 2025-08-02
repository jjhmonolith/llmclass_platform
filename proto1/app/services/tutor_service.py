import os
from typing import List, Dict
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

class TutorService:
    def __init__(self):
        self.client = OpenAI(
            api_key=os.getenv("OPENAI_API_KEY")
        )
        self.system_prompt = """당신은 중학교 수준의 학생들이 AI와 더 효과적으로 대화하며 주어진 주제에 대한 프로젝트를 설계하도록 돕는 교육 튜터입니다.

        **대상 학습자**: 중학교 1-3학년 학생 (만 13-15세)
        **당신의 역할**: 학생의 질문/메시지를 분석하여 더 나은 질문을 할 수 있도록 코칭하는 것입니다.
        
        **핵심 임무 - 주제 집중도 관리**:
        먼저 학생의 메시지가 주어진 학습 주제와 관련이 있는지 확인하세요.
        
        **주제 이탈 감지 및 대응**:
        - 학생의 메시지가 학습 주제에서 크게 벗어났다면 부드럽게 주제로 돌려보내세요
        - "흥미로운 질문이네요! 하지만 오늘은 '{주제}'에 대해 집중해서 탐구해볼까요?"
        - "그 내용도 재미있지만, '{주제}' 관련해서 더 깊이 알아보는 건 어떨까요?"
        - 완전히 차단하지 말고, 주제와 연결할 수 있는 부분이 있다면 연결해주세요
        
        **학생의 메시지를 다음 관점에서 분석하세요**:
        
        0. **주제 관련성**: 학생의 질문/메시지가 주어진 학습 주제와 관련이 있는가?
        1. **질문의 명확성**: 학생의 질문이 구체적이고 명확한가? 모호한 부분은 없는가?
        2. **문맥 제공**: 충분한 배경 정보와 맥락을 제공했는가?
        3. **목표 설정**: 무엇을 알고 싶어하는지, 해결하려는 문제가 분명한가?
        4. **구조화**: 복잡한 문제를 작은 단위로 나누어 질문했는가?
        5. **후속 질문**: AI의 답변을 바탕으로 더 깊이 있는 후속 질문을 할 수 있는가?
        
        **피드백 형식을 정확히 지켜주세요**:
        
        **잘한 점**: 학생이 잘한 부분을 구체적으로 칭찬하는 1-2문장 (주제 이탈시에도 긍정적 요소 찾기)
        
        **개선할 점**: 어떻게 질문을 개선할 수 있는지 구체적 제안 (주제 이탈시 주제로 돌아가는 방법 포함) 1-2문장
        
        **다음 단계**: 주어진 주제에 대한 구체적이고 실행 가능한 다음 단계 (항상 주제 중심으로) 1-2문장
        
        **추천 질문**: (항상 주어진 학습 주제와 관련된 질문들만)
        1. 첫 번째 추천 질문
        2. 두 번째 추천 질문
        3. 세 번째 추천 질문
        
        **중요사항**:
        - 중학생 수준에 맞는 쉬운 언어와 표현을 사용하세요
        - AI의 답변이 아닌 학생의 질문 방식과 커뮤니케이션 스킬에 집중하세요
        - 격려와 동기부여를 포함하여 긍정적인 학습 환경을 조성하세요
        - 주제에서 벗어났을 때 비판적이지 않고 친근하게 가이드하세요
        - 주제 이탈을 감지했을 때는 반드시 주제 관련 질문만 추천하세요"""
    
    async def analyze_conversation(self, messages: List[Dict[str, str]], 
                                 last_user_message: str, 
                                 ai_response: str, 
                                 topic: str = "일반적인 주제") -> Dict[str, any]:
        try:
            # 대화 맥락 구성
            context = "이전 대화 내용:\n"
            for msg in messages[-5:]:  # 최근 5개 메시지만 포함
                context += f"{msg['role']}: {msg['content']}\n"
            
            analysis_prompt = f"""
            **학습 주제**: {topic}
            
            대화 맥락:
            {context}
            
            **분석할 학생의 메시지**: {last_user_message}
            
            (참고: AI가 다음과 같이 응답했습니다: {ai_response})
            
            **중요**: 먼저 학생의 메시지가 '{topic}' 주제와 관련이 있는지 확인하세요.
            
            **만약 주제에서 벗어났다면**:
            - 개선할 점에서 부드럽게 주제로 돌아가자고 제안하세요
            - 다음 단계와 추천 질문은 반드시 '{topic}' 관련 내용만 제시하세요
            
            위 중학생의 메시지를 분석하여:
            1. 학생이 질문을 어떻게 했는지 평가하고
            2. 더 효과적으로 AI를 활용할 수 있는 질문 방법을 제안하며 (주제 이탈시 주제로 돌아가는 가이드 포함)
            3. '{topic}' 주제와 관련된 다음 단계의 방향성을 제시해주세요.
            
            중학생 수준에 맞는 언어로 학생의 질문 스킬과 사고 과정에 초점을 맞춰 피드백을 제공하세요.
            """
            
            response = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": self.system_prompt},
                    {"role": "user", "content": analysis_prompt}
                ],
                max_tokens=800,
                temperature=0.7
            )
            
            feedback = response.choices[0].message.content
            
            # 피드백을 구조화된 형태로 파싱
            return self._parse_feedback(feedback)
            
        except Exception as e:
            return {
                "strengths": "좋은 질문을 했어요! 👍",
                "improvements": "더 구체적으로 설명해보면 어떨까요?",
                "next_steps": "이 주제에 대해 더 탐구해보세요!",
                "suggested_questions": ["이 주제에서 가장 궁금한 점이 무엇인가요?"],
                "error": str(e),
                "raw_feedback": f"오류가 발생했습니다: {str(e)}"
            }
    
    def _parse_feedback(self, feedback_text: str) -> Dict[str, any]:
        """피드백 텍스트를 구조화된 딕셔너리로 변환"""
        import re
        
        result = {
            "strengths": "",
            "improvements": "",
            "next_steps": "",
            "suggested_questions": [],
            "raw_feedback": feedback_text
        }
        
        # 더 강건한 파싱을 위해 정규식 사용
        text = feedback_text.strip()
        
        # 각 섹션 추출
        sections = {
            "strengths": r"(\*\*잘한 점\*\*|잘한 점)[:：]?\s*(.*?)(?=\*\*개선할 점\*\*|개선할 점|다음 단계|\*\*다음 단계\*\*|추천 질문|\*\*추천 질문\*\*|$)",
            "improvements": r"(\*\*개선할 점\*\*|개선할 점)[:：]?\s*(.*?)(?=\*\*다음 단계\*\*|다음 단계|추천 질문|\*\*추천 질문\*\*|$)",
            "next_steps": r"(\*\*다음 단계\*\*|다음 단계)[:：]?\s*(.*?)(?=추천 질문|\*\*추천 질문\*\*|$)",
            "questions": r"(\*\*추천 질문\*\*|추천 질문)[:：]?\s*(.*?)$"
        }
        
        for key, pattern in sections.items():
            match = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
            if match and match.group(2):
                content = match.group(2).strip()
                
                if key == "questions":
                    # 질문 파싱: 번호나 대시로 시작하는 라인들을 찾음
                    questions = []
                    for line in content.split('\n'):
                        line = line.strip()
                        if not line:
                            continue
                        # 번호나 대시 제거
                        if re.match(r'^[\d\-\•]\.\s*', line):
                            question = re.sub(r'^[\d\-\•]\.\s*', '', line)
                            questions.append(question.strip())
                        elif re.match(r'^[\-\•]\s*', line):
                            question = re.sub(r'^[\-\•]\s*', '', line)
                            questions.append(question.strip())
                        elif line and not any(x in line.lower() for x in ['잘한 점', '개선할 점', '다음 단계']):
                            questions.append(line)
                    
                    # 빈 질문이나 너무 짧은 질문 제거
                    result["suggested_questions"] = [q for q in questions if len(q) > 3][:3]
                else:
                    # 텍스트에서 불필요한 마크다운 제거
                    content = re.sub(r'\*\*([^*]+)\*\*', r'\1', content)
                    content = re.sub(r'[\-\•]\s*', '', content)
                    content = ' '.join(content.split())  # 여러 공백을 하나로
                    result[key] = content
        
        # 빈 필드에 대한 기본값 설정
        if not result["strengths"]:
            result["strengths"] = "좋은 질문을 했어요!"
        
        if not result["improvements"]:
            result["improvements"] = "더 구체적으로 설명해보면 어떨까요?"
            
        if not result["next_steps"]:
            result["next_steps"] = "이 주제에 대해 더 탐구해보세요!"
            
        if not result["suggested_questions"]:
            result["suggested_questions"] = ["이 주제에서 가장 궁금한 점이 무엇인가요?"]
        
        return result

tutor_service = TutorService()