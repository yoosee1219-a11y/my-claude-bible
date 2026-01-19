# Turbo Native 패턴

## 1. 내비게이션 패턴

### 1.1 Path Configuration

Rails 서버에서 네이티브 앱의 내비게이션 동작을 제어합니다.

```json
// public/turbo-native/path-configuration.json
{
  "settings": {
    "screenshots_enabled": true,
    "tabs": [
      { "title": "Home", "path": "/", "icon": "house" },
      { "title": "Search", "path": "/search", "icon": "magnifyingglass" },
      { "title": "Profile", "path": "/profile", "icon": "person" }
    ]
  },
  "rules": [
    {
      "patterns": ["/new$", "/edit$"],
      "properties": {
        "presentation": "modal"
      }
    },
    {
      "patterns": ["/login", "/signup"],
      "properties": {
        "presentation": "modal",
        "pull_to_refresh_enabled": false
      }
    },
    {
      "patterns": ["/settings"],
      "properties": {
        "presentation": "push",
        "title": "Settings"
      }
    }
  ]
}
```

### 1.2 Presentation 유형

| 유형 | 설명 | 사용 케이스 |
|------|------|-------------|
| `push` | 스택에 푸시 (기본값) | 일반 페이지 이동 |
| `modal` | 모달로 표시 | 생성/수정 폼 |
| `replace` | 현재 화면 대체 | 로그인 후 리디렉트 |
| `clearAll` | 스택 전체 클리어 | 로그아웃 |
| `none` | 화면 전환 없음 | API 호출만 |

### 1.3 iOS에서 Path Configuration 적용

```swift
// Navigator 설정
import HotwireNative

class Navigator {
    private let session = Session()

    init() {
        session.pathConfiguration.load(from: [
            PathConfigurationSource.server(URL(string: "https://your-app.com/turbo-native/path-configuration.json")!),
            PathConfigurationSource.file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!)
        ])
    }
}
```

### 1.4 Android에서 Path Configuration 적용

```kotlin
// res/raw/path_configuration.json 또는 서버에서 로드
class MainActivity : HotwireActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        Hotwire.loadPathConfiguration(
            context = this,
            location = PathConfiguration.Location(
                assetFilePath = "json/path_configuration.json",
                remoteFileUrl = "https://your-app.com/turbo-native/path-configuration.json"
            )
        )
    }
}
```

## 2. Turbo Frame 패턴

### 2.1 부분 업데이트

```erb
<%# app/views/posts/show.html.erb %>
<%= turbo_frame_tag "post_#{@post.id}" do %>
  <article>
    <h1><%= @post.title %></h1>
    <p><%= @post.content %></p>

    <%= link_to "Edit", edit_post_path(@post), data: { turbo_frame: "_self" } %>
  </article>
<% end %>

<%# 댓글 섹션 - 별도 프레임 %>
<%= turbo_frame_tag "comments", src: post_comments_path(@post) do %>
  <p>Loading comments...</p>
<% end %>
```

### 2.2 Lazy Loading 프레임

```erb
<%# app/views/dashboard/index.html.erb %>
<%= turbo_frame_tag "stats", src: dashboard_stats_path, loading: :lazy do %>
  <div class="loading-skeleton">Loading stats...</div>
<% end %>

<%= turbo_frame_tag "recent_activity", src: dashboard_activity_path, loading: :lazy do %>
  <div class="loading-skeleton">Loading activity...</div>
<% end %>
```

## 3. Turbo Stream 패턴

### 3.1 실시간 업데이트

```ruby
# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  def create
    @message = current_user.messages.build(message_params)

    if @message.save
      # 모든 구독자에게 실시간 전송
      Turbo::StreamsChannel.broadcast_append_to(
        "chat_#{@message.chat_id}",
        target: "messages",
        partial: "messages/message",
        locals: { message: @message }
      )

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path(@message.chat) }
      end
    end
  end
end
```

```erb
<%# app/views/messages/create.turbo_stream.erb %>
<%= turbo_stream.append "messages" do %>
  <%= render @message %>
<% end %>

<%= turbo_stream.replace "message_form" do %>
  <%= render "form", message: Message.new %>
<% end %>
```

### 3.2 네이티브 앱에서 WebSocket 연결

```erb
<%# app/views/chats/show.html.erb %>
<%= turbo_stream_from "chat_#{@chat.id}" %>

<div id="messages">
  <%= render @chat.messages %>
</div>

<%= render "messages/form", message: @chat.messages.build %>
```

## 4. Form 처리 패턴

### 4.1 모달 폼 제출

```erb
<%# app/views/posts/_form.html.erb %>
<%= form_with model: @post, data: { turbo_frame: "_top" } do |form| %>
  <div class="field">
    <%= form.label :title %>
    <%= form.text_field :title %>
  </div>

  <div class="field">
    <%= form.label :content %>
    <%= form.text_area :content %>
  </div>

  <div class="actions">
    <%= form.submit %>
    <%= link_to "Cancel", posts_path, data: { turbo_method: :get } %>
  </div>
<% end %>
```

### 4.2 성공/실패 처리

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to @post, notice: "Post created!"
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

## 5. 에러 처리 패턴

### 5.1 네트워크 에러 처리

```swift
// iOS
extension SceneDelegate: SessionDelegate {
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        if let turboError = error as? TurboError {
            switch turboError {
            case .networkFailure:
                showOfflineAlert()
            case .httpFailure(let statusCode):
                handleHTTPError(statusCode)
            case .pageLoadFailure:
                showPageLoadError()
            }
        }
    }

    private func handleHTTPError(_ statusCode: Int) {
        switch statusCode {
        case 401:
            presentLoginScreen()
        case 404:
            showNotFoundError()
        case 500...599:
            showServerError()
        default:
            showGenericError()
        }
    }
}
```

### 5.2 오프라인 지원

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def not_found
    respond_to do |format|
      format.html { render "errors/not_found", status: :not_found }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("content", partial: "errors/not_found") }
    end
  end
end
```

## 6. 인증 패턴

### 6.1 세션 기반 인증

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def create
    user = User.authenticate(params[:email], params[:password])

    if user
      session[:user_id] = user.id

      respond_to do |format|
        format.html { redirect_to root_path }
        format.turbo_stream do
          render turbo_stream: turbo_stream.action(:advance, root_url)
        end
      end
    else
      flash.now[:alert] = "Invalid credentials"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session

    respond_to do |format|
      format.html { redirect_to login_path }
      format.turbo_stream do
        render turbo_stream: turbo_stream.action(:clearAll, login_url)
      end
    end
  end
end
```

### 6.2 네이티브 앱 세션 동기화

```swift
// iOS - 쿠키 공유 설정
class SessionConfigurator {
    static func configureSession() {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        configuration.httpCookieStorage = .shared

        // WKWebView와 URLSession 쿠키 동기화
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always
    }
}
```

## 7. 딥 링크 패턴

### 7.1 Universal Links (iOS)

```json
// apple-app-site-association (서버)
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAM_ID.com.yourapp.bundle",
      "paths": ["*"]
    }]
  }
}
```

```swift
// SceneDelegate.swift
func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else { return }

    navigator.route(url)
}
```

### 7.2 App Links (Android)

```xml
<!-- AndroidManifest.xml -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="https"
        android:host="your-app.com" />
</intent-filter>
```
