---
name: web-scraping-automation
description: 웹스크래핑, 크롤링, 데이터수집, 자동화파싱, 경쟁사분석, 가격모니터링, 업체리스트, 요금제크롤링, BeautifulSoup, Selenium, Playwright, 데이터추출, 웹자동화로 웹사이트 데이터를 자동으로 수집하고 정리하는 스킬
---

# Web Scraping Automation: 웹 데이터 자동 수집 전문가

## 개요

웹 스크래핑은 웹사이트에서 필요한 데이터를 자동으로 추출하여 구조화된 형식으로 저장하는 기술입니다. 수동으로 복사-붙여넣기 하던 작업을 자동화하여 시간을 대폭 절약하고, 실시간 데이터 모니터링을 가능하게 합니다.

이 스킬은 네이버 검색 결과, 쇼핑몰 가격, 경쟁사 요금제 등 다양한 웹 데이터를 효율적으로 수집하고 활용하는 실전 가이드입니다.

## 언제 사용하나요?

- **업체/리스트 수집**: 네이버에서 "인력파견업체" 검색 결과 전부 수집
- **가격 모니터링**: 경쟁사 요금제 자동 추적 및 비교
- **자동 업데이트**: 웹페이지에 최신 데이터 자동 반영
- **경쟁사 분석**: 제품, 리뷰, 스펙 자동 수집
- **부동산 정보**: 매물 리스트, 가격 변동 추적
- **뉴스 모니터링**: 특정 키워드 관련 기사 자동 수집

## 필요한 것

- Python 기본 지식
- 크롤링 대상 웹사이트 URL
- 윤리적 사용 의지 (robots.txt 준수)

## 실전 가이드

### Step 1: 타겟 사이트 분석

크롤링할 페이지의 구조를 파악합니다.

```python
# 1. 브라우저 개발자 도구 열기 (F12)
# 2. Elements 탭에서 원하는 데이터 찾기
# 3. 선택자(Selector) 확인

# 예시: 네이버 검색 결과
# <div class="total_area">
#   <a class="link_tit">업체명</a>
#   <span class="addr">주소</span>
#   <span class="tel">전화번호</span>
# </div>
```

### Step 2: 크롤러 설정 (정적 페이지)

BeautifulSoup으로 정적 HTML 파싱

```python
import requests
from bs4 import BeautifulSoup
import pandas as pd

def scrape_static_page(url):
    """정적 웹페이지 크롤링"""

    # User-Agent 설정 (봇 차단 방지)
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }

    # 페이지 요청
    response = requests.get(url, headers=headers)
    response.raise_for_status()

    # HTML 파싱
    soup = BeautifulSoup(response.text, 'html.parser')

    return soup

# 사용 예시
url = 'https://example.com/list'
soup = scrape_static_page(url)

# 데이터 추출
items = soup.select('.item-card')
for item in items:
    name = item.select_one('.item-name').text.strip()
    price = item.select_one('.item-price').text.strip()
    print(f'{name}: {price}')
```

### Step 3: 동적 페이지 크롤링 (Playwright)

JavaScript로 렌더링되는 페이지는 Playwright 사용

```python
from playwright.sync_api import sync_playwright
import time

def scrape_dynamic_page(url, wait_selector):
    """동적 웹페이지 크롤링 (JavaScript 렌더링)"""

    with sync_playwright() as p:
        # 브라우저 실행
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        # 페이지 이동
        page.goto(url)

        # 콘텐츠 로딩 대기
        page.wait_for_selector(wait_selector)

        # 스크롤 다운 (무한 스크롤 대응)
        for _ in range(5):
            page.evaluate('window.scrollTo(0, document.body.scrollHeight)')
            time.sleep(1)

        # HTML 추출
        html = page.content()

        browser.close()

        return html

# 사용 예시
html = scrape_dynamic_page(
    'https://example.com/dynamic',
    wait_selector='.result-list'
)

soup = BeautifulSoup(html, 'html.parser')
```

### Step 4: 네이버 검색 결과 크롤링

실전: 네이버에서 "인력파견업체" 검색 결과 수집

