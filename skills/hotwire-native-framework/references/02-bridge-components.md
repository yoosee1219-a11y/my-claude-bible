# Bridge Components

네이티브 기능(카메라, 푸시 알림, 생체 인증 등)을 웹에서 호출하기 위한 Bridge Component 패턴

## 1. Bridge Component 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    Rails Web Application                     │
│  ┌───────────────────────────────────────────────────────┐  │
│  │           Stimulus Bridge Controller (JS)              │  │
│  │   - 이벤트 발생 시 네이티브 Bridge 호출                  │  │
│  │   - 네이티브 응답 처리                                   │  │
│  └───────────────────────────────────────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │ Bridge Message
    ┌───────────────────────┼───────────────────┐
    │                       │                   │
┌───▼───────────┐      ┌────▼────────┐     ┌────▼────────┐
│ iOS Bridge    │      │ Android     │     │ Web Fallback│
│ Component     │      │ Bridge      │     │ (graceful)  │
│ (Swift)       │      │ (Kotlin)    │     │             │
└───────────────┘      └─────────────┘     └─────────────┘
```

## 2. 기본 Bridge Component 설정

### 2.1 Rails (JavaScript) - Stimulus Controller

```javascript
// app/javascript/controllers/bridge_controller.js
import { Controller } from "@hotwired/stimulus"
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends Controller {
  static targets = ["button"]

  // Bridge 메시지 전송
  send(event, message) {
    if (this.isBridgeAvailable) {
      BridgeComponent.send(event, message)
    } else {
      console.log("Bridge not available, using web fallback")
      this.webFallback(event, message)
    }
  }

  get isBridgeAvailable() {
    return typeof BridgeComponent !== "undefined" &&
           window.TurboNativeBridge !== undefined
  }

  webFallback(event, message) {
    // 웹 브라우저 대체 구현
  }
}
```

### 2.2 Bridge Component 등록 (Rails)

```ruby
# config/importmap.rb
pin "@hotwired/hotwire-native-bridge", to: "https://cdn.jsdelivr.net/npm/@hotwired/hotwire-native-bridge@1/dist/hotwire-native-bridge.esm.js"
```

```ruby
# 또는 package.json (npm 사용 시)
# "dependencies": {
#   "@hotwired/hotwire-native-bridge": "^1.0.0"
# }
```

## 3. 카메라 Bridge Component

### 3.1 Rails Stimulus Controller

```javascript
// app/javascript/controllers/camera_bridge_controller.js
import { Controller } from "@hotwired/stimulus"
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends Controller {
  static targets = ["preview", "input"]
  static values = {
    maxSize: { type: Number, default: 1024 },
    quality: { type: Number, default: 0.8 }
  }

  takePhoto() {
    if (this.isBridgeAvailable) {
      BridgeComponent.send("camera", {
        action: "capture",
        maxSize: this.maxSizeValue,
        quality: this.qualityValue
      }, (response) => {
        this.handleCameraResponse(response)
      })
    } else {
      // 웹 폴백: input[type=file] 사용
      this.inputTarget.click()
    }
  }

  selectFromGallery() {
    if (this.isBridgeAvailable) {
      BridgeComponent.send("camera", {
        action: "gallery",
        multiple: false
      }, (response) => {
        this.handleCameraResponse(response)
      })
    } else {
      this.inputTarget.click()
    }
  }

  handleCameraResponse(response) {
    if (response.success) {
      this.previewTarget.src = `data:image/jpeg;base64,${response.data}`
      this.inputTarget.value = response.data
    } else {
      alert(response.error || "Failed to capture image")
    }
  }

  get isBridgeAvailable() {
    return typeof BridgeComponent !== "undefined" &&
           window.TurboNativeBridge !== undefined
  }
}
```

### 3.2 iOS Camera Bridge

```swift
// CameraBridgeComponent.swift
import HotwireNative
import UIKit

final class CameraBridgeComponent: BridgeComponent {
    override class var name: String { "camera" }

    private var imagePickerDelegate: ImagePickerDelegate?

    override func onReceive(message: Message) {
        guard let action = message.data["action"] as? String else { return }

        switch action {
        case "capture":
            presentCamera(message: message)
        case "gallery":
            presentGallery(message: message)
        default:
            break
        }
    }

    private func presentCamera(message: Message) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            reply(to: message, with: ["success": false, "error": "Camera not available"])
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true

        imagePickerDelegate = ImagePickerDelegate { [weak self] image in
            self?.handleImage(image, message: message)
        }
        picker.delegate = imagePickerDelegate

