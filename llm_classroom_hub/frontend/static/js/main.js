// DOM이 로드된 후 실행
document.addEventListener('DOMContentLoaded', function() {
    
    // 카드 애니메이션 초기화
    initializeAnimations();
    
    // 서비스 상태 체크
    checkServiceStatus();
    
});


// 카드 애니메이션 초기화
function initializeAnimations() {
    // 스크롤 시 애니메이션 트리거
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);
    
    // 정보 카드들에 관찰자 적용
    const infoCards = document.querySelectorAll('.info-card');
    infoCards.forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(30px)';
        card.style.transition = 'all 0.6s ease';
        observer.observe(card);
    });
}

// 서비스 상태 체크 (실제 서비스 가용성 확인)
async function checkServiceStatus() {
    const serviceCards = document.querySelectorAll('.service-card');
    
    for (let card of serviceCards) {
        const status = card.dataset.status;
        if (status === 'active') {
            const serviceUrl = card.querySelector('.btn-primary')?.href;
            if (serviceUrl) {
                try {
                    // 간단한 헬스 체크 (CORS 문제로 실제로는 동작하지 않을 수 있음)
                    const response = await fetch(serviceUrl + '/health', {
                        method: 'GET',
                        mode: 'no-cors',
                        cache: 'no-cache'
                    });
                    // 성공 시 초록색 점 표시
                    addStatusIndicator(card, 'online');
                } catch (error) {
                    // 실패 시 회색 점 표시 (실제로는 CORS 때문에 항상 여기로 옴)
                    addStatusIndicator(card, 'unknown');
                }
            }
        }
    }
}

// 상태 표시기 추가
function addStatusIndicator(card, status) {
    const statusElement = card.querySelector('.service-status');
    if (statusElement && status === 'online') {
        const indicator = document.createElement('span');
        indicator.className = 'status-indicator online';
        indicator.style.cssText = `
            display: inline-block;
            width: 8px;
            height: 8px;
            background: #28a745;
            border-radius: 50%;
            margin-left: 8px;
            animation: pulse 2s infinite;
        `;
        statusElement.appendChild(indicator);
    }
}

// 서비스 카드 클릭 트래킹 (분석용)
function trackServiceClick(serviceName, serviceUrl) {
    // 실제 환경에서는 분석 도구에 이벤트 전송
    console.log(`Service clicked: ${serviceName} -> ${serviceUrl}`);
    
    // 로컬 스토리지에 사용 기록 저장
    const usage = JSON.parse(localStorage.getItem('llm_classroom_usage') || '{}');
    usage[serviceName] = (usage[serviceName] || 0) + 1;
    usage.lastUsed = new Date().toISOString();
    localStorage.setItem('llm_classroom_usage', JSON.stringify(usage));
}

// 서비스 링크에 트래킹 추가
document.addEventListener('click', function(e) {
    if (e.target.closest('.btn-primary, .btn-secondary')) {
        const card = e.target.closest('.service-card');
        if (card) {
            const serviceName = card.querySelector('.service-name').textContent;
            const serviceUrl = e.target.href;
            trackServiceClick(serviceName, serviceUrl);
        }
    }
});


// 페이지 로드 완료 후 통계 업데이트
window.addEventListener('load', function() {
    updatePageStats();
});

// 페이지 통계 업데이트
function updatePageStats() {
    const activeServices = document.querySelectorAll('.service-card[data-status="active"]').length;
    const comingSoonServices = document.querySelectorAll('.service-card[data-status="coming_soon"]').length;
    
    // 헤더의 통계 애니메이션
    animateNumber('.stat-number', activeServices, 0);
    
    setTimeout(() => {
        animateNumber('.stat-number', comingSoonServices, 1);
    }, 500);
}

// 숫자 애니메이션
function animateNumber(selector, targetNumber, index) {
    const elements = document.querySelectorAll(selector);
    if (elements[index]) {
        let current = 0;
        const increment = targetNumber / 30;
        const timer = setInterval(() => {
            current += increment;
            if (current >= targetNumber) {
                current = targetNumber;
                clearInterval(timer);
            }
            elements[index].textContent = Math.floor(current);
        }, 50);
    }
}

// 서비스 검색 기능 (향후 확장용)
function initializeSearch() {
    // 검색 박스가 추가되면 여기에 구현
    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
        searchInput.addEventListener('input', function(e) {
            const query = e.target.value.toLowerCase();
            const serviceCards = document.querySelectorAll('.service-card');
            
            serviceCards.forEach(card => {
                const name = card.querySelector('.service-name').textContent.toLowerCase();
                const description = card.querySelector('.service-description').textContent.toLowerCase();
                const features = Array.from(card.querySelectorAll('.feature-tag'))
                    .map(tag => tag.textContent.toLowerCase()).join(' ');
                
                const searchText = `${name} ${description} ${features}`;
                
                if (searchText.includes(query)) {
                    card.style.display = 'block';
                } else {
                    card.style.display = 'none';
                }
            });
        });
    }
}

// CSS 애니메이션 추가
const style = document.createElement('style');
style.textContent = `
    @keyframes pulse {
        0% { opacity: 1; }
        50% { opacity: 0.5; }
        100% { opacity: 1; }
    }
    
    .service-card {
        transition: all 0.3s ease;
    }
    
    .service-card.filtering {
        opacity: 0.3;
        transform: scale(0.95);
    }
`;
document.head.appendChild(style);