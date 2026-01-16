# Hotwire Native 베스트 프랙티스

## 1. 성능 최적화

### 1.1 Turbo Frame 최적화

```erb
<%# 좋은 예: Lazy Loading으로 초기 로드 최소화 %>
<%= turbo_frame_tag "heavy_content", src: heavy_content_path, loading: :lazy do %>
  <div class="skeleton-loader">Loading...</div>
<% end %>

<%# 나쁜 예: 모든 콘텐츠를 한 번에 로드 %>
<%= turbo_frame_tag "heavy_content" do %>
  <%= render @all_items %> <%# 수백 개의 아이템 %>
<% end %>
```

### 1.2 이미지 최적화

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def optimized_image_tag(source, options = {})
    # 네이티브 앱에서는 더 작은 이미지 제공
    if native_app?
      options[:width] ||= 400
      options[:quality] ||= 70
    end

    # WebP 지원
    if supports_webp?
      source = source.gsub(/\.(jpg|jpeg|png)$/, '.webp')
    end

    image_tag source, options
  end

  private

  def supports_webp?
    request.headers["Accept"]&.include?("image/webp")
  end
end
```

```erb
<%# 반응형 이미지 %>
<%= image_tag @product.image,
    srcset: {
      @product.image.variant(resize_to_limit: [400, 400]) => "400w",
      @product.image.variant(resize_to_limit: [800, 800]) => "800w"
    },
    sizes: native_app? ? "100vw" : "(max-width: 768px) 100vw, 50vw",
    loading: "lazy" %>
```

### 1.3 캐싱 전략

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :set_cache_headers

  private

  def set_cache_headers
    if native_app?
      # 네이티브 앱: 더 공격적인 캐싱
      response.headers["Cache-Control"] = "private, max-age=3600"
    else
      # 웹: 표준 캐싱
      response.headers["Cache-Control"] = "private, max-age=60"
    end
  end
end
```

```ruby
# Fragment 캐싱
<% cache [@post, native_app? ? "native" : "web"] do %>
  <%= render @post %>
<% end %>
```

### 1.4 JavaScript 번들 최적화

```ruby
# config/importmap.rb
# 네이티브 앱에서 불필요한 JS 제외
pin "application", preload: true

# 웹 전용 (네이티브에서 불필요)
pin "web_analytics", preload: false
pin "cookie_consent", preload: false
```

```erb
<%# app/views/layouts/application.html.erb %>
<%= javascript_importmap_tags %>

<% unless native_app? %>
  <%# 웹 전용 스크립트 %>
  <script type="module">
    import "web_analytics"
    import "cookie_consent"
  </script>
<% end %>
```

## 2. UX 최적화

### 2.1 네이티브 네비게이션 바

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :set_native_navigation

  private

  def set_native_navigation
    return unless native_app?

    # 네이티브 네비게이션 바 설정
    response.headers["X-Turbo-Native-Title"] = page_title
    response.headers["X-Turbo-Native-Back-Button"] = show_back_button?.to_s
  end

  def page_title
    content_for(:title) || t("#{controller_name}.#{action_name}.title", default: controller_name.titleize)
  end

  def show_back_button?
    action_name != "index"
  end
end
```

### 2.2 플랫폼별 UI 분기

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html lang="<%= I18n.locale %>" class="<%= platform_class %>">
<head>
  <%= render "shared/head" %>
</head>
<body class="<%= body_class %>">
  <% if native_app? %>
    <%# 네이티브: 심플한 레이아웃 %>
    <main class="native-container">
      <%= yield %>
    </main>
  <% else %>
    <%# 웹: 풀 레이아웃 %>
    <%= render "shared/header" %>
    <main class="web-container">
      <%= yield %>
    </main>
    <%= render "shared/footer" %>
  <% end %>
</body>
</html>
```

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def platform_class
    case
    when native_ios? then "platform-ios"
    when native_android? then "platform-android"
    else "platform-web"
    end
  end

  def body_class
    [
      controller_name,
      action_name,
      native_app? ? "native-app" : "web-app"
    ].join(" ")
  end
end
```

### 2.3 터치 최적화

```css
/* app/assets/stylesheets/native.css */

/* 터치 타겟 최소 44px */
.native-app .btn,
.native-app a,
.native-app button {
  min-height: 44px;
  min-width: 44px;
  padding: 12px 16px;
}

/* 터치 피드백 */
.native-app .touchable {
  -webkit-tap-highlight-color: rgba(0, 0, 0, 0.1);
}

