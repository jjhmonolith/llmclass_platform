# EC2 배포 가이드

## 1. EC2 인스턴스 준비

```bash
# 시스템 업데이트
sudo apt update && sudo apt upgrade -y

# Python 및 필수 패키지 설치
sudo apt install python3 python3-pip python3-venv nginx git -y

# 프로젝트 클론
cd /home/ubuntu
git clone https://github.com/jjhmonolith/llm_classroom_proto3.git
cd llm_classroom_proto3
```

## 2. 가상환경 설정

```bash
# 가상환경 생성 및 활성화
python3 -m venv venv
source venv/bin/activate

# 의존성 설치
pip install -r requirements.txt
```

## 3. 환경변수 설정

```bash
# .env 파일 생성
cp .env.example .env
nano .env

# 다음 내용 입력:
OPENAI_API_KEY=your_openai_api_key_here
```

## 4. Nginx 설정

```bash
# Nginx 설정 파일 복사
sudo cp nginx.conf /etc/nginx/sites-available/llm-classroom
sudo ln -s /etc/nginx/sites-available/llm-classroom /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Nginx 테스트 및 재시작
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
```

## 5. Systemd 서비스 설정

```bash
# 서비스 파일 복사
sudo cp llm-classroom.service /etc/systemd/system/

# 서비스 활성화
sudo systemctl daemon-reload
sudo systemctl enable llm-classroom
sudo systemctl start llm-classroom

# 서비스 상태 확인  
sudo systemctl status llm-classroom
```

## 6. 방화벽 설정

```bash
# UFW 방화벽 설정
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 22
sudo ufw enable
```

## 7. 배포 완료 확인

```bash
# 서비스 로그 확인
sudo journalctl -u llm-classroom -f

# API 테스트
curl http://localhost/api/health

# 브라우저에서 접속
# http://your-ec2-public-ip
```

## 트러블슈팅

### 502 Bad Gateway 오류

1. **FastAPI 서버 상태 확인:**
   ```bash
   sudo systemctl status llm-classroom
   sudo journalctl -u llm-classroom -n 50
   ```

2. **포트 사용 확인:**
   ```bash
   sudo netstat -tlnp | grep 8080
   ```

3. **환경변수 확인:**
   ```bash
   sudo systemctl show llm-classroom --property=Environment
   ```

4. **수동으로 서버 테스트:**
   ```bash
   cd /home/ubuntu/llm_classroom_proto3
   source venv/bin/activate
   python main.py
   ```

### 서비스 재시작

```bash
# 코드 업데이트 후
cd /home/ubuntu/llm_classroom_proto3
git pull origin main
sudo systemctl restart llm-classroom
```

### 로그 모니터링

```bash
# 애플리케이션 로그
sudo journalctl -u llm-classroom -f

# Nginx 로그
sudo tail -f /var/log/nginx/llm-classroom-error.log
sudo tail -f /var/log/nginx/llm-classroom-access.log
```