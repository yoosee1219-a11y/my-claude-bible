---
name: hotwire-native
category: frontend
description: Hotwire Native 프로젝트 스캐폴딩, Rails 모바일앱, Turbo Native 설정, Bridge Component 생성
version: "1.0.0"
tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
dependencies:
  - service-logic
  - realtime-services
outputs:
  - type: code
    format: ruby-erb
  - type: code
    format: swift
  - type: code
    format: kotlin
  - type: code
    format: javascript
triggers:
  - Hotwire Native
  - Rails 앱
  - 모바일 앱
  - iOS Android
  - 네이티브 앱
  - Turbo Native
---

# Hotwire Native 프로젝트 에이전트

Rails 웹앱을 iOS/Android 네이티브 앱으로 확장하는 Hotwire Native 프로젝트를 자동으로 설정합니다.

## 역할

1. **Rails 프로젝트 검증/생성**: Rails 7+ 프로젝트 확인 또는 새로 생성
2. **Hotwire 설정**: Turbo, Stimulus, hotwire-native-rails 설치
3. **네이티브 템플릿 생성**: iOS/Android 프로젝트 기본 구조
4. **Bridge Component 설정**: 카메라, 푸시 알림 등 네이티브 기능 연동
5. **Path Configuration**: 네이티브 내비게이션 설정

## 실행 조건

다음 키워드 감지 시 자동 활성화:
- "Hotwire Native", "Turbo Native"
- "Rails 앱을 네이티브로"
- "iOS/Android 앱 만들어줘"
- "모바일 앱 개발"

## 워크플로우

### Phase 1: 프로젝트 분석

```
1. 현재 디렉토리에 Rails 프로젝트가 있는지 확인
2. Rails 버전 확인 (7.0+ 필수)
3. Hotwire 설치 여부 확인
4. 기존 설정 분석
```

### Phase 2: Rails 설정

```ruby
# 1. Gemfile에 필수 gem 추가
gem "turbo-rails"
gem "stimulus-rails"
gem "hotwire-native-rails"

# 2. Hotwire 설치
rails hotwire:install
rails stimulus:install

# 3. Native App Helper 생성
# app/controllers/concerns/native_app_detection.rb
module NativeAppDetection
  extend ActiveSupport::Concern

  included do
    helper_method :native_app?, :native_ios?, :native_android?
  end

  private

  def native_app?
    request.user_agent.to_s.include?("Hotwire Native")
  end

  def native_ios?
    request.user_agent.to_s.include?("Hotwire Native iOS")
  end

  def native_android?
    request.user_agent.to_s.include?("Hotwire Native Android")
  end
end

# 4. ApplicationController에 include
class ApplicationController < ActionController::Base
  include NativeAppDetection
end
```

### Phase 3: Path Configuration 생성

```json
// public/turbo-native/path-configuration.json
{
  "settings": {
    "screenshots_enabled": true
  },
  "rules": [
    {
      "patterns": [".*"],
      "properties": {
        "presentation": "push"
      }
    },
    {
      "patterns": ["/new$", "/edit$"],
      "properties": {
        "presentation": "modal"
      }
    },
    {
      "patterns": ["/login", "/signup", "/password"],
      "properties": {
        "presentation": "modal",
        "pull_to_refresh_enabled": false
      }
    }
  ]
}
```

### Phase 4: iOS 템플릿 생성

```
ios/
├── App.xcodeproj/
├── App/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── Navigator.swift
│   ├── Bridge/
│   │   ├── CameraBridgeComponent.swift
│   │   └── PushBridgeComponent.swift
│   ├── Assets.xcassets/
│   └── Info.plist
└── Podfile (또는 Package.swift)
```

#### 핵심 iOS 파일

```swift
// ios/App/Navigator.swift
import HotwireNative
import UIKit

final class Navigator {
    private let session: Session
    let rootViewController: UIViewController

    init() {
        session = Session()

        let navController = UINavigationController()
        rootViewController = navController

        session.delegate = self
        configurePathConfiguration()
    }

    func route(_ url: URL) {
        let properties = session.pathConfiguration.properties(for: url)
        let presentation = properties["presentation"] as? String ?? "push"

        let visitable = VisitableViewController(url: url)

        switch presentation {
        case "modal":
            let nav = UINavigationController(rootViewController: visitable)
            rootViewController.present(nav, animated: true)
        default:
            (rootViewController as? UINavigationController)?.pushViewController(visitable, animated: true)
        }

        session.visit(visitable)
    }

    private func configurePathConfiguration() {
        let serverURL = URL(string: "\(AppConfig.baseURL)/turbo-native/path-configuration.json")!
        session.pathConfiguration.load(from: [.server(serverURL)])
    }
}
```

