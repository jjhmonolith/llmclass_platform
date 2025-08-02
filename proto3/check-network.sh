#!/bin/bash

# 네트워크 연결 및 OpenAI API 접근 확인 스크립트

echo "🌐 네트워크 연결 상태 확인..."

# 1. 기본 인터넷 연결 확인
echo "1. 기본 인터넷 연결 확인:"
if ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ 인터넷 연결 정상"
else
    echo "❌ 인터넷 연결 실패"
    exit 1
fi

# 2. DNS 해석 확인
echo "2. DNS 해석 확인:"
if nslookup api.openai.com > /dev/null 2>&1; then
    echo "✅ DNS 해석 정상"
else
    echo "❌ DNS 해석 실패"
fi

# 3. OpenAI API 엔드포인트 연결 확인
echo "3. OpenAI API 연결 확인:"
if curl -s --connect-timeout 10 https://api.openai.com > /dev/null; then
    echo "✅ OpenAI API 엔드포인트 연결 정상"
else
    echo "❌ OpenAI API 엔드포인트 연결 실패"
    echo "가능한 원인:"
    echo "- 방화벽 차단"
    echo "- AWS Security Group 설정"
    echo "- OpenAI API 서비스 장애"
fi

# 4. 포트 및 프록시 확인
echo "4. 포트 및 프록시 설정 확인:"
echo "HTTP_PROXY: ${HTTP_PROXY:-없음}"
echo "HTTPS_PROXY: ${HTTPS_PROXY:-없음}"
echo "NO_PROXY: ${NO_PROXY:-없음}"

# 5. EC2 보안 그룹 확인 (AWS CLI가 있는 경우)
if command -v aws &> /dev/null; then
    echo "5. EC2 보안 그룹 확인:"
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' --output text 2>/dev/null || echo "AWS CLI 설정 필요"
fi

echo "완료!"