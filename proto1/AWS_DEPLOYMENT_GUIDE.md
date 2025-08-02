# 🚀 LLM Classroom AWS 배포 가이드

이 가이드는 LLM Classroom을 AWS 프리티어를 사용하여 배포하는 방법을 단계별로 설명합니다.

## 📋 사전 준비사항

### 필수 준비물
- ✅ AWS 계정 (프리티어)
- ✅ GitHub 계정
- ✅ OpenAI API 키
- ✅ 도메인 (선택사항, 없으면 IP로 접속)

### 예상 비용 (프리티어 기준)
- **EC2 t3.micro**: 월 750시간 무료 (1개월 24시간 운영 가능)
- **Route 53**: 호스팅 존 월 $0.50 (도메인 사용시)
- **데이터 전송**: 월 15GB 무료
- **총 예상 비용**: 도메인 없이 **무료**, 도메인 사용시 **월 ~$0.50**

---

## 🌟 1단계: GitHub 리포지토리 설정

### 1.1 로컬 Git 초기화
```bash
cd "/Users/jonghyunjun/LLM Classroom"

# Git 초기화 (아직 안했다면)
git init

# 모든 파일 추가
git add .

# 첫 커밋
git commit -m "Initial commit: LLM Classroom v1.0"
```

### 1.2 GitHub 리포지토리 생성
1. **GitHub 웹사이트**에서 새 리포지토리 생성
   - 리포지토리 이름: `llm-classroom`
   - 설명: `AI-powered educational platform for middle school students`
   - 가시성: `Private` (API 키 보안을 위해)

2. **로컬과 연결**
```bash
# GitHub 리포지토리와 연결 (본인의 USERNAME 사용)
git remote add origin https://github.com/YOUR_USERNAME/llm-classroom.git

# 메인 브랜치로 푸시
git branch -M main
git push -u origin main
```

---

## 🖥 2단계: AWS EC2 인스턴스 설정

### 2.1 EC2 인스턴스 생성

1. **AWS Management Console** 로그인
2. **EC2 대시보드**로 이동
3. **"Launch Instance"** 클릭

#### 인스턴스 설정
```
Name: llm-classroom-server
Application and OS Images: Ubuntu Server 22.04 LTS (Free tier eligible)
Instance type: t3.micro (Free tier eligible)
Key pair: 
  - Create new key pair → "llm-classroom-key"
  - Download .pem 파일 (중요: 잘 보관하세요!)
Network settings:
  - Allow SSH traffic from: Anywhere (0.0.0.0/0)
  - Allow HTTPS traffic from the internet
  - Allow HTTP traffic from the internet
Storage: 8 GiB gp3 (Free tier)
```

4. **"Launch instance"** 클릭

### 2.2 보안 그룹 설정
1. **EC2 Dashboard** → **Security Groups**
2. 생성된 보안 그룹 선택
3. **"Inbound rules"** → **"Edit inbound rules"**

#### 필요한 포트 추가
```
Type: Custom TCP, Port Range: 8000, Source: 0.0.0.0/0 (FastAPI)
Type: HTTP, Port Range: 80, Source: 0.0.0.0/0
Type: HTTPS, Port Range: 443, Source: 0.0.0.0/0  
Type: SSH, Port Range: 22, Source: 0.0.0.0/0
```

---

## 📦 3단계: EC2 서버 설정

### 3.1 SSH 접속
```bash
# 키 파일 권한 설정
chmod 400 ~/Downloads/llm-classroom-key.pem

# EC2 인스턴스 접속 (Public IPv4 주소를 YOUR_EC2_IP에 입력)
ssh -i ~/Downloads/llm-classroom-key.pem ubuntu@YOUR_EC2_IP
```

### 3.2 서버 환경 설정
```bash
# 시스템 업데이트
sudo apt update && sudo apt upgrade -y

# Python 3.11 설치
sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

# Git 설치
sudo apt install -y git

# Nginx 설치 (리버스 프록시용)
sudo apt install -y nginx

# 방화벽 설정
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw allow 8000
sudo ufw --force enable
```

### 3.3 애플리케이션 설치
```bash
# 홈 디렉토리로 이동
cd ~

# GitHub에서 코드 클론 (본인의 리포지토리 URL 사용)
git clone https://github.com/YOUR_USERNAME/llm-classroom.git

# 프로젝트 디렉토리로 이동
cd llm-classroom

# Python 가상환경 생성
python3.11 -m venv venv

# 가상환경 활성화
source venv/bin/activate

# 의존성 설치
pip install -r requirements.txt
```

### 3.4 환경 변수 설정
```bash
# .env 파일 생성
cp .env.example .env

# 환경 변수 편집
nano .env
```

#### .env 파일 내용 (실제 값으로 수정)
```env
# OpenAI API Configuration
OPENAI_API_KEY=sk-proj-your-actual-openai-api-key-here

# Application Configuration  
APP_HOST=0.0.0.0
APP_PORT=8000
APP_ENV=production
```

---

## 🔧 4단계: 서비스 설정 및 자동 시작

### 4.1 Systemd 서비스 생성
```bash
# 서비스 파일 생성
sudo nano /etc/systemd/system/llm-classroom.service
```

#### 서비스 파일 내용
```ini
[Unit]
Description=LLM Classroom FastAPI Application
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/llm-classroom
Environment=PATH=/home/ubuntu/llm-classroom/venv/bin
ExecStart=/home/ubuntu/llm-classroom/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

### 4.2 서비스 활성화
```bash
# 서비스 리로드
sudo systemctl daemon-reload

