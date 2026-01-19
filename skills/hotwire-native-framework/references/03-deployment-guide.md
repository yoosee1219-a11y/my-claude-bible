# iOS/Android 배포 가이드

## 1. Rails 서버 배포 준비

### 1.1 프로덕션 설정

```ruby
# config/environments/production.rb
Rails.application.configure do
  # HTTPS 강제
  config.force_ssl = true

  # Asset CDN
  config.asset_host = ENV["ASSET_HOST"]

  # Action Cable (실시간 기능용)
  config.action_cable.url = "wss://#{ENV['DOMAIN']}/cable"
  config.action_cable.allowed_request_origins = [
    /https:\/\/#{ENV['DOMAIN']}/,
    /hotwire-native:\/\//  # 네이티브 앱
  ]

  # 캐시 설정
  config.cache_store = :redis_cache_store, {
    url: ENV["REDIS_URL"],
    expires_in: 1.hour
  }
end
```

### 1.2 Path Configuration 서빙

```ruby
# config/routes.rb
Rails.application.routes.draw do
  get "/turbo-native/path-configuration", to: "turbo_native#path_configuration"
end
```

```ruby
# app/controllers/turbo_native_controller.rb
class TurboNativeController < ApplicationController
  def path_configuration
    config = Rails.cache.fetch("path_configuration", expires_in: 1.hour) do
      File.read(Rails.root.join("public/turbo-native/path-configuration.json"))
    end

    render json: config
  end
end
```

### 1.3 API 버전 관리

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :check_app_version

  private

  def check_app_version
    return unless native_app?

    app_version = request.headers["X-App-Version"]
    min_version = ENV["MIN_APP_VERSION"] || "1.0.0"

    if app_version && Gem::Version.new(app_version) < Gem::Version.new(min_version)
      render json: {
        error: "update_required",
        message: "Please update your app to continue",
        store_url: native_ios? ? ENV["IOS_STORE_URL"] : ENV["ANDROID_STORE_URL"]
      }, status: :upgrade_required
    end
  end

  def native_ios?
    request.user_agent.to_s.include?("Hotwire Native iOS")
  end

  def native_android?
    request.user_agent.to_s.include?("Hotwire Native Android")
  end
end
```

## 2. iOS 앱 배포

### 2.1 프로젝트 설정

```swift
// Info.plist 필수 항목
/*
<key>ITSAppUsesNonExemptEncryption</key>
<false/>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
*/
```

### 2.2 App Store Connect 설정

1. **앱 아이콘**
   - 1024x1024 PNG (투명 배경 불가)
   - 모든 사이즈 자동 생성

2. **스크린샷**
   - iPhone 6.5" (1284 x 2778)
   - iPhone 5.5" (1242 x 2208)
   - iPad Pro 12.9" (2048 x 2732)

3. **프라이버시 설정**
   - 데이터 수집 유형 명시
   - 추적 여부 명시

### 2.3 빌드 및 배포 스크립트

```bash
#!/bin/bash
# scripts/deploy_ios.sh

# 1. 버전 업데이트
agvtool new-marketing-version $VERSION
agvtool next-version -all

# 2. 빌드
xcodebuild -workspace App.xcworkspace \
  -scheme "App" \
  -configuration Release \
  -archivePath build/App.xcarchive \
  archive

# 3. 익스포트
xcodebuild -exportArchive \
  -archivePath build/App.xcarchive \
  -exportPath build/App \
  -exportOptionsPlist ExportOptions.plist

# 4. App Store Connect 업로드
xcrun altool --upload-app \
  -f build/App/App.ipa \
  -u "$APPLE_ID" \
  -p "$APP_SPECIFIC_PASSWORD"
```

### 2.4 Fastlane 자동화

```ruby
# fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Deploy to App Store"
  lane :release do
    increment_build_number
    build_app(scheme: "App")
    upload_to_app_store(
      skip_metadata: false,
      skip_screenshots: true,
      precheck_include_in_app_purchases: false
    )
  end

  desc "Deploy to TestFlight"
  lane :beta do
    increment_build_number
    build_app(scheme: "App")
    upload_to_testflight
  end
