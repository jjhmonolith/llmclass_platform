# CloudFlare 터널 설정 가이드

## 현재 설정 상태
- **메인 터널**: `config-llmclass.yml` (정상 작동)
- **터널 ID**: b477ca04-c7fd-4617-8645-f4d357073d3c
- **모드**: Ingress 라우팅 (하나의 터널로 모든 서비스)

## 도메인 매핑
- `hub.llmclass.org` → localhost:8003 (Student Hub)
- `strategic.llmclass.org` → localhost:8001 (Proto1)
- `fire.llmclass.org` → localhost:8002 (Proto3)  
- `socratic.llmclass.org` → localhost:8000 (Proto4)

## 설정 파일 위치
- 활성 설정: `~/.cloudflared/config-llmclass.yml`
- 자격증명: `~/.cloudflared/b477ca04-c7fd-4617-8645-f4d357073d3c.json`

## 주의사항
1. **PPT Check 터널은 건드리지 말 것** (별도 운영)
2. 중복 터널 실행 금지 (로드밸런싱 문제 발생)
3. config.yml은 PPT Check 전용이므로 수정 금지