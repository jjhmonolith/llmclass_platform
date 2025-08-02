import os
from typing import List, Dict
from openai import OpenAI
from dotenv import load_dotenv
from .topic_service import topic_service

load_dotenv()

class OpenAIService:
    def __init__(self):
        self.client = OpenAI(
            api_key=os.getenv("OPENAI_API_KEY")
        )
    
    async def chat_completion(self, messages: List[Dict[str, str]], model: str = "gpt-4o-mini", topic: str = "일반적인 주제") -> str:
        try:
            # 주제에 맞는 시스템 프롬프트 가져오기
            system_prompt = await topic_service.get_topic_specific_ai_prompt(topic, messages)
            
            # 시스템 프롬프트를 메시지 앞에 추가
            enhanced_messages = [{"role": "system", "content": system_prompt}] + messages
            
            response = self.client.chat.completions.create(
                model=model,
                messages=enhanced_messages,
                max_tokens=1000,
                temperature=0.7
            )
            return response.choices[0].message.content
        except Exception as e:
            raise Exception(f"OpenAI API Error: {str(e)}")
    
    async def stream_chat_completion(self, messages: List[Dict[str, str]], model: str = "gpt-4o-mini"):
        try:
            stream = self.client.chat.completions.create(
                model=model,
                messages=messages,
                max_tokens=1000,
                temperature=0.7,
                stream=True
            )
            
            for chunk in stream:
                if chunk.choices[0].delta.content is not None:
                    yield chunk.choices[0].delta.content
                    
        except Exception as e:
            raise Exception(f"OpenAI Streaming API Error: {str(e)}")

openai_service = OpenAIService()