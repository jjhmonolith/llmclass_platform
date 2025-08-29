# 🔄 LLM Classroom 업데이트 가이드

## 📋 개요
현재 서비스를 사용 중인 사용자에게 영향을 최소화하면서 Proto4를 안전하게 업데이트하는 방법

## 🔍 사용자 활동 확인

### 1. 실시간 모니터링
```bash
# 현재 사용자 활동 확인
./check_user_activity.sh

# 5초마다 실시간 모니터링
watch -n 5 './check_user_activity.sh'
```

### 2. 확인 항목
- **네트워크 연결**: 현재 접속 중인 사용자 수
- **HTTP 활동**: 최근 5분간 API 요청
- **외부 접속**: Cloudflare를 통한 외부 접속 상태
- **리소스 사용량**: CPU/메모리 사용률

## 🛡️ 무중단 업데이트 전략

### 📊 업데이트 안전성 판단

| 상태 | 설명 | 권장 조치 |
|------|------|----------|
| 🟢 **안전** | 사용자 없음, 최근 활동 없음 | 즉시 업데이트 가능 |
| 🟡 **주의** | 1-2명 사용 중 | 사용자에게 알림 후 업데이트 |
| 🔴 **위험** | 3명 이상 또는 활발한 활동 | 오프피크 시간 대기 |

### ⏰ 권장 업데이트 시간
- **최적**: 새벽 2-6시 (한국 시간)
- **적절**: 오후 2-4시 (점심시간 이후)
- **피해야 할 시간**: 오전 9-12시, 오후 7-10시

## 🚀 업데이트 실행

### 1. 사전 확인
```bash
# 1. 사용자 활동 확인
./check_user_activity.sh

# 2. 현재 서비스 상태 확인
./check_services.sh

# 3. 백업 공간 확인
df -h
```

### 2. 업데이트 실행
```bash
# 대화형 업데이트 (권장)
./update_proto4.sh

# 강제 업데이트 (주의!)
./update_proto4.sh --force
```

### 3. 업데이트 과정
1. **사용자 활동 확인** - 현재 접속자 수 체크
2. **백업 생성** - 현재 버전 자동 백업
3. **서비스 중지** - Proto4만 일시 중지
4. **코드 업데이트** - GitHub에서 최신 버전 다운로드
5. **의존성 업데이트** - requirements.txt 기반 업데이트
6. **서비스 재시작** - 자동 재시작 및 헬스체크
7. **검증** - HTTP 응답 및 외부 접속 테스트

## ⚡ 무중단 업데이트 특징

### ✅ **장점**
- **빠른 복구**: 자동 롤백 시스템
- **최소 다운타임**: 보통 10-30초
- **안전한 백업**: 자동 백업 및 7일 보관
- **실시간 모니터링**: 업데이트 전/후 상태 확인

### ⚠️ **제한사항**
- **Proto4만 업데이트**: 다른 서비스는 영향 없음
- **데이터베이스 변경**: 스키마 변경시 별도 계획 필요
- **환경변수 변경**: .env 파일 변경시 수동 확인 필요

## 🆘 문제 해결

### 업데이트 실패시
```bash
# 로그 확인
tail -f logs/update_*.log

# 수동 롤백
cd /Users/jjh_server/llmclass_platform
mv proto4 proto4_failed
mv backups/proto4_[타임스탬프] proto4
./start_all_services.sh
```

### 서비스 시작 실패시
```bash
# 프로세스 확인
ps aux | grep proto4

# 포트 확인
lsof -i :8000

# 수동 시작
cd proto4/backend
python3 main.py
```

### 의존성 문제
```bash
# 의존성 재설치
cd proto4
pip install -r backend/requirements.txt --force-reinstall

# 가상환경 사용 (권장)
python3 -m venv venv
source venv/bin/activate
pip install -r backend/requirements.txt
```

## 📈 모니터링 및 검증

### 업데이트 후 확인 사항
1. **HTTP 응답**: http://localhost:8000
2. **외부 접속**: https://socratic.llmclass.org
3. **API 엔드포인트**: /health, /api/v1/chat/initial
4. **로그 확인**: 에러 없이 정상 시작
5. **리소스 사용량**: CPU/메모리 정상 범위

### 지속적 모니터링
```bash
# 실시간 로그 모니터링
tail -f logs/*.log

# 헬스체크 반복
watch -n 30 'curl -s http://localhost:8000/health'

# 사용자 활동 추적
watch -n 60 './check_user_activity.sh'
```

## 📚 추가 리소스

### 관련 파일
- `check_user_activity.sh` - 사용자 활동 모니터링
- `update_proto4.sh` - Proto4 업데이트 스크립트
- `check_services.sh` - 전체 서비스 상태 확인
- `logs/update_*.log` - 업데이트 로그

### 백업 관리
- **위치**: `/Users/jjh_server/llmclass_platform/backups/`
- **보관기간**: 7일 (자동 삭제)
- **명명규칙**: `proto4_YYYYMMDD_HHMMSS`

## 🎯 베스트 프랙티스

1. **정기 업데이트**: 매주 화요일 새벽 3시
2. **사전 알림**: 대시보드에 업데이트 공지
3. **점진적 배포**: 테스트 환경 → 프로덕션
4. **롤백 계획**: 항상 롤백 시나리오 준비
5. **문서화**: 모든 변경사항 기록