        viewController?.present(picker, animated: true)
    }

    private func presentGallery(message: Message) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true

        imagePickerDelegate = ImagePickerDelegate { [weak self] image in
            self?.handleImage(image, message: message)
        }
        picker.delegate = imagePickerDelegate

        viewController?.present(picker, animated: true)
    }

    private func handleImage(_ image: UIImage?, message: Message) {
        guard let image = image,
              let maxSize = message.data["maxSize"] as? Int,
              let quality = message.data["quality"] as? Double else {
            reply(to: message, with: ["success": false, "error": "Failed to process image"])
            return
        }

        let resized = image.resized(maxDimension: CGFloat(maxSize))
        guard let data = resized.jpegData(compressionQuality: quality) else {
            reply(to: message, with: ["success": false, "error": "Failed to encode image"])
            return
        }

        let base64 = data.base64EncodedString()
        reply(to: message, with: ["success": true, "data": base64])
    }
}
```

### 3.3 Android Camera Bridge

```kotlin
// CameraBridgeComponent.kt
import dev.hotwire.core.bridge.BridgeComponent
import dev.hotwire.core.bridge.Message

class CameraBridgeComponent(
    name: String,
    private val delegate: BridgeDelegate
) : BridgeComponent<BridgeDelegate>(name, delegate) {

    override fun onReceive(message: Message) {
        val action = message.data.optString("action")

        when (action) {
            "capture" -> launchCamera(message)
            "gallery" -> launchGallery(message)
        }
    }

    private fun launchCamera(message: Message) {
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        // 이미지 캡처 후 결과 처리
        delegate.activity.startActivityForResult(intent, CAMERA_REQUEST_CODE)
        pendingMessage = message
    }

    private fun launchGallery(message: Message) {
        val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        delegate.activity.startActivityForResult(intent, GALLERY_REQUEST_CODE)
        pendingMessage = message
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (resultCode != Activity.RESULT_OK) {
            replyTo(pendingMessage, mapOf("success" to false, "error" to "Cancelled"))
            return
        }

        val bitmap = when (requestCode) {
            CAMERA_REQUEST_CODE -> data?.extras?.get("data") as? Bitmap
            GALLERY_REQUEST_CODE -> getBitmapFromUri(data?.data)
            else -> null
        }

        bitmap?.let {
            val base64 = encodeToBase64(it)
            replyTo(pendingMessage, mapOf("success" to true, "data" to base64))
        } ?: replyTo(pendingMessage, mapOf("success" to false, "error" to "Failed to process image"))
    }

    companion object {
        const val NAME = "camera"
        const val CAMERA_REQUEST_CODE = 1001
        const val GALLERY_REQUEST_CODE = 1002
    }
}
```

## 4. 푸시 알림 Bridge Component

### 4.1 Rails Stimulus Controller

```javascript
// app/javascript/controllers/push_bridge_controller.js
import { Controller } from "@hotwired/stimulus"
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends Controller {
  connect() {
    this.requestPushPermission()
  }

  requestPushPermission() {
    if (this.isBridgeAvailable) {
      BridgeComponent.send("push", {
        action: "requestPermission"
      }, (response) => {
        if (response.granted) {
          this.registerToken(response.token)
        }
      })
    } else {
      // Web Push API 사용
      this.requestWebPush()
    }
  }

  registerToken(token) {
    fetch("/api/push_tokens", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({ token: token, platform: this.getPlatform() })
    })
  }

  getPlatform() {
    const userAgent = navigator.userAgent
    if (userAgent.includes("Hotwire Native iOS")) return "ios"
    if (userAgent.includes("Hotwire Native Android")) return "android"
    return "web"
  }

  get isBridgeAvailable() {
    return typeof BridgeComponent !== "undefined" &&
           window.TurboNativeBridge !== undefined
  }
}
```

### 4.2 iOS Push Bridge

```swift
// PushBridgeComponent.swift
import HotwireNative
import UserNotifications

final class PushBridgeComponent: BridgeComponent {
    override class var name: String { "push" }

    override func onReceive(message: Message) {
        guard let action = message.data["action"] as? String else { return }

        switch action {
        case "requestPermission":
            requestPermission(message: message)
        default:
            break
        }
    }

    private func requestPermission(message: Message) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }

                // 토큰은 AppDelegate에서 받아서 전달
                if let token = UserDefaults.standard.string(forKey: "pushToken") {
                    self.reply(to: message, with: ["granted": true, "token": token])
                } else {
                    self.reply(to: message, with: ["granted": true, "token": "pending"])
                }
            } else {
                self.reply(to: message, with: ["granted": false, "error": error?.localizedDescription ?? "Permission denied"])
            }
        }
    }
}
```

## 5. 생체 인증 Bridge Component

### 5.1 Rails Stimulus Controller

```javascript
// app/javascript/controllers/biometric_bridge_controller.js
import { Controller } from "@hotwired/stimulus"
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends Controller {
  authenticate() {
    if (this.isBridgeAvailable) {
      BridgeComponent.send("biometric", {
        action: "authenticate",
        reason: "Please authenticate to continue"
      }, (response) => {
        if (response.success) {
          this.onAuthSuccess()
        } else {
          this.onAuthFailure(response.error)
        }
      })
    } else {
      // 웹 폴백: 비밀번호 입력 폼 표시
      this.showPasswordForm()
    }
  }

  onAuthSuccess() {
    this.element.dispatchEvent(new CustomEvent("biometric:success"))
  }

  onAuthFailure(error) {
    this.element.dispatchEvent(new CustomEvent("biometric:failure", { detail: { error } }))
  }

  showPasswordForm() {
    // 비밀번호 폴백 UI 표시
  }

  get isBridgeAvailable() {
    return typeof BridgeComponent !== "undefined" &&
           window.TurboNativeBridge !== undefined
  }
}
```

### 5.2 iOS Biometric Bridge

```swift
// BiometricBridgeComponent.swift
import HotwireNative
import LocalAuthentication