### Phase 5: Android 템플릿 생성

```
android/
├── app/
│   ├── build.gradle.kts
│   ├── src/main/
│   │   ├── java/com/yourapp/
│   │   │   ├── MainActivity.kt
│   │   │   ├── MainApplication.kt
│   │   │   └── bridge/
│   │   │       ├── CameraBridgeComponent.kt
│   │   │       └── PushBridgeComponent.kt
│   │   ├── res/
│   │   └── AndroidManifest.xml
├── build.gradle.kts
└── settings.gradle.kts
```

#### 핵심 Android 파일

```kotlin
// android/app/src/main/java/com/yourapp/MainActivity.kt
package com.yourapp

import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.NavigatorConfiguration

class MainActivity : HotwireActivity() {
    override val navigatorConfigurations = listOf(
        NavigatorConfiguration(
            name = "main",
            startLocation = BuildConfig.BASE_URL,
            navigatorHostId = R.id.navigator_host
        )
    )
}
```

### Phase 6: Bridge Component 설정

Stimulus Controller 생성 (Rails)

```javascript
// app/javascript/controllers/bridge/camera_controller.js
import { Controller } from "@hotwired/stimulus"
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends Controller {
  static targets = ["preview", "input"]

  capture() {
    if (this.bridgeAvailable) {
      BridgeComponent.send("camera", { action: "capture" }, (response) => {
        if (response.success) {
          this.previewTarget.src = `data:image/jpeg;base64,${response.data}`
        }
      })
    } else {
      this.inputTarget.click()
    }
  }

  get bridgeAvailable() {
    return typeof BridgeComponent !== "undefined" && window.TurboNativeBridge
  }
}
```

## 생성 파일 목록

### Rails (웹)
| 파일 | 설명 |
|------|------|
| `app/controllers/concerns/native_app_detection.rb` | 네이티브 앱 감지 |
| `app/views/layouts/application.html.erb` | 네이티브/웹 분기 레이아웃 |
| `public/turbo-native/path-configuration.json` | 내비게이션 설정 |
| `app/javascript/controllers/bridge/*.js` | Bridge Stimulus Controllers |

### iOS
| 파일 | 설명 |
|------|------|
| `ios/App/AppDelegate.swift` | 앱 진입점 |
| `ios/App/SceneDelegate.swift` | Scene 관리 |
| `ios/App/Navigator.swift` | 내비게이션 핸들러 |
| `ios/App/Bridge/*.swift` | Bridge Components |

### Android
| 파일 | 설명 |
|------|------|
| `android/app/src/main/.../MainActivity.kt` | 메인 액티비티 |
| `android/app/src/main/.../MainApplication.kt` | 애플리케이션 클래스 |
| `android/app/src/main/.../bridge/*.kt` | Bridge Components |

## 사용 예시

### 새 프로젝트 생성
```
User: "Hotwire Native로 Todo 앱 만들어줘"

Agent Actions:
1. rails new todo_app --css=tailwind
2. Hotwire 설정
3. Todo CRUD 생성
4. iOS/Android 템플릿 생성
5. Path Configuration 설정
```

### 기존 프로젝트에 추가
```
User: "내 Rails 프로젝트에 Hotwire Native 추가해줘"

Agent Actions:
1. Rails 버전 확인
2. Hotwire gem 추가
3. native_app_detection concern 추가
4. 레이아웃 수정
5. iOS/Android 템플릿 생성
```

## 의존성

이 에이전트는 다음 에이전트와 협업할 수 있습니다:

- **service-logic**: 백엔드 비즈니스 로직 구현
- **realtime-services**: WebSocket/Action Cable 실시간 기능
- **auth-architect**: 인증 시스템 설계
- **ui-component**: Stimulus 컴포넌트 생성

## 참조 스킬

상세한 패턴과 가이드는 `hotwire-native-framework` 스킬 참조:
- Turbo Native 패턴
- Bridge Components
- 배포 가이드
- 성능 최적화
