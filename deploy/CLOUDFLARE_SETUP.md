# Cloudflare Tunnel 설정 가이드

## 📖 개요

Cloudflare Tunnel을 사용하여 로컬에서 실행 중인 서비스를 외부 도메인으로 안전하게 노출할 수 있습니다.

- ✅ **보안**: NAT/방화벽 설정 불필요, 인바운드 포트 열지 않음
- ✅ **안정성**: Cloudflare의 글로벌 네트워크 사용
- ✅ **간편성**: DNS 설정 자동화
- ✅ **무료**: Cloudflare 계정만 있으면 사용 가능

---

## 🚀 빠른 설정 (자동 스크립트)

### 1. 전제 조건
- Cloudflare 계정 보유
- 도메인이 Cloudflare에 등록되어 있음
- 로컬 서비스가 포트 8080에서 실행 중

### 2. 자동 설정 실행
```bash
cd deploy/cloudflared
./setup-tunnel.sh
```

이 스크립트는 다음을 자동으로 수행합니다:
1. Cloudflare 인증
2. 터널 생성
3. DNS 라우팅 설정
4. 설정 파일 생성
5. 터널 테스트

---

## 🔧 수동 설정 (단계별)

### 1. cloudflared 설치

**macOS (Homebrew):**
```bash
brew install cloudflared
```

**직접 다운로드:**
https://github.com/cloudflare/cloudflared/releases

### 2. Cloudflare 인증
```bash
cloudflared tunnel login
```
- 브라우저가 열리면 Cloudflare에 로그인
- 사용할 도메인 선택

### 3. 터널 생성
```bash
# 터널 생성
cloudflared tunnel create llmclass-platform

# 출력에서 터널 ID 기록 (예: 12345678-1234-1234-1234-123456789abc)
```

### 4. DNS 라우팅 설정
```bash
# 도메인을 터널에 연결
cloudflared tunnel route dns llmclass-platform platform.llmclass.org
```

### 5. 설정 파일 생성
```bash
# tunnel.yml 파일 생성
cp tunnel.yml.example tunnel.yml
# 파일을 편집하여 TUNNEL_ID와 도메인 업데이트
```

### 6. 터널 실행
```bash
# 로컬 서비스가 8080 포트에서 실행 중인지 확인
make up ENV=dev

# 터널 시작
cloudflared tunnel --config tunnel.yml run
```

---

## 🔄 자동 시작 설정 (macOS)

### 1. launchd 설정
```bash
# 로그 디렉토리 생성
mkdir -p ../logs

# launchd 설정 파일 복사 및 편집
cp launchd.plist.example ~/Library/LaunchAgents/com.cloudflare.cloudflared.llmclass.plist

# 파일 편집 (YOUR_USERNAME을 실제 사용자명으로 변경)
nano ~/Library/LaunchAgents/com.cloudflare.cloudflared.llmclass.plist
```

### 2. 서비스 등록 및 시작
```bash
# 서비스 로드
launchctl load ~/Library/LaunchAgents/com.cloudflare.cloudflared.llmclass.plist

# 서비스 시작
launchctl start com.cloudflare.cloudflared.llmclass

# 상태 확인
launchctl list | grep cloudflared
```

### 3. 서비스 관리
```bash
# 중지
launchctl stop com.cloudflare.cloudflared.llmclass

# 재시작
launchctl start com.cloudflare.cloudflared.llmclass

# 제거
launchctl unload ~/Library/LaunchAgents/com.cloudflare.cloudflared.llmclass.plist
```

---

## 📊 모니터링 및 로깅

### 로그 확인
```bash
# 터널 로그
tail -f ../logs/cloudflared.log

# 에러 로그
tail -f ../logs/cloudflared.error.log

# 라이브 로그 (터널 실행 중)
cloudflared tunnel --config tunnel.yml run --loglevel debug
```

### 상태 확인
```bash
# 터널 목록
cloudflared tunnel list

# 터널 정보
cloudflared tunnel info llmclass-platform

# DNS 라우팅 확인
nslookup platform.llmclass.org
```

---

## 🔍 트러블슈팅

### 일반적인 문제들

#### 1. "tunnel with name llmclass-platform already exists"
```bash
# 기존 터널 삭제
cloudflared tunnel delete llmclass-platform

# 또는 다른 이름 사용
cloudflared tunnel create llmclass-platform-2
```

#### 2. "connection refused" 에러
```bash
# 로컬 서비스가 실행 중인지 확인
curl http://localhost:8080/healthz

# Docker 서비스 시작
make up ENV=dev
```

#### 3. DNS 전파 지연
```bash
# DNS 전파 확인
dig platform.llmclass.org

# Cloudflare DNS 직접 확인
dig @1.1.1.1 platform.llmclass.org
```

#### 4. 인증서 에러
- Cloudflare 대시보드에서 SSL/TLS 설정을 "Full" 또는 "Flexible"로 변경
- Edge Certificates가 Active 상태인지 확인

#### 5. 라우팅 문제
```bash
# 현재 라우팅 확인
cloudflared tunnel route ip show

# 특정 터널의 라우팅 확인
cloudflared tunnel route dns llmclass-platform
```

### 로그 분석

**연결 성공 로그:**
```
INFO[2025-08-01] Connection established
INFO[2025-08-01] Registered tunnel connection
```

**연결 실패 로그:**
```
ERROR[2025-08-01] connection refused
ERROR[2025-08-01] failed to connect to origin
```

---

## 🔐 보안 고려사항

### 1. 크리덴셜 보안
- `~/.cloudflared/*.json` 파일의 권한을 600으로 설정
- 크리덴셜 파일을 Git에 커밋하지 않음

### 2. 방화벽 설정
- 로컬 방화벽에서 8080 포트를 외부에 노출하지 않음
- 터널을 통해서만 접근 가능

### 3. 접근 제어
- Cloudflare Access를 사용하여 추가 인증 설정 가능
- IP 화이트리스트 설정 가능

---

## 📈 성능 최적화

### 1. 설정 조정
```yaml
# tunnel.yml에서 최적화 설정
originRequest:
  keepAliveConnections: 10
  keepAliveTimeout: 90s
  connectTimeout: 30s
  httpHostHeader: platform.llmclass.org
```

### 2. 메트릭 모니터링
```yaml
# tunnel.yml에 메트릭 추가
metrics: localhost:2000
```

```bash
# 메트릭 확인
curl http://localhost:2000/metrics
```

---

## ✅ 설정 완료 체크리스트

- [ ] cloudflared 설치 완료
- [ ] Cloudflare 계정 인증 완료
- [ ] 터널 생성 완료
- [ ] DNS 라우팅 설정 완료
- [ ] 설정 파일(tunnel.yml) 생성 완료
- [ ] 로컬 서비스(포트 8080) 실행 중
- [ ] 터널 연결 테스트 성공
- [ ] 외부 도메인 접근 테스트 성공
- [ ] launchd 자동 시작 설정 완료 (선택)
- [ ] 로그 모니터링 설정 완료

---

## 🆘 도움 받기

### 공식 문서
- [Cloudflare Tunnel 문서](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [cloudflared 설치 가이드](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/)

### 명령어 도움말
```bash
cloudflared tunnel --help
cloudflared tunnel create --help
cloudflared tunnel run --help
```

### 커뮤니티
- [Cloudflare Community](https://community.cloudflare.com/)
- [GitHub Issues](https://github.com/cloudflare/cloudflared/issues)