final class BiometricBridgeComponent: BridgeComponent {
    override class var name: String { "biometric" }

    override func onReceive(message: Message) {
        guard let action = message.data["action"] as? String else { return }

        switch action {
        case "authenticate":
            authenticate(message: message)
        case "isAvailable":
            checkAvailability(message: message)
        default:
            break
        }
    }

    private func authenticate(message: Message) {
        let context = LAContext()
        let reason = message.data["reason"] as? String ?? "Authenticate to continue"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            reply(to: message, with: ["success": false, "error": error?.localizedDescription ?? "Biometrics not available"])
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.reply(to: message, with: ["success": true])
                } else {
                    self.reply(to: message, with: ["success": false, "error": error?.localizedDescription ?? "Authentication failed"])
                }
            }
        }
    }

    private func checkAvailability(message: Message) {
        let context = LAContext()
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        let biometryType: String
        switch context.biometryType {
        case .faceID: biometryType = "faceId"
        case .touchID: biometryType = "touchId"
        default: biometryType = "none"
        }

        reply(to: message, with: [
            "available": available,
            "type": biometryType
        ])
    }
}
```

## 6. 위치 정보 Bridge Component

### 6.1 Rails Stimulus Controller

```javascript
// app/javascript/controllers/location_bridge_controller.js
import { Controller } from "@hotwired/stimulus"
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends Controller {
  static targets = ["latitude", "longitude", "accuracy"]

  getCurrentLocation() {
    if (this.isBridgeAvailable) {
      BridgeComponent.send("location", {
        action: "getCurrentPosition",
        highAccuracy: true
      }, (response) => {
        if (response.success) {
          this.updateLocation(response)
        } else {
          this.handleError(response.error)
        }
      })
    } else {
      // Web Geolocation API 폴백
      this.getWebLocation()
    }
  }

  updateLocation(response) {
    this.latitudeTarget.value = response.latitude
    this.longitudeTarget.value = response.longitude
    if (this.hasAccuracyTarget) {
      this.accuracyTarget.textContent = `Accuracy: ${response.accuracy}m`
    }
  }

  getWebLocation() {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          this.updateLocation({
            success: true,
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy
          })
        },
        (error) => {
          this.handleError(error.message)
        },
        { enableHighAccuracy: true }
      )
    }
  }

  handleError(error) {
    console.error("Location error:", error)
  }

  get isBridgeAvailable() {
    return typeof BridgeComponent !== "undefined" &&
           window.TurboNativeBridge !== undefined
  }
}
```

## 7. 공유 Bridge Component

### 7.1 Rails Stimulus Controller

```javascript
// app/javascript/controllers/share_bridge_controller.js
import { Controller } from "@hotwired/stimulus"
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends Controller {
  static values = {
    title: String,
    text: String,
    url: String
  }

  share() {
    const shareData = {
      title: this.titleValue,
      text: this.textValue,
      url: this.urlValue || window.location.href
    }

    if (this.isBridgeAvailable) {
      BridgeComponent.send("share", shareData)
    } else if (navigator.share) {
      // Web Share API
      navigator.share(shareData)
    } else {
      // 폴백: 클립보드 복사
      this.copyToClipboard(shareData.url)
    }
  }

  copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
      alert("Link copied to clipboard!")
    })
  }

  get isBridgeAvailable() {
    return typeof BridgeComponent !== "undefined" &&
           window.TurboNativeBridge !== undefined
  }
}
```

## 8. Bridge Component 등록

### iOS

```swift
// AppDelegate.swift
import HotwireNative

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Bridge Component 등록
        Hotwire.registerBridgeComponents([
            CameraBridgeComponent.self,
            PushBridgeComponent.self,
            BiometricBridgeComponent.self,
            LocationBridgeComponent.self,
            ShareBridgeComponent.self
        ])

        return true
    }
}
```

### Android

```kotlin
// Application.kt
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        Hotwire.registerBridgeComponents(
            BridgeComponentFactory("camera", ::CameraBridgeComponent),
            BridgeComponentFactory("push", ::PushBridgeComponent),
            BridgeComponentFactory("biometric", ::BiometricBridgeComponent),
            BridgeComponentFactory("location", ::LocationBridgeComponent),
            BridgeComponentFactory("share", ::ShareBridgeComponent)
        )
    }
}
```