```python
from playwright.sync_api import sync_playwright
from bs4 import BeautifulSoup
import pandas as pd

def crawl_naver_search(keyword, pages=3):
    """네이버 검색 결과 크롤링"""

    results = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        page = browser.new_page()

        for page_num in range(1, pages + 1):
            # 네이버 검색 URL
            start = (page_num - 1) * 10 + 1
            url = f'https://search.naver.com/search.naver?query={keyword}&start={start}'

            page.goto(url)
            page.wait_for_selector('.total_wrap')

            # HTML 파싱
            html = page.content()
            soup = BeautifulSoup(html, 'html.parser')

            # 검색 결과 추출
            items = soup.select('.total_wrap')

            for item in items:
                try:
                    data = {
                        '업체명': item.select_one('.link_tit').text.strip(),
                        '주소': item.select_one('.addr').text.strip() if item.select_one('.addr') else '',
                        '전화번호': item.select_one('.tel').text.strip() if item.select_one('.tel') else '',
                        '설명': item.select_one('.total_txt').text.strip() if item.select_one('.total_txt') else ''
                    }
                    results.append(data)
                except:
                    continue

            print(f'{page_num}페이지 크롤링 완료')
            time.sleep(2)  # 서버 부담 줄이기

        browser.close()

    # 데이터프레임으로 변환
    df = pd.DataFrame(results)
    return df

# 실행
df = crawl_naver_search('인력파견업체', pages=3)
df.to_excel('인력파견업체_리스트.xlsx', index=False)
print(f'총 {len(df)}개 업체 수집 완료!')
```

### Step 5: 요금제 자동 업데이트

경쟁사 요금제를 크롤링해서 내 웹페이지에 자동 반영

```python
import json
from datetime import datetime

def scrape_pricing(competitor_url):
    """경쟁사 요금제 크롤링"""

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(competitor_url)

        # 요금제 섹션 대기
        page.wait_for_selector('.pricing-card')

        html = page.content()
        soup = BeautifulSoup(html, 'html.parser')

        pricing_data = []

        # 각 요금제 카드 파싱
        cards = soup.select('.pricing-card')
        for card in cards:
            plan = {
                '플랜명': card.select_one('.plan-name').text.strip(),
                '가격': card.select_one('.price').text.strip(),
                '특징': [li.text.strip() for li in card.select('.features li')],
                '수집일': datetime.now().strftime('%Y-%m-%d %H:%M')
            }
            pricing_data.append(plan)

        browser.close()

        return pricing_data

def update_website_pricing(pricing_data, output_file='pricing.json'):
    """웹사이트 요금제 데이터 업데이트"""

    # JSON으로 저장 (프론트엔드에서 자동 로드)
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(pricing_data, f, ensure_ascii=False, indent=2)

    print(f'{output_file}에 요금제 업데이트 완료!')

# 사용 예시
competitor_url = 'https://competitor.com/pricing'
pricing = scrape_pricing(competitor_url)
update_website_pricing(pricing)

# 프론트엔드에서 사용
# fetch('/pricing.json')
#   .then(res => res.json())
#   .then(data => renderPricing(data))
```

### Step 6: 자동화 스케줄링

크론잡 또는 GitHub Actions로 주기적 실행

```python
# scheduler.py
import schedule
import time

def daily_scraping_job():
    """매일 실행할 크롤링 작업"""
    print(f'크롤링 시작: {datetime.now()}')

    # 경쟁사 요금제 업데이트
    pricing = scrape_pricing('https://competitor.com/pricing')
    update_website_pricing(pricing)

    # 네이버 업체 리스트 업데이트
    df = crawl_naver_search('인력파견업체', pages=5)
    df.to_excel(f'업체리스트_{datetime.now():%Y%m%d}.xlsx', index=False)

    print('크롤링 완료!')

# 매일 오전 9시 실행
schedule.every().day.at("09:00").do(daily_scraping_job)

# 매시간 실행 (가격 모니터링)
schedule.every().hour.do(lambda: scrape_pricing('https://competitor.com/pricing'))

# 스케줄러 실행
while True:
    schedule.run_pending()
    time.sleep(60)
```

## 실전 예시

### Example 1: 네이버 지역 업체 리스트

