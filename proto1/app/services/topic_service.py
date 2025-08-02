import os
from typing import Dict, Any
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

class TopicService:
    def __init__(self):
        self.client = OpenAI(
            api_key=os.getenv("OPENAI_API_KEY")
        )
    
    def get_initial_message(self, topic: str) -> str:
        """주제에 맞는 초기 인사 메시지 생성 (간단한 인사만)"""
        topic_greetings = {
            "사회 문제해결": f"안녕! 👋 나는 '{topic}' 탐험을 함께할 AI 친구야! 🌍",
            "과학 탐구": f"와! 🔬 '{topic}' 선택했네! 과학자가 되어볼 준비됐어? ⚡",
            "역사 연구": f"오늘은 시간여행자가 되어볼까? 📜✨ '{topic}' 모험 시작!",
            "문학 창작": f"글쓰기 마법사 등장! ✍️✨ '{topic}' 세계로 출발~",
            "기술과 미래": f"미래에서 온 AI야! 🚀 '{topic}' 탐험 준비됐어?",
            "예술과 문화": f"예술가의 영혼을 깨워보자! 🎨 '{topic}' 창작 여행 시작!"
        }
        
        # 기본 인사 (커스텀 주제의 경우)
        default_greeting = f"헤이! 👋 '{topic}' 탐험가가 되어볼까? 🚀"
        
        greeting = topic_greetings.get(topic, default_greeting)
        
        message = f"""{greeting}

무엇이든 궁금한 걸 물어봐! 함께 탐구해보자! 😄"""
        
        return message
    
    async def get_initial_tutor_guide(self, topic: str) -> Dict[str, Any]:
        """주제에 맞는 초기 튜터 가이드 생성"""
        topic_guides = {
            "사회 문제해결": {
                "guide_title": "🎯 질문 시작 가이드",
                "guide_content": "우리 주변의 불편함이나 문제를 찾아 해결책을 만들어보는 프로젝트예요!\n\n💡 이렇게 시작해보세요:\n• 일상에서 겪는 불편함을 떠올려보기\n• '왜 이런 문제가 생길까?' 원인 파악하기\n• '어떻게 하면 나아질까?' 해결 방법 상상하기",
                "starter_questions": [
                    "학교에서 급식 줄이 너무 길어서 불편해요. 어떻게 해결할 수 있을까요?",
                    "우리 동네 횡단보도가 위험해 보이는데, 더 안전하게 만들 방법이 있을까요?",
                    "플라스틱 쓰레기를 줄이고 싶은데, 중학생이 할 수 있는 방법은 뭐가 있을까요?"
                ]
            },
            "과학 탐구": {
                "guide_title": "🔬 질문 시작 가이드",
                "guide_content": "일상 속 신기한 현상을 과학적으로 탐구해보는 프로젝트예요!\n\n💡 이렇게 시작해보세요:\n• 평소 '왜 그럴까?' 궁금했던 것 떠올리기\n• 현상을 자세히 관찰하고 기록하기\n• 가설을 세우고 실험 방법 생각하기",
                "starter_questions": [
                    "비 오는 날은 왜 하늘이 어두워 보일까요?",
                    "아이스크림은 왜 냉동실에서도 부드러울까요?",
                    "식물은 어떻게 중력을 거슬러 물을 위로 올릴까요?"
                ]
            },
            "역사 연구": {
                "guide_title": "📜 질문 시작 가이드",
                "guide_content": "과거를 탐구하며 현재를 이해하는 프로젝트예요!\n\n💡 이렇게 시작해보세요:\n• 관심 있는 역사적 사건이나 인물 선택하기\n• '만약 ~했다면?' 상상해보기\n• 과거와 현재의 연결점 찾아보기",
                "starter_questions": [
                    "조선시대 학생들은 어떻게 공부했을까요?",
                    "세종대왕이 한글을 만들지 않았다면 지금 우리는 어떤 글자를 쓰고 있을까요?",
                    "옛날 사람들은 스마트폰 없이 어떻게 소통했을까요?"
                ]
            },
            "문학 창작": {
                "guide_title": "✍️ 질문 시작 가이드",
                "guide_content": "상상력을 발휘해 나만의 이야기를 만드는 프로젝트예요!\n\n💡 이렇게 시작해보세요:\n• 좋아하는 이야기 장르 정하기\n• 매력적인 캐릭터 만들기\n• '만약에...' 로 시작하는 상황 상상하기",
                "starter_questions": [
                    "평범한 중학생이 갑자기 초능력을 얻는다면 어떤 이야기가 될까요?",
                    "우리 학교에 비밀 통로가 있다면 어디로 이어질까요?",
                    "미래에서 온 친구를 만난다면 어떤 대화를 나눌까요?"
                ]
            },
            "기술과 미래": {
                "guide_title": "🚀 질문 시작 가이드",
                "guide_content": "미래 기술을 상상하고 설계해보는 프로젝트예요!\n\n💡 이렇게 시작해보세요:\n• 불편한 점을 해결할 미래 기술 상상하기\n• 현재 기술의 한계와 가능성 탐구하기\n• 기술이 바꿀 미래 모습 그려보기",
                "starter_questions": [
                    "숙제를 도와주는 AI 로봇을 만든다면 어떤 기능이 필요할까요?",
                    "미래의 학교는 어떤 모습일까요? VR로 수업을 할까요?",
                    "날아다니는 자동차가 생긴다면 도시는 어떻게 바뀔까요?"
                ]
            },
            "예술과 문화": {
                "guide_title": "🎨 질문 시작 가이드",
                "guide_content": "예술 작품을 감상하고 창작해보는 프로젝트예요!\n\n💡 이렇게 시작해보세요:\n• 좋아하는 예술 작품이나 아티스트 찾기\n• 작품이 주는 느낌과 의미 생각하기\n• 나만의 방식으로 표현해보기",
                "starter_questions": [
                    "우리 학교를 주제로 한 노래를 만든다면 어떤 가사를 쓸까요?",
                    "내 감정을 색깔로 표현한다면 어떤 그림이 될까요?",
                    "K-POP이 세계적으로 인기 있는 이유는 뭘까요?"
                ]
            }
        }
        
        # 기본 가이드 (커스텀 주제의 경우)
        default_guide = {
            "guide_title": "🎯 질문 시작 가이드",
            "guide_content": f"'{topic}'에 대해 자유롭게 탐구해보는 프로젝트예요!\n\n💡 이렇게 시작해보세요:\n• 가장 궁금한 점부터 시작하기\n• '왜?', '어떻게?', '만약에?' 질문하기\n• 다양한 관점에서 생각해보기",
            "starter_questions": [
                f"{topic}에서 가장 흥미로운 부분은 무엇인가요?",
                f"{topic}을(를) 더 재미있게 만들 수 있는 방법이 있을까요?",
                f"{topic}과(와) 관련해서 미래에는 어떤 변화가 있을까요?"
            ]
        }
        
        # 기본 템플릿 사용하되, AI로 개인화된 가이드 생성
        base_guide = topic_guides.get(topic, default_guide)
        
        # AI를 통해 더 개인화된 가이드 생성
        try:
            enhanced_guide = await self._generate_personalized_guide(topic, base_guide)
            return enhanced_guide
        except Exception as e:
            # AI 생성 실패 시 기본 가이드 반환
            return base_guide
    
    async def _generate_personalized_guide(self, topic: str, base_guide: Dict[str, Any]) -> Dict[str, Any]:
        """AI를 통해 개인화된 튜터 가이드 생성"""
        prompt = f"""당신은 중학생들의 '{topic}' 학습을 도와주는 창의적인 교육 전문가입니다.

**상황**: 중학생이 '{topic}' 주제로 LLM Classroom에서 AI와 대화하며 프로젝트를 수행합니다. 학생이 AI에게 어떻게 질문해야 할지 도움이 필요합니다.

**목표**: 중학생이 AI에게 '{topic}'에 대해 효과적으로 질문하여 깊이 있는 답변을 얻을 수 있도록 도움을 주세요.

**요구사항**:
1. 중학생 수준에 맞는 친근하고 쉬운 언어
2. '{topic}'에 대한 흥미로운 접근 방법 제시  
3. **시작 질문들은 학생이 AI에게 직접 할 수 있는 구체적인 질문이어야 합니다**
4. 실생활과 연결된 흥미로운 내용

**응답 형식** (정확히 이 형식을 지켜주세요):

**가이드 내용**: {topic}에 대한 간단한 소개와 AI와 대화하며 탐구하면 좋은 이유 (2-3문장)

---시작질문구분선---

**시작 질문 1**: {topic}에 대해 AI에게 할 수 있는 구체적이고 흥미로운 질문 (예: '설명해주세요', '예시를 들어주세요', '어떻게 할 수 있을까요' 등의 형태)
**시작 질문 2**: {topic}에 대해 AI에게 할 수 있는 구체적이고 흥미로운 질문
**시작 질문 3**: {topic}에 대해 AI에게 할 수 있는 구체적이고 흥미로운 질문

중학생이 AI와 효과적으로 대화하며 '{topic}'를 탐구할 수 있도록 도와주세요."""
        
        try:
            response = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "user", "content": prompt}
                ],
                max_tokens=800,
                temperature=0.8
            )
            
            ai_response = response.choices[0].message.content
            
            # AI 응답 파싱
            return self._parse_ai_guide(ai_response, topic)
            
        except Exception as e:
            raise Exception(f"AI guide generation failed: {str(e)}")
    
    def _parse_ai_guide(self, ai_response: str, topic: str) -> Dict[str, Any]:
        """AI 응답을 구조화된 가이드로 파싱"""
        import re
        
        result = {
            "guide_title": f"🎯 {topic} 탐구 가이드",
            "guide_content": "",
            "starter_questions": []
        }
        
        try:
            # 시작 질문 부분을 제거한 AI 응답 정리
            # 구분선 전까지의 내용만 사용
            if '---시작질문구분선---' in ai_response:
                cleaned_response = ai_response.split('---시작질문구분선---')[0]
            else:
                cleaned_response = re.sub(r'\*\*시작 질문.*?(?=\n\n|이러한 질문|이상입니다|$)', '', ai_response, flags=re.DOTALL)
            
            # 가이드 내용 추출
            guide_match = re.search(r'\*\*가이드 내용\*\*:?\s*(.*?)(?=\*\*탐구 방법\*\*|\*\*AI 질문 팁\*\*|$)', cleaned_response, re.DOTALL)
            if guide_match:
                result["guide_content"] = guide_match.group(1).strip()
            else:
                # 가이드 내용이 명시적으로 없다면 첫 부분 사용
                first_part = cleaned_response.split('\n\n')[0]
                result["guide_content"] = first_part.strip()
            
            # AI 질문 팁 부분은 제거 (중복 방지)
            
            # 시작 질문들 추출 - 구분선 이후 부분에서만
            questions = []
            
            # 구분선 이후 부분 추출
            if '---시작질문구분선---' in ai_response:
                question_part = ai_response.split('---시작질문구분선---')[1]
            else:
                question_part = ai_response
            
            # 방법1: **시작 질문 1**, **시작 질문 2** 형태
            for i in range(1, 4):
                patterns = [
                    f'\*\*시작 질문 {i}\*\*:?\s*(.*?)(?=\*\*시작 질문|\*\*|$)',
                    f'시작 질문 {i}:?\s*(.*?)(?=시작 질문|$)',
                    f'{i}\.\s+(.*?)(?=\d+\.|$)'
                ]
                
                for pattern in patterns:
                    question_match = re.search(pattern, question_part, re.DOTALL | re.MULTILINE)
                    if question_match:
                        question = question_match.group(1).strip()
                        # 줄바꿈과 여백 정리
                        question = re.sub(r'\n+', ' ', question)
                        question = re.sub(r'\s+', ' ', question)
                        # 불필요한 설명 단어 제거
                        question = re.sub(r'\(예:.*?\)', '', question)
                        question = question.replace('예를 들어', '').strip()
                        if len(question) > 10:  # 유의미한 질문인 경우만
                            questions.append(question)
                            break
            
            # 백업 질문들이 충분하지 않으면 기본 질문 추가
            if len(questions) < 3:
                backup_questions = [
                    f"{topic}에 대해 간단히 설명해주세요. 중학생이 이해하기 쉬운 예시도 포함해주세요.",
                    f"{topic}에서 가장 흥미로운 부분을 3가지 알려주세요. 왜 그것이 중요한지도 설명해주세요.",
                    f"{topic}과 관련된 실생활 예시를 들어주세요. 어떻게 활용할 수 있는지도 알려주세요."
                ]
                # 부족한 만큼 추가
                for i in range(len(questions), 3):
                    if i < len(backup_questions):
                        questions.append(backup_questions[i])
            
            if questions:
                result["starter_questions"] = questions[:3]  # 최대 3개
            else:
                # 백업 질문들
                result["starter_questions"] = [
                    f"{topic}에 대해 간단히 설명해주세요. 중학생이 이해하기 쉬운 예시도 포함해주세요.",
                    f"{topic}에서 가장 흥미로운 부분을 3가지 알려주세요. 왜 그것이 중요한지도 설명해주세요.",
                    f"{topic}과 관련된 실생활 예시를 들어주세요. 어떻게 활용할 수 있는지도 알려주세요."
                ]
            
        except Exception as e:
            # 파싱 실패 시 기본 내용 설정
            result["guide_content"] = f"{topic}에 대해 자유롭게 탐구해보는 시간입니다!\n\n💡 궁금한 점을 자유롭게 질문해보세요:"
            result["starter_questions"] = [
                f"{topic}에 대해 간단히 설명해주세요. 중학생이 이해하기 쉬운 예시도 포함해주세요.",
                f"{topic}에서 가장 흥미로운 부분을 3가지 알려주세요. 왜 그것이 중요한지도 설명해주세요.",
                f"{topic}과 관련된 실생활 예시를 들어주세요. 어떻게 활용할 수 있는지도 알려주세요."
            ]
        
        return result

    async def get_topic_specific_ai_prompt(self, topic: str, messages: list) -> str:
        """주제에 맞는 AI 시스템 프롬프트 생성"""
        base_prompt = f"""당신은 중학생들의 '{topic}' 학습을 도와주는 친근한 AI 튜터입니다.

**학습자 정보**: 중학교 1-3학년 (만 13-15세)
**학습 주제**: {topic}

**역할과 목표**:
- 학생이 {topic}에 대해 깊이 있게 탐구할 수 있도록 도움
- 중학생 수준에 맞는 쉬운 설명과 예시 제공
- 학생의 호기심을 자극하고 스스로 생각할 수 있도록 유도
- 격려와 칭찬을 통해 긍정적인 학습 분위기 조성

**대화 스타일**:
- 친근하고 격려하는 어조 사용
- 복잡한 개념은 쉬운 말로 설명
- 학생의 관심사와 경험을 연결하여 설명
- 적절한 질문을 통해 학생의 사고를 확장

**중요한 주제 관리 규칙**:
- 학생이 '{topic}'과 관련 없는 질문을 하면 부드럽게 주제로 돌려보내세요
- 예: "재미있는 질문이네요! 하지만 오늘은 '{topic}'에 대해 더 깊이 알아볼까요?"
- 예: "그 내용도 흥미로워요. 그런데 '{topic}'와 연결해서 생각해보면 어떨까요?"
- 완전히 차단하지 말고, 가능하다면 '{topic}'와 연결점을 찾아 설명해주세요
- 학생이 계속 다른 주제로 가려고 하면 "오늘 수업 주제는 '{topic}'이에요. 이 주제에 집중해서 멋진 프로젝트를 만들어봐요!"라고 안내하세요

**주의사항**:
- 답을 직접 제공하기보다는 학생이 스스로 찾을 수 있도록 힌트 제공
- 학생의 답변에 대해 항상 긍정적으로 반응
- 어려운 용어 사용 시 반드시 설명 추가
- 주제에서 벗어난 질문에도 비판적이지 않고 친근하게 대응"""

        return base_prompt

topic_service = TopicService()