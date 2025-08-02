#!/usr/bin/env python3
"""
API 테스트 스크립트
"""
import requests
import json

BASE_URL = "http://localhost:8080"

def test_health():
    """헬스 체크 테스트"""
    print("🔍 헬스 체크 테스트...")
    try:
        response = requests.get(f"{BASE_URL}/api/health")
        print(f"상태: {response.status_code}")
        print(f"응답: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"오류: {e}")
        return False

def test_oneshot():
    """One-shot API 테스트"""
    print("\n🤖 One-shot API 테스트...")
    try:
        data = {
            "prompt": "안녕하세요! 간단한 인사말로 응답해주세요.",
            "temperature": 0.7,
            "maxTokens": 100
        }
        response = requests.post(f"{BASE_URL}/api/oneshot", json=data)
        print(f"상태: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"성공: {result.get('success')}")
            print(f"응답: {result.get('response', '응답 없음')[:100]}...")
            return True
        else:
            print(f"오류 응답: {response.text}")
            return False
    except Exception as e:
        print(f"오류: {e}")
        return False

def test_evaluate_prompt():
    """프롬프트 평가 API 테스트"""
    print("\n📊 프롬프트 평가 API 테스트...")
    try:
        data = {
            "currentPrompt": "환경 문제에 대해 설명해주세요",
            "learningObjective": "환경 문제에 대한 2페이지 보고서를 작성하세요",
            "settings": {
                "topic": "환경 문제",
                "difficulty": "중급",
                "schoolLevel": "중학생"
            }
        }
        response = requests.post(f"{BASE_URL}/api/evaluate-prompt", json=data)
        print(f"상태: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"성공: {result.get('success')}")
            evaluation = result.get('evaluation', {})
            rtcf_scores = evaluation.get('rtcf_scores', {})
            print(f"RTCF 점수:")
            for key, value in rtcf_scores.items():
                if isinstance(value, dict) and 'score' in value:
                    print(f"  {key}: {value['score']}/5")
            return True
        else:
            print(f"오류 응답: {response.text}")
            return False
    except Exception as e:
        print(f"오류: {e}")
        return False

def main():
    print("🚀 LLM Classroom Proto3 API 테스트 시작")
    print("=" * 50)
    
    # 테스트 실행
    tests = [
        ("헬스 체크", test_health),
        ("One-shot API", test_oneshot),
        ("프롬프트 평가 API", test_evaluate_prompt)
    ]
    
    results = []
    for name, test_func in tests:
        success = test_func()
        results.append((name, success))
    
    # 결과 요약
    print("\n" + "=" * 50)
    print("📊 테스트 결과 요약")
    print("=" * 50)
    
    for name, success in results:
        status = "✅ 성공" if success else "❌ 실패"
        print(f"{status} {name}")
    
    success_count = sum(1 for _, success in results if success)
    total_count = len(results)
    print(f"\n총 {total_count}개 중 {success_count}개 성공")
    
    if success_count == total_count:
        print("🎉 모든 테스트가 성공했습니다!")
    else:
        print("⚠️  일부 테스트가 실패했습니다.")

if __name__ == "__main__":
    main()