```python
def crawl_naver_place(keyword, location='서울'):
    """네이버 지도 업체 검색"""

    url = f'https://map.naver.com/v5/search/{keyword} {location}'

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        page = browser.new_page()
        page.goto(url)

        # 검색 결과 로딩 대기
        page.wait_for_selector('.search_item')

        # 스크롤하여 모든 결과 로드
        for i in range(10):
            page.evaluate('document.querySelector(".search_list").scrollTop += 1000')
            time.sleep(0.5)

        # 결과 추출
        items = page.query_selector_all('.search_item')

        results = []
        for item in items:
            try:
                name = item.query_selector('.name').inner_text()
                category = item.query_selector('.category').inner_text()
                address = item.query_selector('.addr').inner_text()
                phone = item.query_selector('.tel')
                phone_text = phone.inner_text() if phone else ''

                results.append({
                    '업체명': name,
                    '업종': category,
                    '주소': address,
                    '전화': phone_text
                })
            except:
                continue

        browser.close()

    return pd.DataFrame(results)

# 실행
df = crawl_naver_place('인력파견', '서울')
df.to_excel('서울_인력파견업체.xlsx', index=False)
```

### Example 2: 쇼핑몰 가격 비교

```python
def compare_prices(product_name, sites):
    """여러 쇼핑몰 가격 비교"""

    price_data = []

    for site_name, site_config in sites.items():
        try:
            with sync_playwright() as p:
                browser = p.chromium.launch(headless=True)
                page = browser.new_page()

                # 검색
                search_url = site_config['search_url'].format(query=product_name)
                page.goto(search_url)
                page.wait_for_selector(site_config['item_selector'])

                # 첫 번째 상품 가격
                price_elem = page.query_selector(site_config['price_selector'])
                price = price_elem.inner_text() if price_elem else 'N/A'

                price_data.append({
                    '쇼핑몰': site_name,
                    '상품명': product_name,
                    '가격': price,
                    '수집시간': datetime.now()
                })

                browser.close()
        except Exception as e:
            print(f'{site_name} 크롤링 실패: {e}')

    return pd.DataFrame(price_data)

# 설정
sites = {
    '쿠팡': {
        'search_url': 'https://www.coupang.com/np/search?q={query}',
        'item_selector': '.search-product',
        'price_selector': '.price-value'
    },
    '11번가': {
        'search_url': 'https://search.11st.co.kr/Search.tmall?kwd={query}',
        'item_selector': '.c_card',
        'price_selector': '.price_num'
    }
}

# 실행
df = compare_prices('아이폰 15', sites)
print(df)
```

### Example 3: 부동산 매물 모니터링

```python
def monitor_real_estate(area, min_price, max_price):
    """부동산 매물 자동 알림"""

    url = f'https://부동산사이트.com/search?area={area}&min={min_price}&max={max_price}'

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url)

        page.wait_for_selector('.property-item')
        html = page.content()
        soup = BeautifulSoup(html, 'html.parser')

        properties = []
        items = soup.select('.property-item')

        for item in items:
            prop = {
                '제목': item.select_one('.title').text.strip(),
                '가격': item.select_one('.price').text.strip(),
                '면적': item.select_one('.area').text.strip(),
                '링크': item.select_one('a')['href']
            }
            properties.append(prop)

        browser.close()

    # 새 매물이 있으면 알림
    if properties:
        send_notification(f'{len(properties)}개 새 매물 발견!')

    return properties
```

## 핵심 개념

- **정적 크롤링**: HTML이 서버에서 완성되어 오는 페이지 (requests + BeautifulSoup)
- **동적 크롤링**: JavaScript로 렌더링되는 페이지 (Playwright, Selenium)
- **셀렉터**: CSS 선택자로 원하는 요소 찾기 (`.class`, `#id`, `tag`)
- **Rate Limiting**: 서버 부담을 줄이기 위한 요청 간격 조절
- **User-Agent**: 브라우저인 척 하기 위한 헤더 설정
- **robots.txt**: 크롤링 허용 정책 확인

## 주의사항

### ⚠️ 법적/윤리적 주의

```python
# 1. robots.txt 확인
# https://example.com/robots.txt

# 2. 이용약관 확인
# 크롤링 금지 명시 여부 체크

# 3. 적절한 간격
time.sleep(2)  # 요청 사이 2초 대기

# 4. User-Agent 명시
headers = {
    'User-Agent': 'MyBot/1.0 (contact@example.com)'
}

# 5. 과도한 요청 금지
# 초당 1-2회 이하 권장
```

### 🚫 절대 하지 말아야 할 것

