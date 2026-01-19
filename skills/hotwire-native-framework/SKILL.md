---
name: hotwire-native-framework
description: HotwireNative, TurboNative, RailsMobile, BridgeComponent, iOS앱개발, Android앱개발, 웹앱네이티브변환, 1인창업앱, 앱개발비절감
version: "1.0.0"
---

# Hotwire Native Framework

웹앱 하나로 iOS/Android 네이티브 앱을 만드는 Hotwire Native 프레임워크 가이드

## 개요

Hotwire Native는 Rails 웹 애플리케이션을 iOS/Android 네이티브 앱으로 래핑하여 단일 코드베이스로 3개 플랫폼(Web, iOS, Android)을 커버하는 기술입니다.

### 핵심 장점
- **단일 코드베이스**: Rails 웹앱 하나로 모든 플랫폼 지원
- **네이티브 UX**: Bridge Component로 네이티브 기능 완벽 연동
- **빠른 개발**: 웹 기술만으로 앱 개발 가능
- **비용 절감**: iOS/Android 개발자 없이 앱 출시 가능

## 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                    Rails Application                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │   Turbo     │  │  Stimulus   │  │ Bridge          │  │
│  │   Frames    │  │  Controllers│  │ Components (JS) │  │
│  └─────────────┘  └─────────────┘  └─────────────────┘  │
└───────────────────────┬─────────────────────────────────┘
                        │ WebView + Bridge
    ┌───────────────────┼───────────────────┐
    │                   │                   │
┌───▼───┐          ┌────▼────┐         ┌────▼────┐
│  Web  │          │   iOS   │         │ Android │
│Browser│          │  Native │         │ Native  │
└───────┘          └─────────┘         └─────────┘
```

## 필수 구성 요소

### 1. Rails 서버 (웹)
- Rails 7+ with Turbo & Stimulus
- `turbo-rails` gem
- `stimulus-rails` gem
- `hotwire-native-rails` gem (Bridge Component 지원)

### 2. iOS 앱
- Swift + UIKit 또는 SwiftUI
- `hotwire-native-ios` 패키지 (SPM)
- Xcode 15+

### 3. Android 앱
- Kotlin + Jetpack
- `hotwire-native-android` 라이브러리
- Android Studio

## 빠른 시작

### 1. Rails 프로젝트 설정

```ruby
# Gemfile
gem "turbo-rails"
gem "stimulus-rails"
gem "hotwire-native-rails"
```

```bash
bundle install
rails hotwire:install
rails stimulus:install
```

### 2. User-Agent 기반 분기

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  helper_method :native_app?

  private

  def native_app?
    request.user_agent.to_s.include?("Hotwire Native")
  end
end
```

```erb
<%# app/views/layouts/application.html.erb %>
<% if native_app? %>
  <%# 네이티브 앱 전용 레이아웃 %>
  <%= yield %>
<% else %>
  <%# 웹 브라우저용 레이아웃 (헤더, 푸터 포함) %>
  <%= render "shared/header" %>
  <%= yield %>
  <%= render "shared/footer" %>
<% end %>
```

### 3. iOS 프로젝트 기본 설정

```swift
// AppDelegate.swift
import HotwireNative

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Hotwire.config.debugLoggingEnabled = true
        Hotwire.config.userAgent = "Hotwire Native iOS"
        return true
    }
}
```

```swift
// SceneDelegate.swift
import HotwireNative

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let navigator = Navigator()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = navigator.rootViewController
        window?.makeKeyAndVisible()

        navigator.route(URL(string: "https://your-rails-app.com")!)
    }
}
```

### 4. Android 프로젝트 기본 설정

```kotlin
// MainActivity.kt
import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.NavigatorConfiguration

class MainActivity : HotwireActivity() {
    override val navigatorConfigurations = listOf(
        NavigatorConfiguration(
            name = "main",
            startLocation = "https://your-rails-app.com",
            navigatorHostId = R.id.navigator_host
        )
    )
}
```

## 참조 문서

자세한 내용은 references 폴더의 문서를 참조하세요:

- **01-turbo-native-patterns.md**: Turbo Native 내비게이션 패턴
- **02-bridge-components.md**: 네이티브 기능 연동 (카메라, 푸시 등)
- **03-deployment-guide.md**: iOS/Android 스토어 배포 가이드
- **04-best-practices.md**: 성능 최적화 및 보안 가이드

## 관련 에이전트

프로젝트 자동 생성이 필요하면 `hotwire-native` 에이전트를 사용하세요:
```
"Hotwire Native로 새 프로젝트 만들어줘"
```