# 서비스 활성화 (부팅시 자동 시작)
sudo systemctl enable llm-classroom

# 서비스 시작
sudo systemctl start llm-classroom

# 서비스 상태 확인
sudo systemctl status llm-classroom
```

---

## 🌐 5단계: Nginx 리버스 프록시 설정

### 5.1 Nginx 설정
```bash
# 기본 설정 제거
sudo rm /etc/nginx/sites-enabled/default

# 새 설정 파일 생성
sudo nano /etc/nginx/sites-available/llm-classroom
```

#### Nginx 설정 파일 내용
```nginx
server {
    listen 80;
    server_name YOUR_DOMAIN_OR_IP;  # 실제 도메인 또는 EC2 IP 주소로 변경

    # 정적 파일 서빙 (frontend)
    location / {
        root /home/ubuntu/llm-classroom/frontend;
        try_files $uri $uri/ /index.html;
        
        # CORS 헤더 추가
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
    }

    # API 요청은 FastAPI로 프록시
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS 헤더 추가
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
    }
}
```

### 5.2 설정 활성화
```bash
# 설정 활성화
sudo ln -s /etc/nginx/sites-available/llm-classroom /etc/nginx/sites-enabled/

# Nginx 설정 테스트
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx

# Nginx 자동 시작 설정
sudo systemctl enable nginx
```

---

## 🔍 6단계: 배포 확인 및 테스트

### 6.1 서비스 상태 확인
```bash
# 모든 서비스 상태 확인
sudo systemctl status llm-classroom
sudo systemctl status nginx

# 포트 확인
sudo netstat -tlnp | grep :8000
sudo netstat -tlnp | grep :80

# 로그 확인
sudo journalctl -u llm-classroom -f
```

### 6.2 웹 접속 테스트
1. **브라우저에서 접속**: `http://YOUR_EC2_PUBLIC_IP`
2. **주제 선택 페이지** 확인
3. **채팅 기능** 테스트
4. **튜터 피드백** 기능 확인

---

## 🌍 7단계: 도메인 연결 (선택사항)

### 7.1 Route 53 설정 (도메인이 있는 경우)

1. **Route 53 Console**로 이동
2. **"Create hosted zone"** 클릭
3. **Domain name**: 본인의 도메인 입력
4. **Type**: Public hosted zone
5. **Create hosted zone** 클릭

### 7.2 A 레코드 생성
1. **호스팅 존 선택**
2. **"Create record"** 클릭
```
Record name: (비워둠, 또는 www)
Record type: A
Value: EC2_PUBLIC_IP_ADDRESS
TTL: 300
```

### 7.3 도메인 네임서버 업데이트
- Route 53에서 제공하는 네임서버를 도메인 등록업체에서 설정

---

## 🔒 8단계: HTTPS 설정 (Let's Encrypt)

### 8.1 Certbot 설치
```bash
# Certbot 설치
sudo apt install -y certbot python3-certbot-nginx

# SSL 인증서 발급 (도메인이 있는 경우)
sudo certbot --nginx -d your-domain.com

# 자동 갱신 설정
sudo crontab -e

# 다음 라인 추가
0 12 * * * /usr/bin/certbot renew --quiet
```

---

## 🔧 9단계: 모니터링 및 유지보수

### 9.1 로그 모니터링
```bash
# 애플리케이션 로그
sudo journalctl -u llm-classroom -f

# Nginx 로그
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 9.2 업데이트 스크립트
```bash
# update.sh 스크립트 생성
cat > ~/update-llm-classroom.sh << 'EOF'
#!/bin/bash
cd ~/llm-classroom
git pull origin main
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart llm-classroom
sudo systemctl restart nginx
echo "✅ 업데이트 완료!"
EOF

chmod +x ~/update-llm-classroom.sh
```

---

## 🎯 완료! 서비스 URL

### 🌐 접속 주소
- **IP 접속**: `http://YOUR_EC2_PUBLIC_IP`
- **도메인 접속**: `https://your-domain.com` (HTTPS 설정한 경우)

### 📊 AWS 프리티어 사용량 모니터링
1. **AWS Billing Dashboard**에서 사용량 확인
2. **CloudWatch**에서 인스턴스 모니터링
3. 프리티어 한도 초과 시 알림 설정 권장

---

## 🚨 문제 해결

### 자주 발생하는 문제들

#### 1. 서비스가 시작되지 않을 때
```bash
# 로그 확인
sudo journalctl -u llm-classroom -n 50

# 수동 실행으로 오류 확인
cd ~/llm-classroom
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000
```

#### 2. OpenAI API 오류
- `.env` 파일의 `OPENAI_API_KEY` 확인
- API 키의 유효성 및 잔액 확인

#### 3. CORS 오류
- Nginx 설정에서 CORS 헤더 확인
- 브라우저 개발자 도구에서 네트워크 탭 확인

#### 4. 접속이 안될 때
- 보안 그룹에서 포트 8000, 80, 443 확인
- 방화벽 설정 확인: `sudo ufw status`

---

## 📞 지원 및 문의

배포 과정에서 문제가 발생하면:
1. **로그 확인** 후 오류 메시지 분석
2. **AWS 문서** 참조
3. **GitHub Issues** 활용

---

**🎉 축하합니다! LLM Classroom이 성공적으로 AWS에 배포되었습니다!**

이제 전 세계 어디서나 여러분의 AI 교육 플랫폼에 접속할 수 있습니다.