- 개인정보 무단 수집
- 저작권 있는 콘텐츠 무단 복제
- DDoS 수준의 과도한 요청
- 로그인 필요한 데이터 무단 접근
- 명시적 크롤링 금지 사이트 크롤링

## 베스트 프랙티스

1. **점진적 개발**: 작은 샘플부터 테스트
2. **에러 처리**: try-except로 안정성 확보
3. **로깅**: 크롤링 과정 기록
4. **백업**: 수집 데이터 정기 백업
5. **모니터링**: 크롤러 정상 작동 확인
6. **업데이트 대응**: 사이트 구조 변경 시 수정

## 🔒 보안 감지 회피 방법

### 문제: 크롤링 봇 감지

많은 사이트가 크롤러를 감지하고 차단해요:

```python
# ❌ 감지되는 코드
from selenium import webdriver
driver = webdriver.Chrome()
# → "webdriver" 속성이 노출되어 봇으로 감지됨
```

**감지 방법:**
- WebDriver 속성 체크 (`navigator.webdriver`)
- Headless 모드 탐지
- User-Agent 분석
- 마우스/키보드 패턴 분석
- IP 추적

---

### ✅ 해결책 1: undetected-chromedriver (Selenium 감지 회피)

```python
import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
import time

def scrape_undetected(url):
    """감지 회피 크롬 드라이버"""

    # undetected-chromedriver 사용
    options = uc.ChromeOptions()
    options.add_argument('--disable-blink-features=AutomationControlled')

    driver = uc.Chrome(options=options)

    try:
        driver.get(url)
        time.sleep(2)

        # 데이터 추출
        content = driver.find_element(By.TAG_NAME, 'body').text

        return content
    finally:
        driver.quit()

# 설치: pip install undetected-chromedriver
```

---

### ✅ 해결책 2: Playwright Stealth (더 강력)

```python
from playwright.sync_api import sync_playwright
from playwright_stealth import stealth_sync

def scrape_with_stealth(url):
    """Playwright + Stealth로 감지 회피"""

    with sync_playwright() as p:
        # Stealth 모드 브라우저
        browser = p.chromium.launch(
            headless=True,
            args=['--disable-blink-features=AutomationControlled']
        )

        context = browser.new_context(
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            viewport={'width': 1920, 'height': 1080},
            locale='ko-KR',
            timezone_id='Asia/Seoul'
        )

        page = context.new_page()

        # Stealth 적용
        stealth_sync(page)

        page.goto(url)
        page.wait_for_load_state('networkidle')

        content = page.content()

        browser.close()

        return content

# 설치: pip install playwright-stealth
```

---

### ✅ 해결책 3: 순수 HTTP 요청 (가장 안전)

JavaScript가 필요없는 사이트는 이게 최고:

```python
import requests
from fake_useragent import UserAgent
import random
import time

def scrape_http_safe(url):
    """순수 HTTP 요청 (감지 거의 불가능)"""

    # 랜덤 User-Agent
    ua = UserAgent()

    headers = {
        'User-Agent': ua.random,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'DNT': '1',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Cache-Control': 'max-age=0',
    }

    # 세션 사용 (쿠키 유지)
    session = requests.Session()

    # 랜덤 딜레이
    time.sleep(random.uniform(1, 3))

    response = session.get(url, headers=headers, timeout=10)
    response.raise_for_status()

    return response.text

# 설치: pip install fake-useragent
```

---

### ✅ 해결책 4: 프록시 로테이션

IP 차단 방지:

```python
import requests
from itertools import cycle

def scrape_with_proxy_rotation(urls, proxies):
    """프록시 돌려가며 크롤링"""

    proxy_pool = cycle(proxies)

    results = []

    for url in urls:
        proxy = next(proxy_pool)

        try:
            response = requests.get(
                url,
                proxies={'http': proxy, 'https': proxy},
                timeout=10
            )

            results.append(response.text)
            print(f'✅ {url} 크롤링 성공 (프록시: {proxy})')

        except Exception as e:
            print(f'❌ {url} 실패: {e}')
            continue

        time.sleep(random.uniform(2, 5))

    return results

# 무료 프록시 리스트 (예시)
proxies = [
    'http://123.45.67.89:8080',
    'http://98.76.54.32:3128',
    # ... 더 추가
]
```

---

### ✅ 해결책 5: Claude Code + Playwright MCP

**가장 추천! Claude가 직접 브라우저 조작**