.native-app .touchable:active {
  transform: scale(0.98);
  opacity: 0.9;
}

/* 스크롤 최적화 */
.native-app .scrollable {
  -webkit-overflow-scrolling: touch;
  overscroll-behavior: contain;
}

/* Safe Area 대응 */
.native-app .bottom-bar {
  padding-bottom: env(safe-area-inset-bottom);
}

.platform-ios .header {
  padding-top: env(safe-area-inset-top);
}
```

### 2.4 로딩 상태

```javascript
// app/javascript/controllers/loading_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "skeleton"]

  connect() {
    // Turbo 이벤트 리스닝
    document.addEventListener("turbo:before-fetch-request", this.showLoading.bind(this))
    document.addEventListener("turbo:before-fetch-response", this.hideLoading.bind(this))
    document.addEventListener("turbo:frame-missing", this.hideLoading.bind(this))
  }

  showLoading() {
    if (this.hasSkeletonTarget) {
      this.contentTarget.classList.add("hidden")
      this.skeletonTarget.classList.remove("hidden")
    }
  }

  hideLoading() {
    if (this.hasSkeletonTarget) {
      this.contentTarget.classList.remove("hidden")
      this.skeletonTarget.classList.add("hidden")
    }
  }
}
```

## 3. 오프라인 지원

### 3.1 Service Worker 기본 설정

```javascript
// app/javascript/service_worker.js
const CACHE_NAME = 'app-v1';
const OFFLINE_URL = '/offline';

const PRECACHE_URLS = [
  '/',
  '/offline',
  '/assets/application.css',
  '/assets/application.js'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(PRECACHE_URLS))
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request)
        .catch(() => caches.match(OFFLINE_URL))
    );
  } else {
    event.respondWith(
      caches.match(event.request)
        .then((response) => response || fetch(event.request))
    );
  }
});
```

### 3.2 오프라인 페이지

```erb
<%# app/views/pages/offline.html.erb %>
<div class="offline-page">
  <h1>You're offline</h1>
  <p>Please check your internet connection and try again.</p>

  <button onclick="window.location.reload()" class="btn btn-primary">
    Try Again
  </button>
</div>
```

### 3.3 네트워크 상태 감지

```javascript
// app/javascript/controllers/network_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator"]

  connect() {
    this.updateStatus()
    window.addEventListener("online", () => this.updateStatus())
    window.addEventListener("offline", () => this.updateStatus())
  }

  updateStatus() {
    if (navigator.onLine) {
      this.indicatorTarget.classList.add("hidden")
      // 오프라인 중 쌓인 요청 동기화
      this.syncPendingRequests()
    } else {
      this.indicatorTarget.classList.remove("hidden")
      this.indicatorTarget.textContent = "You're offline"
    }
  }

  syncPendingRequests() {
    const pending = JSON.parse(localStorage.getItem("pendingRequests") || "[]")
    pending.forEach((request) => {
      fetch(request.url, request.options)
        .then(() => this.removePendingRequest(request.id))
    })
  }

  removePendingRequest(id) {
    const pending = JSON.parse(localStorage.getItem("pendingRequests") || "[]")
    const updated = pending.filter((r) => r.id !== id)
    localStorage.setItem("pendingRequests", JSON.stringify(updated))
  }
}
```

## 4. 보안

### 4.1 CSRF 보호

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :verify_native_app_signature, if: :native_app?

  private

  def verify_native_app_signature
    # 네이티브 앱에서 보내는 서명 검증
    signature = request.headers["X-App-Signature"]
    timestamp = request.headers["X-App-Timestamp"]

    return if valid_signature?(signature, timestamp)

    render json: { error: "Invalid signature" }, status: :unauthorized
  end

  def valid_signature?(signature, timestamp)
    return false if signature.blank? || timestamp.blank?
    return false if Time.at(timestamp.to_i) < 5.minutes.ago

    expected = OpenSSL::HMAC.hexdigest(
      "SHA256",
      ENV["APP_SECRET_KEY"],
      "#{timestamp}:#{request.path}"
    )

    ActiveSupport::SecurityUtils.secure_compare(signature, expected)
  end
end
```

### 4.2 세션 보안

```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: "_app_session",
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax,
  expire_after: 2.weeks
```

### 4.3 입력 검증

```ruby
# app/controllers/api/base_controller.rb
class Api::BaseController < ApplicationController
  before_action :validate_content_type

  private

  def validate_content_type
    return if request.get? || request.delete?

    unless request.content_type&.include?("application/json")
      render json: { error: "Content-Type must be application/json" }, status: :unsupported_media_type
    end
  end
end
```

