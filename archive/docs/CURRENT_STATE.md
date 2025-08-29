# 📊 LLM Classroom 현재 상태 문서
## 생성일: 2025-08-25

## 🔧 현재 구성
### 서비스 포트 매핑
- **Proto1 (Strategic Learning)**: 포트 8001 → strategic.llmclass.org
- **Proto3 (FIRE Prompt)**: 포트 8002 → fire.llmclass.org  
- **Proto4 (Socratic Learning)**: 포트 8000 → socratic.llmclass.org
- **Student Hub (메인 허브)**: 포트 8003 → hub.llmclass.org
- **PPT Check**: 포트 3333 (별도 서비스, 유지 필요)

### CloudFlare 터널 설정
- **메인 터널 ID**: b477ca04-c7fd-4617-8645-f4d357073d3c
- **설정 파일**: ~/.cloudflared/config-llmclass.yml
- **Ingress 규칙**: 하나의 터널로 모든 서비스 라우팅

### 디버깅 이슈 해결 내역
1. ✅ 중복 터널 프로세스 제거 (로드밸런싱 문제 해결)
2. ✅ fire와 strategic 도메인 매핑 수정
3. ✅ Proto4 CSS 경로 절대경로로 수정 (?v=2 버전 추가)
4. ✅ LaunchAgent 중복 실행 방지

### 실행 중인 프로세스
- Python 프로세스: proto1, proto3, proto4, hub
- CloudFlare 터널: config-llmclass.yml (단일)
- PPT Check: pptcheck-local (별도)