```typescript
// Claude Code에서 실행 가능
// Playwright MCP 사용

"네이버에서 '인력파견업체' 검색 결과 크롤링해줘"

// Claude가 자동으로:
// 1. Playwright MCP 호출
// 2. 브라우저 실행 (감지 회피 자동)
// 3. 데이터 추출
// 4. 정리해서 반환
```

---

### 🎯 감지 회피 베스트 프랙티스

```python
# ✅ 종합 안전 크롤링 템플릿

import undetected_chromedriver as uc
from fake_useragent import UserAgent
import random
import time

def safe_scraping_template(url):
    """보안 감지 회피 종합 템플릿"""

    # 1. User-Agent 랜덤화
    ua = UserAgent()

    # 2. undetected-chromedriver 사용
    options = uc.ChromeOptions()
    options.add_argument(f'user-agent={ua.random}')
    options.add_argument('--disable-blink-features=AutomationControlled')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--no-sandbox')

    # 3. 윈도우 크기 랜덤화
    options.add_argument(f'--window-size={random.randint(1200, 1920)},{random.randint(800, 1080)}')

    driver = uc.Chrome(options=options)

    try:
        # 4. 페이지 로드 전 대기
        time.sleep(random.uniform(1, 3))

        driver.get(url)

        # 5. 사람처럼 행동
        # 스크롤
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight/2);")
        time.sleep(random.uniform(0.5, 1.5))

        driver.execute_script("window.scrollTo(0, 0);")
        time.sleep(random.uniform(0.5, 1.5))

        # 6. 마우스 무브먼트 시뮬레이션
        from selenium.webdriver.common.action_chains import ActionChains
        actions = ActionChains(driver)

        # 랜덤 위치로 마우스 이동
        element = driver.find_element('tag name', 'body')
        actions.move_to_element_with_offset(
            element,
            random.randint(0, 100),
            random.randint(0, 100)
        ).perform()

        # 7. 데이터 추출
        content = driver.page_source

        return content

    finally:
        # 8. 정상 종료
        time.sleep(random.uniform(0.5, 1))
        driver.quit()
```

---

## 🛡️ 도구별 보안 감지 위험도

| 도구 | 감지 위험도 | 추천도 | 비고 |
|------|-----------|--------|------|
| **requests + BS4** | ⭐ 매우 낮음 | ⭐⭐⭐⭐⭐ | HTTP만 사용, 가장 안전 |
| **Playwright (일반)** | ⭐⭐ 낮음 | ⭐⭐⭐⭐ | 현대적, 감지 적음 |
| **Playwright + Stealth** | ⭐ 매우 낮음 | ⭐⭐⭐⭐⭐ | 강력 추천! |
| **undetected-chromedriver** | ⭐⭐ 낮음 | ⭐⭐⭐⭐ | Selenium 대체재 |
| **Selenium (기본)** | ⭐⭐⭐⭐⭐ 매우 높음 | ⭐ | 피하세요 |
| **Claude + Playwright MCP** | ⭐ 매우 낮음 | ⭐⭐⭐⭐⭐ | 자동 최적화 |

---

## 📊 상황별 추천 도구

### 정적 페이지 (네이버 검색 결과)
```
✅ requests + BeautifulSoup
→ 가장 안전, 빠름, 감지 불가능
```

### 동적 페이지 (무한 스크롤)
```
✅ Playwright + Stealth
→ 감지 회피 + 강력한 기능
```

### 까다로운 사이트 (Cloudflare, reCAPTCHA)
```
✅ undetected-chromedriver
OR
✅ Claude Code + Playwright MCP
→ 자동 감지 회피
```

### 대규모 크롤링
```
✅ Scrapy + 프록시 로테이션
→ 속도 + 안정성
```

## 관련 리소스

- [BeautifulSoup 문서](https://www.crummy.com/software/BeautifulSoup/bs4/doc/)
- [Playwright Python](https://playwright.dev/python/)
- [Selenium 문서](https://selenium-python.readthedocs.io/)
- [Scrapy 튜토리얼](https://docs.scrapy.org/en/latest/intro/tutorial.html)

## 태그

#웹스크래핑 #크롤링 #데이터수집 #자동화파싱 #경쟁사분석 #가격모니터링 #BeautifulSoup #Playwright #Selenium #웹자동화 #데이터추출 #파이썬