### 4.4 민감 데이터 보호

```swift
// iOS - Keychain 사용
import Security

class SecureStorage {
    static func save(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return status == errSecSuccess ? result as? Data : nil
    }
}
```

## 5. 디버깅

### 5.1 Rails 로깅

```ruby
# config/initializers/lograge.rb
Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    {
      user_agent: event.payload[:user_agent],
      native_app: event.payload[:native_app],
      app_version: event.payload[:app_version]
    }
  end
end
```

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :append_info_to_payload

  def append_info_to_payload(payload)
    super
    payload[:user_agent] = request.user_agent
    payload[:native_app] = native_app?
    payload[:app_version] = request.headers["X-App-Version"]
  end
end
```

### 5.2 네이티브 디버그 모드

```swift
// iOS Debug Configuration
#if DEBUG
Hotwire.config.debugLoggingEnabled = true

// WebView 디버깅
if #available(iOS 16.4, *) {
    webView.isInspectable = true
}
#endif
```

```kotlin
// Android Debug Configuration
if (BuildConfig.DEBUG) {
    Hotwire.config.debugLoggingEnabled = true
    WebView.setWebContentsDebuggingEnabled(true)
}
```

### 5.3 에러 추적

```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]

  config.before_send = lambda do |event, hint|
    # 네이티브 앱 정보 추가
    if hint[:request]
      user_agent = hint[:request].user_agent
      event.tags[:platform] = case user_agent
      when /Hotwire Native iOS/ then "ios"
      when /Hotwire Native Android/ then "android"
      else "web"
      end
    end
    event
  end
end
```

## 6. 테스트

### 6.1 시스템 테스트

```ruby
# test/system/native_app_test.rb
require "application_system_test_case"

class NativeAppTest < ApplicationSystemTestCase
  setup do
    # 네이티브 앱 User-Agent 시뮬레이션
    page.driver.browser.header("User-Agent", "Hotwire Native iOS/1.0")
  end

  test "shows native layout for native app" do
    visit root_path
    assert_no_selector ".web-header"
    assert_no_selector ".web-footer"
    assert_selector ".native-container"
  end

  test "shows modal for new action" do
    visit posts_path
    click_link "New Post"

    # 모달로 표시되어야 함
    assert_selector "[data-turbo-frame='modal']"
  end
end
```

### 6.2 API 테스트

```ruby
# test/controllers/api/posts_controller_test.rb
class Api::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headers = {
      "User-Agent" => "Hotwire Native iOS/1.0",
      "X-App-Version" => "1.0.0",
      "Content-Type" => "application/json"
    }
  end

  test "returns JSON for native app" do
    get api_posts_url, headers: @headers
    assert_response :success
    assert_equal "application/json", response.media_type
  end

  test "returns Turbo Stream for web" do
    get posts_url, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end
end
```

### 6.3 Bridge Component 테스트

```swift
// iOS XCTest
class CameraBridgeTests: XCTestCase {
    var bridge: CameraBridgeComponent!

    override func setUp() {
        bridge = CameraBridgeComponent()
    }

    func testCaptureMessageHandling() {
        let message = Message(
            id: "1",
            component: "camera",
            event: "capture",
            data: ["action": "capture", "maxSize": 1024, "quality": 0.8]
        )

        // 메시지 처리 테스트
        bridge.onReceive(message: message)

        // 응답 검증
        XCTAssertNotNil(bridge.lastReply)
    }
}
```

## 7. 체크리스트

### 성능
- [ ] Turbo Frame으로 부분 업데이트
- [ ] Lazy loading 적용
- [ ] 이미지 최적화 (WebP, srcset)
- [ ] 적절한 캐싱 전략
- [ ] JavaScript 번들 최소화

### UX
- [ ] 터치 타겟 44px 이상
- [ ] Safe Area 대응
- [ ] 로딩 상태 표시
- [ ] 플랫폼별 UI 최적화
- [ ] 오프라인 지원

### 보안
- [ ] CSRF 보호
- [ ] 세션 보안 설정
- [ ] 입력 검증
- [ ] HTTPS 필수
- [ ] 민감 데이터 암호화

### 테스트
- [ ] 시스템 테스트
- [ ] API 테스트
- [ ] Bridge Component 테스트
- [ ] 성능 테스트
- [ ] 보안 테스트
