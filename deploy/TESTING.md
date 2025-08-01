# 로컬 Docker 환경 테스트 가이드

## 🚀 빠른 시작

### 1. 전제 조건
- Docker Desktop이 설치되어 있고 실행 중이어야 합니다
- `curl` 명령어가 사용 가능해야 합니다 (macOS 기본 제공)

### 2. 환경 시작
```bash
cd deploy

# 첫 실행 (이미지 빌드 포함)
./test-local.sh --build

# 일반 실행
./test-local.sh

# 완전 정리 후 재시작
./test-local.sh --cleanup --build
```

### 3. 접근 확인
테스트가 성공하면 다음 URL로 접근 가능:
- **메인 대시보드**: http://localhost:8080/
- **헬스체크**: http://localhost:8080/healthz
- **API 버전**: http://localhost:8080/api/version
- **개발자 도구**: http://localhost:8080/dev.html

---

## 📋 수동 테스트 단계

### 1. Docker 실행 확인
```bash
docker info
```

### 2. 환경 설정 검증
```bash
./env-check.sh dev
```

### 3. Docker 이미지 빌드
```bash
docker compose --env-file .env.dev -f docker-compose.yml build
```

### 4. 서비스 시작
```bash
docker compose --env-file .env.dev -f docker-compose.yml up -d
```

### 5. 서비스 상태 확인
```bash
docker compose --env-file .env.dev -f docker-compose.yml ps
```

### 6. 엔드포인트 테스트
```bash
# 헬스체크 (백엔드 직접)
curl http://localhost:8000/healthz

# 헬스체크 (프록시 경유)
curl http://localhost:8080/healthz

# API 버전 정보
curl http://localhost:8080/api/version

# 에코 테스트 (개발 모드)
curl http://localhost:8080/api/echo

# 메인 페이지
curl -I http://localhost:8080/
```

---

## 🔧 트러블슈팅

### Docker 관련 문제

#### 1. "Docker daemon is not running"
```bash
# macOS에서 Docker Desktop 시작
open -a Docker

# 또는 Applications에서 Docker Desktop 실행
```

#### 2. 포트 충돌 (8080, 8000, 5432)
```bash
# 사용 중인 포트 확인
lsof -i :8080
lsof -i :8000
lsof -i :5432

# 해당 프로세스 종료 후 재시도
```

#### 3. 이미지 빌드 실패
```bash
# 빌드 로그 확인
docker compose --env-file .env.dev -f docker-compose.yml build --no-cache

# 개별 서비스 빌드 로그
docker compose --env-file .env.dev -f docker-compose.yml logs backend
```

### 서비스 시작 문제

#### 1. 백엔드가 시작되지 않음
```bash
# 백엔드 로그 확인
docker compose --env-file .env.dev -f docker-compose.yml logs backend

# 컨테이너 내부 접속
docker compose --env-file .env.dev -f docker-compose.yml exec backend /bin/bash
```

#### 2. 데이터베이스 연결 실패
```bash
# DB 로그 확인
docker compose --env-file .env.dev -f docker-compose.yml logs db

# DB 연결 테스트
docker compose --env-file .env.dev -f docker-compose.yml exec db psql -U appuser -d appdb_dev -c "SELECT 1;"
```

#### 3. Nginx 설정 오류
```bash
# Nginx 로그 확인
docker compose --env-file .env.dev -f docker-compose.yml logs proxy

# 설정 문법 검사 (Docker 실행 시)
docker run --rm -v "$(pwd)/nginx:/etc/nginx/conf.d:ro" nginx:1.25-alpine nginx -t -c /etc/nginx/conf.d/nginx.conf
```

### 네트워크 및 접근 문제

#### 1. 헬스체크 실패
```bash
# 백엔드 직접 접근 테스트
curl -v http://localhost:8000/healthz

# 프록시 경유 테스트
curl -v http://localhost:8080/healthz

# DNS 해결 확인
nslookup localhost
```

#### 2. 정적 파일 서빙 실패
```bash
# 파일 존재 확인
ls -la ../frontend/public/

# Nginx 컨테이너 내부 파일 확인
docker compose --env-file .env.dev -f docker-compose.yml exec proxy ls -la /usr/share/nginx/html/
```

---

## 📊 로그 모니터링

### 실시간 로그 확인
```bash
# 모든 서비스 로그
docker compose --env-file .env.dev -f docker-compose.yml logs -f

# 특정 서비스 로그
docker compose --env-file .env.dev -f docker-compose.yml logs -f backend
docker compose --env-file .env.dev -f docker-compose.yml logs -f proxy
docker compose --env-file .env.dev -f docker-compose.yml logs -f db
```

### 리소스 사용량 확인
```bash
# 컨테이너 리소스 사용량
docker stats

# 디스크 사용량
docker system df
```

---

## 🧹 정리 작업

### 서비스 정지
```bash
# 컨테이너만 정지
docker compose --env-file .env.dev -f docker-compose.yml down

# 볼륨까지 삭제
docker compose --env-file .env.dev -f docker-compose.yml down -v
```

### 시스템 정리
```bash
# 사용하지 않는 리소스 정리
docker system prune -f

# 볼륨 정리
docker volume prune -f

# 네트워크 정리
docker network prune -f
```

---

## ✅ 성공 기준

다음 모든 항목이 통과하면 성공:

1. **서비스 시작**: 모든 컨테이너가 `Up` 상태
2. **헬스체크**: `/healthz`에서 `{"status":"ok", "database":"ok"}` 응답
3. **API 접근**: `/api/version`에서 버전 정보 응답
4. **정적 파일**: `/`에서 HTML 페이지 로드
5. **에러 처리**: `/nonexistent`에서 404 페이지 표시
6. **데이터베이스**: PostgreSQL 연결 정상

---

## 🔗 다음 단계

로컬 테스트가 성공하면:
1. Cloudflare Tunnel 설정
2. 외부 도메인 연결
3. 운영 환경 배포

문제가 있으면 위 트러블슈팅 가이드를 참조하거나 로그를 확인하세요.