end
```

## 3. Android 앱 배포

### 3.1 릴리스 설정

```kotlin
// app/build.gradle.kts
android {
    defaultConfig {
        applicationId = "com.yourcompany.app"
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KEYSTORE_PATH") ?: "release.keystore")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 3.2 ProGuard 설정

```proguard
# proguard-rules.pro

# Hotwire Native
-keep class dev.hotwire.** { *; }
-dontwarn dev.hotwire.**

# WebView JavaScript Interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Kotlin
-dontwarn kotlin.**
-keep class kotlin.Metadata { *; }
```

### 3.3 Google Play Console 설정

1. **스토어 등록정보**
   - 앱 이름 (30자)
   - 간단한 설명 (80자)
   - 자세한 설명 (4000자)
   - 스크린샷

2. **앱 콘텐츠**
   - 개인정보처리방침 URL
   - 앱 액세스 권한 설명
   - 광고 포함 여부
   - 콘텐츠 등급

3. **출시 관리**
   - 내부 테스트 → 비공개 테스트 → 프로덕션

### 3.4 빌드 및 배포 스크립트

```bash
#!/bin/bash
# scripts/deploy_android.sh

# 1. AAB 빌드
./gradlew bundleRelease

# 2. APK 빌드 (테스트용)
./gradlew assembleRelease

# 3. 서명 확인
jarsigner -verify -verbose -certs app/build/outputs/bundle/release/app-release.aab

echo "AAB 파일: app/build/outputs/bundle/release/app-release.aab"
echo "Google Play Console에 수동 업로드하거나 Fastlane supply 사용"
```

### 3.5 Fastlane 자동화

```ruby
# fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Deploy to Play Store"
  lane :release do
    gradle(
      task: "bundle",
      build_type: "Release"
    )
    upload_to_play_store(
      track: "production",
      aab: "app/build/outputs/bundle/release/app-release.aab"
    )
  end

  desc "Deploy to Internal Testing"
  lane :internal do
    gradle(
      task: "bundle",
      build_type: "Release"
    )
    upload_to_play_store(
      track: "internal",
      aab: "app/build/outputs/bundle/release/app-release.aab"
    )
  end
end
```

## 4. CI/CD 파이프라인

### 4.1 GitHub Actions - iOS

```yaml
# .github/workflows/ios-deploy.yml
name: iOS Deploy

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Install CocoaPods
        run: pod install
        working-directory: ios

      - name: Build and Deploy
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
        run: |
          cd ios
          bundle exec fastlane release
```

### 4.2 GitHub Actions - Android

```yaml
# .github/workflows/android-deploy.yml
name: Android Deploy

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup JDK
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Decode Keystore
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/release.keystore

      - name: Build and Deploy
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
          GOOGLE_PLAY_JSON_KEY: ${{ secrets.GOOGLE_PLAY_JSON_KEY }}
        run: |
          cd android
          bundle exec fastlane release
```

## 5. 업데이트 전략

### 5.1 강제 업데이트 처리

```swift
// iOS
class UpdateChecker {
    func checkForUpdate(completion: @escaping (UpdateStatus) -> Void) {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

        URLSession.shared.dataTask(with: URL(string: "https://your-api.com/app/version")!) { data, _, _ in
            guard let data = data,
                  let response = try? JSONDecoder().decode(VersionResponse.self, from: data) else {
                completion(.upToDate)
                return
            }

            if response.forceUpdate && currentVersion < response.minVersion {
                completion(.forceUpdate(storeURL: response.storeURL))
            } else if currentVersion < response.latestVersion {
                completion(.updateAvailable(storeURL: response.storeURL))
            } else {
                completion(.upToDate)
            }
        }.resume()
    }
}

enum UpdateStatus {
    case upToDate
    case updateAvailable(storeURL: URL)
    case forceUpdate(storeURL: URL)
}
```

### 5.2 OTA 업데이트 (웹 콘텐츠)

Hotwire Native의 장점은 웹 콘텐츠가 실시간으로 업데이트된다는 것입니다. 앱 스토어 심사 없이:

- UI 변경
- 새로운 기능 추가
- 버그 수정
- A/B 테스트

```ruby
# Rails에서 기능 플래그
class FeaturesController < ApplicationController
  def index
    @features = {
      new_checkout: Flipper.enabled?(:new_checkout, current_user),
      dark_mode: Flipper.enabled?(:dark_mode),
      beta_features: current_user&.beta_tester?
    }

    respond_to do |format|
      format.html
      format.json { render json: @features }
    end
  end
end
```

## 6. 배포 체크리스트

### iOS
- [ ] 앱 아이콘 (1024x1024)
- [ ] 스크린샷 (모든 필수 사이즈)
- [ ] 앱 설명 및 키워드
- [ ] 개인정보처리방침 URL
- [ ] 앱 심사 정보 (테스트 계정 등)
- [ ] 인앱 결제 설정 (해당 시)
- [ ] Push 인증서 설정
- [ ] Universal Links 설정

### Android
- [ ] 앱 아이콘 (512x512)
- [ ] 피처 그래픽 (1024x500)
- [ ] 스크린샷 (휴대전화, 태블릿)
- [ ] 앱 설명
- [ ] 개인정보처리방침 URL
- [ ] 콘텐츠 등급 설문
- [ ] 앱 서명 키 설정
- [ ] App Links 설정

### 공통
- [ ] Rails 서버 HTTPS 설정
- [ ] Path Configuration 배포
- [ ] 최소 앱 버전 API 구현
- [ ] 에러 모니터링 설정 (Sentry, Bugsnag)
- [ ] 애널리틱스 설정
