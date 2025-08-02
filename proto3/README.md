# LLM Classroom Proto3

FIRE 프레임워크 기반 프롬프트 학습 플랫폼

## 주요 기능

- **FIRE 프롬프트 평가**: Focus, Input, Rules, Effect 프레임워크로 프롬프트 품질 평가
- **실시간 점수 추이**: 프롬프트별 점수 변화를 그래프로 시각화
- **축하 애니메이션**: 점수 향상 시 폭죽 효과 및 축하 메시지
- **마크다운 렌더링**: 학습목표와 AI 응답에 마크다운 지원
- **비동기 처리**: AI 응답과 평가를 독립적으로 처리

## 기술 스택

- **백엔드**: FastAPI, Python 3.12+
- **프론트엔드**: 정적 HTML/CSS/JavaScript
- **AI**: OpenAI GPT-4o-mini
- **스타일**: 오렌지-레드 테마

## 설치 및 실행

1. **저장소 클론**
   ```bash
   git clone https://github.com/jjhmonolith/llm_classroom_proto3.git
   cd llm_classroom_proto3
   ```

2. **의존성 설치**
   ```bash
   pip install -r requirements.txt
   ```

3. **환경 변수 설정**
   ```bash
   cp .env.example .env
   # .env 파일에 OpenAI API 키 설정
   echo "OPENAI_API_KEY=your_api_key_here" > .env
   ```

4. **서버 실행**
   ```bash
   python main.py
   ```

5. **브라우저에서 접속**
   ```
   http://localhost:8080
   ```

## FIRE 프레임워크

효과적인 프롬프트 작성을 위한 4가지 핵심 요소:

- **F: Focus** - 무엇을 알고 싶은가? (명확한 목적)
- **I: Input** - 어떤 정보를 주었는가? (배경, 맥락, 자료)
- **R: Rules** - 어떻게 표현되길 원하는가? (형식, 조건)
- **E: Effect** - 결과가 어떻게 쓰일 것인가? (사용 목적)

각 요소는 0-3점으로 평가되며, 총 12점 만점입니다.

## 프로젝트 구조

```
├── app/
│   ├── api/           # FastAPI 라우터
│   ├── models/        # Pydantic 모델
│   ├── services/      # OpenAI 서비스
│   └── utils/         # 유틸리티 함수
├── frontend/          # 정적 웹 파일
│   ├── index.html     # 홈페이지
│   ├── setup.html     # 설정 페이지
│   └── learning.html  # 학습 페이지
├── main.py           # FastAPI 앱 엔트리포인트
└── requirements.txt  # Python 의존성
```

## API 엔드포인트

- `GET /` - 홈페이지
- `GET /setup` - 설정 페이지
- `GET /learning` - 학습 페이지
- `POST /api/oneshot` - AI 응답 생성
- `POST /api/evaluate-prompt` - FIRE 프롬프트 평가
- `GET /api/health` - 헬스 체크

## 개발 히스토리

이 프로젝트는 Proto2(Next.js + Express)에서 단순한 구조로 마이그레이션되었으며, RTCF에서 FIRE 프레임워크로 평가 방식이 개선되었습니다.

## 라이선스

MIT License