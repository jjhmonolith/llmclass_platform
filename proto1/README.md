# 🎓 LLM Classroom

**AI와 함께하는 새로운 학습 경험** - 중학생을 위한 지능형 교육 플랫폼

[![Live Demo](https://img.shields.io/badge/Live%20Demo-3.107.236.141-blue?style=for-the-badge)](http://3.107.236.141)
[![GitHub](https://img.shields.io/badge/GitHub-Source%20Code-black?style=for-the-badge&logo=github)](https://github.com/jjhmonolith/llm_classroom_proto1)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

> 💡 **혁신적인 듀얼 AI 시스템**으로 학생들이 AI와 효과적으로 소통하는 방법을 배우고, 실시간 튜터 피드백을 통해 학습 효과를 극대화하는 교육 플랫폼

## 🌟 서비스 소개

LLM Classroom은 단순히 AI와 대화하는 것을 넘어서, **교육적 가치**를 극대화하는 차세대 에듀테크 플랫폼입니다.

### 🎯 해결하는 문제
- ❌ AI를 단순 답변 기계로만 사용하는 학생들
- ❌ 효과적인 질문 방법을 모르는 학생들  
- ❌ AI와의 대화가 학습으로 연결되지 않는 문제

### ✅ 우리의 해결책
- 🤖 **듀얼 AI 시스템**: 채팅 AI + 교육 전문 튜터 AI
- 📚 **체계적 학습 가이드**: 주제별 맞춤형 학습 경로 제공
- 💡 **실시간 피드백**: 질문 방식과 사고 과정 개선 코칭

## ✨ 주요 기능

### 🎓 학생 기능
- **주제별 LLM 대화**: 선택한 학습 주제에 맞는 AI와의 대화 환경
- **실시간 AI 튜터 피드백**: 학생의 질문 방식과 대화 패턴을 분석하여 개선점 제안
- **가이드형 시작 질문**: AI가 생성하는 개인화된 학습 가이드와 시작 질문 예시
- **마크다운 렌더링**: 풍부한 텍스트 표현으로 더 나은 학습 경험
- **클릭형 질문 전송**: 추천 질문을 클릭하여 즉시 대화 시작

### 🔧 AI 시스템
- **듀얼 AI 구조**: 채팅 AI와 튜터 AI의 분리된 역할
- **주제 관리**: 학습 주제에서 벗어나는 대화를 감지하고 리다이렉션
- **동적 프롬프트**: 각 주제별 맞춤형 AI 프롬프트 생성
- **GPT-4o-mini 모델**: 모든 AI 상호작용에 최신 모델 사용

## 🛠 기술 스택

- **Backend**: FastAPI
- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **AI Integration**: OpenAI GPT-4o-mini API
- **Deployment**: Docker, AWS EC2, Nginx
- **Version Control**: Git, GitHub

## 🚀 빠른 시작

### 🌐 온라인 체험 (권장)
**바로 사용해보세요!** ✨
```
📱 웹브라우저에서: http://3.107.236.141
```

### 💻 로컬 개발 환경
```bash
# 1. 프로젝트 클론
git clone https://github.com/jjhmonolith/llm_classroom_proto1.git
cd llm_classroom_proto1

# 2. 가상환경 설정
python3.11 -m venv venv
source venv/bin/activate  # macOS/Linux

# 3. 의존성 설치
pip install -r requirements.txt

# 4. 환경변수 설정
cp .env.example .env
echo "OPENAI_API_KEY=your-api-key-here" >> .env

# 5. 서버 실행
uvicorn main:app --host 0.0.0.0 --port 8000
```

### 🐳 Docker 실행
```bash
# Docker 이미지 빌드 및 실행
docker build -t llm-classroom .
docker run -p 8000:8000 --env-file .env llm-classroom
```

## 📁 프로젝트 구조

```
llm_classroom_proto1/
├── app/
│   ├── api/                 # API 라우터
│   │   ├── chat.py         # 채팅 API
│   │   └── initial.py      # 초기 설정 API
│   ├── services/           # 비즈니스 로직
│   │   ├── openai_service.py    # OpenAI API 통합
│   │   ├── topic_service.py     # 주제 관리 서비스
│   │   └── tutor_service.py     # AI 튜터 서비스
│   ├── models/             # 데이터 모델
│   └── utils/              # 유틸리티 함수
├── frontend/               # 프론트엔드 파일
│   ├── index.html         # 메인 채팅 페이지
│   └── topic-selection.html # 주제 선택 페이지
├── requirements.txt        # Python 의존성
├── main.py                # 애플리케이션 진입점
├── Dockerfile             # Docker 설정
├── deploy.sh              # 배포 스크립트
├── .env.example           # 환경변수 템플릿
├── AWS_DEPLOYMENT_GUIDE.md # AWS 배포 가이드
└── TECHNICAL_DOCUMENTATION.md # 기술 문서
```

## 📖 문서

- **[기술 문서](TECHNICAL_DOCUMENTATION.md)**: 시스템 아키텍처, AI 프롬프트, API 명세
- **[AWS 배포 가이드](AWS_DEPLOYMENT_GUIDE.md)**: 단계별 AWS 배포 방법
- **[환경 설정](.env.example)**: 환경변수 설정 가이드

## 🎮 사용 방법

1. **주제 선택**: 학습하고 싶은 주제를 선택합니다
2. **AI 가이드 확인**: 우측 튜터 피드백 영역에서 학습 가이드를 확인합니다
3. **질문 시작**: 추천 질문을 클릭하거나 직접 질문을 입력합니다
4. **피드백 활용**: AI 튜터의 실시간 피드백을 통해 질문 방식을 개선합니다

## 🔒 보안 및 프라이버시

- OpenAI API 키는 환경변수로 안전하게 관리
- 학생 대화 내용은 세션 기반으로만 저장
- HTTPS 지원 (Let's Encrypt SSL 인증서)

## 📊 성능 특징

- **응답 속도**: GPT-4o-mini의 빠른 응답 시간
- **확장성**: Docker 컨테이너 기반 배포로 쉬운 확장
- **안정성**: Nginx 리버스 프록시와 systemd 서비스 관리

## 🤝 기여 방법

1. Fork 이 리포지토리
2. Feature 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 변경사항 커밋 (`git commit -m 'Add amazing feature'`)
4. 브랜치에 Push (`git push origin feature/amazing-feature`)
5. Pull Request 생성

## 📄 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다.

## 🔗 링크 및 리소스

### 📚 문서
- **[사용자 가이드](USER_GUIDE.md)**: 서비스 사용법 상세 안내
- **[기술 문서](TECHNICAL_DOCUMENTATION.md)**: 시스템 아키텍처 및 구현 세부사항
- **[AWS 배포 가이드](AWS_DEPLOYMENT_GUIDE.md)**: 단계별 배포 방법
- **[AWS 배포 기술 문서](AWS_DEPLOYMENT_TECHNICAL_GUIDE.md)**: 상세 배포 기술 가이드

### 🌐 서비스
- **[라이브 데모](http://3.107.236.141)**: 실제 서비스 체험
- **[GitHub 리포지토리](https://github.com/jjhmonolith/llm_classroom_proto1)**: 소스 코드

### 📊 성과 지표
- **응답 속도**: 평균 2-3초 (GPT-4o-mini 최적화)
- **지원 주제**: 6개 기본 주제 + 무제한 커스텀 주제
- **동시 사용자**: 다중 사용자 지원 (AWS EC2 기반)

## 🎯 교육적 효과

### 학생에게
- ✅ **질문 스킬 향상**: 더 구체적이고 효과적인 질문 방법 학습
- ✅ **비판적 사고**: AI 답변을 분석하고 추가 질문하는 능력 개발
- ✅ **자기주도 학습**: 스스로 탐구하고 학습하는 습관 형성
- ✅ **디지털 리터러시**: AI 시대 필수 소양 습득

### 교육 현장에
- ✅ **개별 맞춤 학습**: 각자의 속도와 관심사에 맞는 학습 지원
- ✅ **24시간 학습 지원**: 언제든지 접근 가능한 AI 튜터
- ✅ **교사 보조 도구**: 교사의 개별 지도를 보완하는 도구
- ✅ **미래 교육 대비**: AI 시대 교육 모델 선도

## 📈 버전 히스토리

### **v1.0** (2025.07.23) - 현재 버전
- 🚀 **AWS 프로덕션 배포** 완료
- 🤖 **듀얼 AI 시스템** 구현 (ChatGPT + 튜터 AI)
- 📚 **6개 학습 주제** 지원 + 커스텀 주제
- 💡 **실시간 튜터 피드백** 시스템
- 🎨 **반응형 웹 인터페이스** (6:4 레이아웃)
- 🔒 **CORS 및 보안** 설정 완료
- 📱 **다중 디바이스** 지원 (PC, 태블릿, 모바일)
