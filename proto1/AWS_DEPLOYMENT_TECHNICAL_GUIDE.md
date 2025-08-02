# 🔧 LLM Classroom AWS 배포 기술 문서

## 📋 목차
1. [시스템 아키텍처](#시스템-아키텍처)
2. [배포 환경 구성](#배포-환경-구성)
3. [서비스 구성 요소](#서비스-구성-요소)
4. [배포 프로세스 상세](#배포-프로세스-상세)
5. [트러블슈팅 가이드](#트러블슈팅-가이드)
6. [성능 최적화](#성능-최적화)
7. [보안 설정](#보안-설정)
8. [모니터링 및 유지보수](#모니터링-및-유지보수)

---

## 🏗 시스템 아키텍처

### 전체 구성도
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Client (Web)  │────▶│   AWS EC2       │────▶│  OpenAI API     │
│   Browser       │     │   t3.micro      │     │  GPT-4o-mini    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │
                        ┌──────┴──────┐
                        │             │
                  ┌─────▼─────┐ ┌─────▼─────┐
                  │   Nginx    │ │  FastAPI   │
                  │  (Port 80) │ │ (Port 8000)│
                  └────────────┘ └────────────┘
```

### 기술 스택
- **프론트엔드**: HTML5, CSS3, Vanilla JavaScript
- **백엔드**: FastAPI (Python 3.11)
- **웹서버**: Nginx 1.18.0
- **AI 모델**: OpenAI GPT-4o-mini
- **운영체제**: Ubuntu 22.04 LTS
- **클라우드**: AWS EC2 (t3.micro)

---

## 🔧 배포 환경 구성

### EC2 인스턴스 사양
```yaml
Instance Type: t3.micro
vCPUs: 2
Memory: 1 GiB
Network: Up to 5 Gbps
Storage: 8 GiB gp3
Region: ap-southeast-2 (Sydney)
```

### 보안 그룹 설정
```yaml
Inbound Rules:
  - Type: SSH
    Port: 22
    Source: 0.0.0.0/0
    
  - Type: HTTP
    Port: 80
    Source: 0.0.0.0/0
    
  - Type: Custom TCP
    Port: 8000
    Source: 0.0.0.0/0
```

### 시스템 요구사항
```bash
# Python
Python 3.11+

# 시스템 패키지
nginx
git
python3.11-venv
python3.11-dev
```

---

## 📦 서비스 구성 요소

### 1. Nginx 설정
```nginx
# /etc/nginx/sites-available/llm-classroom
server {
    listen 80;
    server_name 3.107.236.141;

    # 루트 경로 리다이렉션
    location = / {
        return 301 /topic-selection.html;
    }

    # 정적 파일 서빙
    location / {
        root /home/ubuntu/llm_classroom_proto1/frontend;
        try_files $uri $uri/ =404;
        
        # CORS 헤더
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
    }

    # API 리버스 프록시
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS 헤더
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
    }
}
```

### 2. Systemd 서비스 설정
```ini
# /etc/systemd/system/llm-classroom.service
[Unit]
Description=LLM Classroom FastAPI Application
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/llm_classroom_proto1
Environment=PATH=/home/ubuntu/llm_classroom_proto1/venv/bin
ExecStart=/home/ubuntu/llm_classroom_proto1/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 3. FastAPI 애플리케이션 구조
```python
# main.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import RedirectResponse
from app.api import chat, initial
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="LLM Classroom",
    description="학생들이 LLM 사용법과 활용을 배울 수 있는 온라인 에듀테크 도구",
    version="1.0.0"
)

# CORS 미들웨어 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API 라우터 등록
app.include_router(chat.router, prefix="/api/v1/chat", tags=["chat"])
app.include_router(initial.router, prefix="/api/v1/chat", tags=["initial"])

# 정적 파일 마운트
app.mount("/", StaticFiles(directory="frontend", html=True), name="static")
```

---

## 🚀 배포 프로세스 상세

### 1. 초기 서버 설정
```bash
# 시스템 업데이트
sudo apt update && sudo apt upgrade -y

# 필수 패키지 설치
sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip git nginx

# 방화벽 설정
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw allow 8000
sudo ufw --force enable
```

### 2. 애플리케이션 배포
```bash
# 코드 클론
cd ~
git clone https://github.com/jjhmonolith/llm_classroom_proto1.git
cd llm_classroom_proto1

# Python 가상환경 설정
python3.11 -m venv venv
source venv/bin/activate

# 의존성 설치
pip install -r requirements.txt

# 환경 변수 설정
cp .env.example .env
nano .env  # OPENAI_API_KEY 설정
```

### 3. 서비스 등록 및 시작
```bash
# Systemd 서비스 등록
sudo cp llm-classroom.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable llm-classroom
sudo systemctl start llm-classroom

# Nginx 설정
sudo cp nginx-config /etc/nginx/sites-available/llm-classroom
sudo ln -s /etc/nginx/sites-available/llm-classroom /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo systemctl restart nginx
```

---

## 🔍 트러블슈팅 가이드

### 1. 일반적인 문제 해결

#### CORS 에러
**문제**: "Access to fetch at ... has been blocked by CORS policy"
```bash
# 해결방법 1: FastAPI CORS 설정 확인
cat main.py | grep -A 10 "CORSMiddleware"

# 해결방법 2: Nginx CORS 헤더 확인
sudo nano /etc/nginx/sites-available/llm-classroom
```

#### 502 Bad Gateway
**문제**: Nginx가 FastAPI 서버에 연결할 수 없음
```bash
# FastAPI 서비스 상태 확인
sudo systemctl status llm-classroom

# 포트 확인
sudo ss -tlnp | grep :8000

# 서비스 재시작
sudo systemctl restart llm-classroom
```

#### Permission Denied
**문제**: Nginx가 정적 파일에 접근할 수 없음
```bash
# 권한 설정
sudo chmod 755 /home/ubuntu
sudo chmod 755 /home/ubuntu/llm_classroom_proto1
sudo chmod 755 /home/ubuntu/llm_classroom_proto1/frontend
sudo chmod 644 /home/ubuntu/llm_classroom_proto1/frontend/*
```

### 2. 디버깅 명령어
```bash
# FastAPI 로그 확인
sudo journalctl -u llm-classroom -f

# Nginx 에러 로그
sudo tail -f /var/log/nginx/error.log

# API 테스트
curl -X POST http://localhost:8000/api/v1/chat/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "테스트", "topic": "테스트", "conversation_history": []}'
```

---

## ⚡ 성능 최적화

### 1. Nginx 최적화
```nginx
# /etc/nginx/nginx.conf
worker_processes auto;
worker_connections 1024;

# Gzip 압축 활성화
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
```

### 2. FastAPI 최적화
```python
# Uvicorn 워커 수 조정 (프로덕션)
uvicorn main:app --workers 2 --host 0.0.0.0 --port 8000
```

### 3. 시스템 리소스 모니터링
```bash
# CPU 및 메모리 사용량
htop

# 디스크 사용량
df -h

# 네트워크 연결
netstat -an | grep :80 | wc -l
```

---

## 🔒 보안 설정

### 1. 환경 변수 보호
```bash
# .env 파일 권한
chmod 600 .env

# 시스템 환경 변수 사용
export OPENAI_API_KEY="your-key"
```

### 2. HTTPS 설정 (Let's Encrypt)
```bash
# Certbot 설치
sudo apt install certbot python3-certbot-nginx

# SSL 인증서 발급
sudo certbot --nginx -d your-domain.com

# 자동 갱신 설정
sudo crontab -e
# 추가: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 3. 보안 헤더 추가
```nginx
# Nginx 보안 헤더
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

---

## 📊 모니터링 및 유지보수

### 1. 로그 관리
```bash
# 로그 순환 설정
sudo nano /etc/logrotate.d/llm-classroom

/home/ubuntu/llm_classroom_proto1/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
```

### 2. 백업 전략
```bash
# 데이터베이스 백업 (향후 구현시)
#!/bin/bash
DATE=$(date +%Y%m%d)
backup_dir="/home/ubuntu/backups"
mkdir -p $backup_dir

# 코드 백업
tar -czf $backup_dir/code_$DATE.tar.gz /home/ubuntu/llm_classroom_proto1
```

### 3. 업데이트 프로세스
```bash
#!/bin/bash
# update.sh
cd /home/ubuntu/llm_classroom_proto1
git pull origin main
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart llm-classroom
sudo systemctl restart nginx
```

---

## 🔄 CI/CD 파이프라인 (향후 구현)

### GitHub Actions 워크플로우
```yaml
name: Deploy to AWS

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Deploy to EC2
      uses: appleboy/ssh-action@master
      with:
        host: ${{ secrets.EC2_HOST }}
        username: ubuntu
        key: ${{ secrets.EC2_SSH_KEY }}
        script: |
          cd ~/llm_classroom_proto1
          git pull origin main
          source venv/bin/activate
          pip install -r requirements.txt
          sudo systemctl restart llm-classroom
```

---

## 📈 확장성 고려사항

### 1. 수평 확장
- **로드 밸런서**: AWS ALB 사용
- **다중 인스턴스**: Auto Scaling Group 구성
- **세션 관리**: Redis를 통한 세션 공유

### 2. 데이터베이스 (향후)
- **PostgreSQL**: 대화 기록 저장
- **Redis**: 캐싱 및 세션 관리
- **S3**: 정적 파일 및 백업 저장

### 3. 모니터링 도구
- **CloudWatch**: AWS 리소스 모니터링
- **Grafana**: 시각화 대시보드
- **Sentry**: 에러 트래킹

---

## 🎯 결론

이 문서는 LLM Classroom의 AWS 배포에 대한 기술적 세부사항을 다룹니다. 
지속적인 개선과 확장을 위해 이 문서는 정기적으로 업데이트됩니다.

**마지막 업데이트**: 2025년 7월 23일