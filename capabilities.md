# Moonwish — 配置文档

生成时间：2026-11-07

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下配置项均为增强功能。不配置时，App 的核心链路（创建愿望 → 生成文字脚本 → 本地渲染音频 → 播放/过夜循环）仍然完整可用。配置后可获得跨设备同步、真实订阅购买、云生成与生产签名。

### 🟡 iCloud / CloudKit（跨设备备份）

**增强功能**：愿望、日记、愿景板元数据、音频元数据和 streak 自动同步到你的私有 iCloud 数据库，重装或多设备不丢数据。
**不配置的影响**：App 自动使用本地 SwiftData 存储，功能完整，但数据只在这台设备上。
**当前状态**：本地存储为默认方案，已实现自动降级。

**已自动配置部分**：
- ✅ `Moonwish.entitlements` 已声明 `iCloud.com.zzoutuo.Moonwish` 容器、CloudKit 服务、kv-store 标识
- ✅ `DataStore.swift` 优先使用 `cloudKitDatabase: .automatic`，失败时回退本地
- ✅ 模型字段全部带默认值，符合 SwiftData + CloudKit 要求

**如需启用云同步，请手动配置**：
1. 打开 [Apple Developer](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Identifiers**
2. 找到 `com.zzoutuo.Moonwish` → 勾选 **iCloud** → **CloudKit**
3. 创建或绑定容器 `iCloud.com.zzoutuo.Moonwish`
4. 在 Xcode 登录同一 Apple ID 后，执行：
   ```
   xcodebuild -project Moonwish.xcodeproj -scheme Moonwish -destination 'generic/platform=iOS' -allowProvisioningUpdates build
   ```
   Xcode 会自动注册容器并刷新描述文件。
5. 首次真机运行后，打开 [CloudKit Dashboard](https://icloud.developer.apple.com) → 选择该容器 → 将 Development 环境的 Schema 部署到 **Production**（App Store 版本只读 Production）。
6. 回到 App：Profile → iCloud backup 应显示 **On**。

---

### 🔵 StoreKit 2 订阅与消耗型内购

**影响功能**：不创建产品时，Plus 页面会显示“无法加载订阅选项”，用户无法完成真实购买（本地开发和免费功能不受影响）。

**配置步骤**：
1. 打开 [App Store Connect](https://appstoreconnect.apple.com) → 你的 App → **Monetization** → **Subscriptions**
2. 创建订阅组 **Moonwish Plus**
3. 在组内创建两个自动续期订阅：

| 产品 | Reference Name | Product ID | 价格 | 试用 |
|------|----------------|-----------|------|------|
| 月付 | Moonwish Plus Monthly | `com.zzoutuo.Moonwish.plus.monthly` | $7.99 / 月 | 无 |
| 年付 | Moonwish Plus Yearly | `com.zzoutuo.Moonwish.plus.yearly` | $29.99 / 年 | 7 天免费试用 |

4. 在 **In-App Purchases** 创建消耗型产品：

| 产品 | Reference Name | Product ID | 价格 |
|------|----------------|-----------|------|
| 云补充包 | Moonwish Cloud Booster | `com.zzoutuo.Moonwish.cloud.booster` | $1.99 |

5. Display Name / Description 直接复制 `price.md` 中已校验的字段（均 ≤35 / ≤55 字符）。
6. 每个产品上传审核截图并提交审核。
7. 本地测试：Xcode → File → New → File → **StoreKit Configuration File**，添加上述三个产品；在 Scheme → Run → Options 中选择该配置文件。
8. 真机验证：Plus 页面 → 购买 → 立即解锁过夜模式/21 音景/云额度；点 Restore Purchases 验证恢复。

---

### 🟢 App Store 审核信息（AI 与订阅）

**影响功能**：不填写审核备注时，审核员可能无法理解 Apple Intelligence 不可用设备上的降级路径，触发 Guideline 2.1(a) 询问或拒绝。

**配置步骤**：
1. App Store Connect → 你的 App → **App Review Information**
2. **Notes** 字段粘贴 `app_review_info.md` 的 “Review Notes” 部分（包含 Apple Intelligence、自定义 API Key、内置 composer 兜底、订阅产品 ID、隐私说明）
3. **Demo Account** 字段粘贴同文件的 “Reviewer steps” 部分。App 无需账号即可使用，审核员可直接走创建流程
4. **Privacy Policy URL**：`https://asunnyboy861.github.io/Moonwish/privacy.html`
5. **EULA / Terms**：`https://asunnyboy861.github.io/Moonwish/terms.html`
6. **Support URL**：`https://asunnyboy861.github.io/Moonwish/support.html`
7. 审核备注中说明：iPhone 15 Pro 及以上、iOS 26 及以上可使用 Apple Intelligence；其他设备使用内置 composer 或 Plus 云通道，均能生成音频

---

### 🟣 真机签名与 Archive

**影响功能**：模拟器构建已通过，但 Archive 上传需要真实 Team 与描述文件。

**配置步骤**：
1. 在 Xcode → Settings → Accounts 登录开发者账号
2. 打开 `Moonwish.xcodeproj` → 每个 target 的 Signing & Capabilities → Team 选择 `JP4TN5PTS3`（工程已预置该 Team）
3. 执行：
   ```
   xcodebuild -project Moonwish.xcodeproj -scheme Moonwish -destination 'generic/platform=iOS' -allowProvisioningUpdates build
   ```
4. 确认无 `requires a development team` 报错后，Product → Archive → Distribute App → App Store Connect

---

### ⚪ GLM 云代理（Plus 深度生成）

**增强功能**：Plus 用户每月 30 次 GLM-5.3-Flash 深度脚本生成。
**不配置的影响**：Plus 云通道不可用，但 Apple Intelligence / BYO / 内置 composer 仍可生成音频。
**当前状态**：
- ✅ 已注册 Worker 白名单：`appId = moonwish`，`bundleId = com.zzoutuo.Moonwish`
- ✅ 本地开发密钥已写入 `Moonwish/GLMProxySecret.txt`（已加入 `.gitignore`，Release 构建通过 `EXCLUDED_SOURCE_FILE_NAMES` 排除）
- ✅ 端到端验证通过：200（正常生成）、400（缺 userId）、401（无凭证）、405（GET）

**需要你确认的事项**：
1. 生产环境依赖 StoreKit 2 订阅 JWS 验签，不需要在 App 内放 devKey。上线前确保订阅产品已审核通过，Worker 端能验证 JWS。
2. 若 GLM 账号归属变化，请在 `~/.local/share/glm_secrets/glm_dev_key` 更新本地密钥，并同步 Worker Secret。
3. 不要将 `GLMProxySecret.txt` 提交到 Git，也不要放进 Release 包。

---

### 💡 App 内用户操作（不是开发者配置）

- **通知权限**：用户在 Profile 打开 “Evening moon reminder” 时由系统弹窗授权。
- **麦克风/语音识别**：用户第一次点“Speak it”或日记“Dictate”时授权。
- **Face ID**：用户在 Profile 打开 “Face ID lock” 时授权。
- **Personal Voice**：用户在 Profile 打开 “Personal Voice” 时授权，语音需先在系统设置创建。
- **自定义 API Key**：用户在 Profile → Custom API key 内填写，密钥存 Keychain。

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### 工程与 Capabilities

| 项目 | 说明 | 状态 |
|------|------|------|
| Bundle ID | `com.zzoutuo.Moonwish` | ✅ |
| 部署目标 | iOS 17.0；Apple Intelligence 代码用 `@available(iOS 26.0, *)` 保护 | ✅ |
| 签名 Team | 工程级 `DEVELOPMENT_TEAM = JP4TN5PTS3` | ✅ |
| iPhone / iPad | `TARGETED_DEVICE_FAMILY = 1,2`，iPad 四方向 | ✅ |
| iCloud entitlements | CloudKit 容器 + kv-store | ✅ |
| 后台音频 | `UIBackgroundModes = audio` | ✅ |
| 麦克风 / 语音识别 | Info.plist 用途字符串 | ✅ |
| Face ID | `NSFaceIDUsageDescription` | ✅ |
| 相机 / 相册 | `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` | ✅ |
| 出口合规 | `ITSAppUsesNonExemptEncryption = false` | ✅ |
| 隐私清单 | `PrivacyInfo.xcprivacy`（无追踪；UserDefaults CA92.1；文件时间戳 C617.1） | ✅ |
| 应用图标 | Agnes 生成 1024×1024 RGB 无 alpha，Asset Catalog 已配置 | ✅ |

### 后端与网络

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | `https://msg.calcs.top/api/feedback`（7 个主题 tile、5 个必填字段、隐私提示、成功/失败反馈） | ✅ 已接入 |
| GLM 代理 | `https://cramjam-api.calcs.top` + 备用 workers.dev 域名 | ✅ 已接入 |
| 网络权限 | 全部 HTTPS 出站，Info.plist 无需 ATS 例外 | ✅ |

### 代码与内容

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | MVVM；27 项功能；5 个 Tab | ✅ |
| AI 引擎 | Apple Intelligence + GLM 云 + 自定义 Key + 内置 composer 四级降级 | ✅ |
| 音频 | AVSpeechSynthesizer 渲染本地 CAF；AVPlayerLooper 无缝循环；21 种程序化音景 | ✅ |
| 数据 | SwiftData + CloudKit；本地降级；导出 JSON + 音频 | ✅ |
| 内购 | StoreKit 2；3 个产品 ID；恢复购买；管理订阅；法律链接 | ✅ |
| 客服 | ContactSupportView 完整实现 | ✅ |
| 测试 | 7 项单元测试全部通过（脚本、解析、音频渲染、持久化、streak、月相、资源数量） | ✅ |
| 政策页 | Landing + Support + Privacy + Terms，GitHub Pages 4 个 URL 均 200 | ✅ |
| App Store 文案 | `keytext.md` 通过 15 项校验 | ✅ |
| 代码仓库 | https://github.com/asunnyboy861/Moonwish | ✅ |

---

## 三、能力检测详情

### Analysis

来自中文指南与 `us.md` 的关键词扫描：
- SwiftData + CloudKit 全量自动云备份（同步 / iCloud）
- 8 小时过夜音频、锁屏与后台播放（后台 / 音频）
- 晚间 21:30 仪式提醒、试用结束提醒、Time Capsule 到期提醒（通知 / 提醒）
- 日记语音转文字、说出愿望（语音 / 麦克风）
- Face ID 应用锁
- Personal Voice 个人声音朗读
- 愿景板拍照 / 相册选图
- 月度云配额与消耗型补充包（订阅 / 购买）
- iPhone + iPad 通用布局

### 未使用的能力（无需配置）

- 推送通知（APNs）：仅使用本地通知，不需要推送 entitlement
- HealthKit：未使用，无健康声明
- 定位服务：未使用
- Sign in with Apple：CloudKit 使用设备 Apple ID，无需独立登录
- App Groups：无 Widget / 扩展 target
- Apple Watch：v1 不含 Watch App

### Verification

- 模拟器构建：iPhone 17（iOS 27.0）与 iPad Pro 13-inch（iOS 27.0）均 **BUILD SUCCEEDED**
- 启动测试：iPhone 与 iPad 均正常渲染首屏，进程存活无崩溃
- 单元测试：`MoonwishCoreTests` 7/7 通过
- 签名验证：⏳ 待用户在 Xcode 登录账号后执行 `-allowProvisioningUpdates`
- 隐私清单：App target 已覆盖
- 端到端：GLM 200 / 400 / 401 / 405 全部符合预期
