# Capabilities Configuration

## Analysis

Detected requirements from the Chinese guide and `us.md`:

- Cloud backup of wishes, journal, streak, and audio metadata ("SwiftData + CloudKit 全量自动云备份")
- Background audio playback for 8-hour overnight loops ("过夜音频", "锁屏控制中心可操作")
- Local notifications for 21:30 ritual reminder, trial-ending reminder, Time Capsule target dates
- Microphone + speech recognition for journal dictation and speaking a wish
- Face ID app lock ("Face ID 锁")
- Personal Voice authorization for self-voiced affirmations
- Camera / photo library for the vision board
- In-app purchase (subscriptions + consumable booster) — configured later with StoreKit products
- Universal iPhone + iPad layout

## Auto-Configured Capabilities

| Capability | Status | Method |
|------------|--------|--------|
| iCloud / CloudKit | ✅ Entitlements configured | `Moonwish.entitlements`: `com.apple.developer.icloud-container-identifiers` = `iCloud.com.zzoutuo.Moonwish`, `com.apple.developer.icloud-services` = CloudKit, ubiquity kv-store identifier |
| Background audio | ✅ Configured | `UIBackgroundModes` = `audio` in Info.plist |
| Local notifications | ✅ Configured | UserNotifications framework; no entitlement required for local notifications |
| Microphone | ✅ Configured | `NSMicrophoneUsageDescription` |
| Speech recognition | ✅ Configured | `NSSpeechRecognitionUsageDescription` |
| Face ID | ✅ Configured | `NSFaceIDUsageDescription` + LocalAuthentication |
| Camera | ✅ Configured | `NSCameraUsageDescription` |
| Photo library | ✅ Configured | `NSPhotoLibraryUsageDescription` |
| Universal iPhone/iPad | ✅ Configured | `TARGETED_DEVICE_FAMILY = 1,2`; iPad orientations declared |
| Export compliance | ✅ Configured | `ITSAppUsesNonExemptEncryption = false` |
| Privacy manifest | ✅ Configured | `Moonwish/PrivacyInfo.xcprivacy` (no tracking, UserDefaults CA92.1, file timestamp C617.1) |
| Signing team | ✅ Configured | Project-level `DEVELOPMENT_TEAM = JP4TN5PTS3`, automatic signing |

## Manual Configuration Required

| Capability | Status | Steps |
|------------|--------|-------|
| CloudKit container provisioning | ⏳ Pending | The container `iCloud.com.zzoutuo.Moonwish` must be registered to the team in the Apple Developer portal / Xcode Signing & Capabilities. Xcode auto-creates it on the first `-allowProvisioningUpdates` build once the account is signed in. CloudKit schema (Wish, AudioSession, DailyRecord, JournalEntry, BoardItem, StreakState) is created automatically on first run, then deployed to Production from the CloudKit Dashboard. |
| StoreKit products | ⏳ Pending | Create subscription group "Moonwish Plus" with `com.zzoutuo.Moonwish.plus.monthly` ($7.99) and `com.zzoutuo.Moonwish.plus.yearly` ($29.99, 7-day trial), plus consumable `com.zzoutuo.Moonwish.cloud.booster` ($1.99) in App Store Connect. Products are declared in code and must exist in ASC to resolve. |
| GLM shared proxy | ⏳ Pending | The shared Cloudflare Worker (`cramjam-api.calcs.top`) must whitelist bundle ID `com.zzoutuo.Moonwish`; the dev key is injected into a gitignored local secret file by the GLM configuration step. Free tier works without it. |
| Personal Voice | ⏳ Device only | Personal Voice creation happens in Settings → Accessibility → Personal Voice on a real device; the app requests authorization when the user opts in. Simulator cannot create personal voices. |

## No Configuration Needed

- Push notifications (only local notifications are used; no APNs entitlement required)
- HealthKit (not used)
- Location services (not used)
- Sign in with Apple (CloudKit uses the device's Apple ID; no separate sign-in entitlement)
- App Groups (no widget or extension targets)
- Apple Watch target (not in scope for v1)

## Verification

- Build succeeded after configuration: ✅ (`xcodebuild -scheme Moonwish -destination 'id=197C3FE9-9D72-487D-B117-D0CCB73DEAF4' build CODE_SIGNING_ALLOWED=NO` → BUILD SUCCEEDED)
- Entitlements file referenced at project level: ✅ `CODE_SIGN_ENTITLEMENTS = Moonwish/Moonwish.entitlements`
- Signing verification (generic/platform=iOS): ⏳ DEFERRED — no portal-side capability registration performed; after the user signs into Xcode, run `xcodebuild -project Moonwish.xcodeproj -scheme Moonwish -destination 'generic/platform=iOS' -allowProvisioningUpdates build`
- DEVELOPMENT_TEAM: JP4TN5PTS3 baked at project level for all targets
- PrivacyInfo.xcprivacy: App target covered
- Info.plist: usage strings, background audio, export compliance, iPad orientations verified
