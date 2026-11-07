# Moonwish — iOS Development Guide

**Source guide**: `TR-20261013-Moonwish月光许愿操作指南.MD` (2026-10-13)
**Target market**: United States
**App name**: Moonwish
**Subtitle (≤30 chars)**: Manifest While You Sleep
**Category**: Health & Fitness (Lifestyle fallback)
**Bundle ID**: com.zzoutuo.Moonwish (skill preset `${BUNDLE_PREFIX}<APP_NAME>`; the guide's own bundle suggestion is ignored per DOCUMENT-vs-SKILL precedence)
**Minimum iOS**: 17.0 (Apple Intelligence features are gated at runtime to iOS 26+ / supported devices)
**Community name**: Moonwishers (#Moonwishers #ManifestWhileYouSleep)

---

## Executive Summary

Moonwish is a bedtime manifestation companion: within 90 seconds a new user speaks one wish, answers up to three tap-only AI follow-up chips, and receives a personalized affirmation audio track rendered locally on the device — then sleeps to an 8-hour seamless overnight loop.

Core emotional value chain: **say it (be heard) → triage questions (be taken seriously) → hear your own audio (be treasured) → a moon letter in the morning (be answered) → celebrate the day it happened (be blessed)**.

Key differentiators vs. the category leader Vix ($19.99/mo, $39.99/yr, no trial, paywall-first):
1. A genuinely useful free tier — 3 complete AI personalized audios per week generated on-device at zero marginal cost, plus a 20+ track curated library.
2. 8-hour seamless overnight loops that pass an on-device LoopGuard quality check before playback.
3. SwiftData + CloudKit full automatic backup — journal entries and streaks never disappear.
4. A forgiving moon streak with a monthly "cloud-covered moon" grace day.
5. Time Capsule closure loop — mark a wish "It Happened!" and generate a shareable celebration card.
6. Transparent pricing: $7.99/month and $29.99/year (7-day free trial), monthly option available.
7. Multi-provider BYO API (GLM / OpenAI / Claude / Gemini / DeepSeek / custom OpenAI-compatible endpoint).

---

## Competitive Analysis

| App | Strengths | Weaknesses | Our Advantage |
|-----|-----------|------------|---------------|
| Vix (AI Manifestation) — App ID 6747910148 | Category leader; ~$140K/yr net subscription revenue; 25-account TikTok matrix; 200+ subliminal playlists; 13 languages | Paywall before value, no free trial; 2-minute audios with broken loops; journal entries and streaks lost; support unresponsive; $19.99/mo or $39.99/yr with no monthly alternative in some tiers | Real free tier (3 full AI audios/week), 8h seamless loops, CloudKit backup, forgiving streak, $7.99/mo + $29.99/yr with 7-day trial |
| Manifest (ai-manifest) | Aggressive weekly subscription; 3-day trial | Weekly subscription is the most complained-about model in the category | No weekly plan; monthly + annual only, transparent renewal reminders |
| The Manifest App | Workbook-style 7-day onboarding; ~$90/yr | Annual-only pricing, no monthly option, opaque billing | $29.99/yr anchor, monthly option, explicit renewal disclosures |
| Fate – Subliminals | Large subliminal library; $4.99/wk, $47.99/yr | Pure subliminal, no personalized AI scripting, weekly billing | Personalized scripts + curated library + no weekly billing |
| You Are | Low-price anchor $29.99/yr | Thin free tier | Stronger free tier and deeper audio pipeline |
| DreamBoard | One-time $27 purchase | No recurring content or AI | Sustainable subscription with monthly cloud quota, plus BYO-key option |

Positioning statement: **Moonwish = in 60 seconds before bed, say your wish; AI turns it into a personalized manifestation radio that plays all night.**

---

## ⚠️ App Store Compliance — AI Features

### Apple Intelligence (Default Free AI Backend)
This app uses Apple Intelligence (on-device Foundation Models) as the default free-tier AI backend. On supported devices (iPhone 15 Pro or later, iOS 26+) AI features work immediately after download with zero configuration.

**iOS Version Handling**:
- **iOS 26+ with Apple Intelligence available**: default engine; AI works out of the box.
- **iOS 17–25, or unsupported hardware**: Foundation Models unavailable. The app falls back to (a) the shared GLM cloud proxy for Plus subscribers, or (b) the user's own BYO API key. The UI must state clearly: "Apple Intelligence requires iOS 26 and a supported device. Configure a custom API key or subscribe to Plus to continue generating."
- **Simulator**: Apple Intelligence is unavailable; testing uses BYO key or the GLM proxy.

### BYO API Key (Optional Advanced Configuration)
Users may configure their own key (GLM / OpenAI / Claude / Gemini / DeepSeek / any OpenAI-compatible endpoint) under Profile → BYO API. Benefits: works on older devices, lets users pick a model, unlimited generations on their own quota.

### Guideline 2.1(a) — App Completeness
1. Reviewers on Apple Intelligence-capable devices can generate without any key.
2. Never show a generation button that dead-ends in an error when no engine is available — always offer a deterministic fallback path (curated preset audio + clear inline explanation).
3. Generation gating logic is entitlement-based, never "free generation counter" dead code:
   `canGenerate = isPlusActive || hasBYOKey || appleIntelligenceAvailable` (free weekly quota applies only to the on-device engine).
4. Do NOT ship dead code such as `freeGenerationsUsed`, `maxFreeGenerations`, `canGenerateFree`, `incrementGenerationCount()`.

### AI Content Safety
- AI output is validated against a JSON schema before use; on failure retry once, then fall back to the on-device engine, then to a curated preset.
- No medical, diagnostic, or therapeutic claims anywhere in UI, metadata, or generated scripts. Content is framed as motivational / mindfulness audio.

---

## ⚠️ App Store Compliance — Subscriptions

### Guideline 3.1.2(c) — Subscription Information
The Paywall MUST contain:
- Functional link to Privacy Policy
- Functional link to Terms of Use (EULA)
- Subscription title, length, and price for each option
- Auto-renewal disclosure text ("7 days free, then $29.99/year, cancel anytime")
- Restore Purchases button
- Manage Subscription link to the system subscription settings

### Pricing Model
| Tier | Price | Contents |
|------|-------|----------|
| Free | $0 | 3 full AI personalized audios per week (on-device engine); 20+ curated preset audios; vision board (9 images); 369 / scripting journal; moon streak; system voices; 3 basic soundscapes; CloudKit backup |
| Plus Monthly | $7.99/month | Unlimited Apple AI features; 30 GLM cloud generations/month; 8h overnight mode; Personal Voice; all 21 soundscapes/rituals; audio download & export; SOS mode; moon weekly report |
| Plus Annual (primary) | $29.99/year with 7-day trial | Everything in monthly; effectively $2.50/month |
| Cloud Booster (consumable) | $1.99 = 30 GLM cloud generations, permanent | For heavy months |
| BYO API | $0 (Plus or free with own key) | Unlimited cloud generation on the user's own quota |

Forbidden: lifetime unlock of the whole app, weekly subscription, dark-pattern auto-redirect billing.

---

## ⚠️ Feature Inventory (MANDATORY)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|---------------------|------------|------------|-------------|-------------|---------------------|
| 1 | First-run onboarding (90-second activation) | Open app → moon breathing animation + tagline → Sign in with Apple (optional, skippable) → choose wish domain card → speak or type one wish → up to 3 chip-only follow-ups → generating animation with streaming script lines → audio plays | Apple ID credential, domain choice, wish text, chip answers | Onboarding state machine; wish persisted; script generation routed by AIEngineRouter; TTS + soundscape offline render; LoopGuard check | Animated moon, personal audio playback, streak +1, item in My Channel | SwiftData `Wish`, `AudioSession`, `DailyRecord`; local m4a file; CloudKit sync | Fresh install → within 3 steps a personalized audio is playing; no keyboard forced; no paywall before value |
| 2 | Moon breathing home ("Tonight") | Daily open → real-time moon phase with streak-driven fullness → today's affirmation → two large buttons: Tonight ritual / New Wish | Date, streak count, stored daily affirmation | MoonPhaseCalculator (astronomical phase + streak fullness), daily affirmation selection | Moon canvas, streak bar, primary gold button | `DailyRecord`, UserDefaults for last affirmation seed | Moon renders correct phase for the date; Reduce Motion shows a static moon |
| 3 | New Wish flow + AI triage chips | Tap New Wish → domain → wish text → 3 chip questions ("When? Tonight / This week / No deadline", etc.) | Wish text, domain, chip selections | Chip generation from domain templates; AI script generation (JSON schema) | Structured script (opening / 10–30 body lines / closing / duration markers) | `Wish`, `AudioSession.scriptJSON` | All follow-ups are tap-only; a user can complete the flow without typing after the wish line |
| 4 | Script generation with dual-engine routing | Automatic during wish creation | `WishInput` (wish + chips + domain + tier) | `AIEngineRouter`: free/offline → Apple Foundation Models (guided generation); Plus → GLM-5.3-Flash via Worker; BYO → direct endpoint. Validation → 1 retry → fallback to on-device → fallback to preset | Validated `ManifestationScript` JSON | `AudioSession.scriptJSON` | Engine used is recorded; no user ever ends with zero audio |
| 5 | Audio synthesis and offline mixdown | Automatic after script validation | Script segments, voice choice, soundscape choice, target duration | `AudioMixer`: AVSpeechSynthesizer voice + looping background track, 1.2s inter-sentence breathing gap, 1s fade in/out, rendered to local m4a | Local audio file + metadata | Sandbox file + `AudioSession.fileName` | Audio plays offline; survives relaunch; one generation is permanently playable |
| 6 | LoopGuard seamless loop QA | Automatic before overnight playback | Rendered audio file | Tail/head crossfade check, waveform continuity validation; auto re-render on failure | Passed/failed QC flag; repaired file | `AudioSession` quality metadata | Overnight audio always loops without clicks or gaps; failures are re-rendered or blocked with explanation |
| 7 | Overnight 8-hour sleep mode with fade-out timer | Tap "Tonight" → sleep mode → choose duration and fade-out → lock screen continues playback | Duration, fade curve | `AVQueuePlayer` looping playback, `.playback` + `mixWithOthers` session, sleep timer with gradual volume fade | Continuous overnight audio; lock-screen / control-center controls | Playback state; background audio enabled | 8h loop is stable; volume fades to silence at the timer end; works with screen locked |
| 8 | My Channel personal radio | Tab 2 → grouped by wish; play, loop, download, delete | Stored sessions | Grouping, sorting, playback queue | Audio library list per wish | `Wish` ↔ `AudioSession` relationship | Every generated audio appears automatically, grouped by its wish |
| 9 | Curated preset audio library (20+) | Browse preset tracks → play → optionally save | Preset selection | Bundled audio assets + metadata | Playable preset list | Bundled resources + `DailyRecord` listen event | At least 20 presets shipped; no AI needed; works fully offline |
| 10 | Vision Board (9 images) + AI photo-to-affirmation | Board tab → add photos from library/camera → arrange collage → tap "Generate from photo" | Up to 9 images, optional vision caption | Collage layout; GLM vision request (Plus/BYO) or deterministic local caption-based script for free tier | Grid collage; generated audio tied to the board | `BoardItem` (image data in local storage, metadata in SwiftData) | 9-image limit enforced; photo generation clearly labeled Plus/BYO when cloud vision is used |
| 11 | Journal (369 / scripting / gratitude) | Journal tab → choose method → voice-to-text or type → save → streak event | Text (typed or dictated), method type | `JournalEntry` creation; optional on-device prompt expansion; streak update | Timeline of entries; method badges | SwiftData `JournalEntry`; CloudKit | Voice input available; entries survive reinstall via CloudKit; 369 method shows morning/afternoon/evening slots |
| 12 | Moon streak with forgiveness | Automatic on listen/journal; visible in Tonight header | Daily listen/journal events | `StreakEngine`: +1 per day; monthly free grace card (Plus: 3) consumed on a missed day instead of resetting; streak stored in CloudKit | Streak count, grace cards remaining, moon fullness | `DailyRecord`, `StreakState` | Missing one day does not zero the streak while grace remains; reinstall preserves streak |
| 13 | Morning moon letter | Morning open or notification → affirmation card; swipe left to save, right to regenerate | Date, wish context | Daily affirmation generator (on-device or cached) | Card with daily affirmation | `DailyRecord`, saved affirmations | Morning card appears once per day; saving is persistent |
| 14 | Time Capsule wish closure + celebration card | Wish creation → optional target date → notification at date → "It Happened!" → celebration card → share sheet | Target date, fulfillment confirmation | Status transition growing → fulfilled; card rendering with wish text + moon phase of the wish date | Celebration image to share to TikTok/IG | `Wish.status`, `fulfilledAt` | Fulfilled wish shows a generated card; share sheet opens with an image |
| 15 | Weekly moon report | Sunday → report card of wishes progress, listen days, streaks → share | Weekly records | Aggregation over `DailyRecord` and `Wish` | Shareable weekly summary card | Derived data | Report matches actual weekly data; share produces an image |
| 16 | Paywall (soft, after value) | After 3rd free generation / first overnight tap / day-7 full moon | Purchase intent | StoreKit 2 purchase flow; entitlements; restore; manage subscription deep link | Subscription state; feature unlock | Keychain/UserDefaults entitlement cache | Paywall appears with title, length, price, trial terms, privacy/terms links, restore |
| 17 | Profile & settings hub | Tab 5 → subscription status, BYO API, cloud sync status, grace cards, export, support, legal | Settings interactions | Settings model; diagnostics | Toggles, status rows, links | UserDefaults; Keychain for API keys | Every row functional; cloud sync indicator reflects real state |
| 18 | BYO API configuration (multi-provider) | Profile → BYO API → pick provider → enter key and optional base URL/model → test connection → save | API key, provider, base URL, model name | Keychain storage; request builder for OpenAI-compatible chat; connection test | Success/failure state; unlimited generation enabled | Keychain + UserDefaults (non-secret fields) | Key never logged; test call reports latency/status; wrong key yields actionable error |
| 19 | Cloud sync (SwiftData + CloudKit) | Automatic; status in Profile | Local mutations | `ModelContainer(cloudKitDatabase: .automatic)`; sync monitor | "All changes synced" indicator; cross-device data | CloudKit private database | Reinstall after sign-in restores wishes, sessions metadata, journal, streak |
| 20 | Data export (audio/journal/vision board) | Profile → Export → choose package → share sheet / Files | Selection | Bundling of m4a files + JSON manifest of journal and wishes | zip/share package | Temporary export folder | Export opens share sheet; content matches user selection |
| 21 | In-app support ticket + FAQ | Profile → Support → FAQ list / new ticket form | Subject, message, email (prefilled) | POST to feedback backend; validation; retry | Ticket confirmation; FAQ answers | Backend + local draft | Submission succeeds or shows retry guidance; FAQ answers built in |
| 22 | Notifications (evening ritual, trial ending, Time Capsule) | Automatic scheduling | User permission | UNUserNotificationCenter local notifications at 21:30, trial-end reminders, target dates | Banners | Scheduled requests | Permission prompt explains value; notifications fire at correct local times |
| 23 | SOS calm mode | Profile / Tonight → SOS → immediate calming audio + breathing guide | Tap | Plays a pre-rendered calming track with breathing cue | 60-second guided calm session | Playback state | Reachable in two taps; works offline |
| 24 | 21 rituals / soundscape catalog | During generation or playback → choose soundscape (theta / 432Hz / rain / lo-fi / none …) | Selection | Soundscape catalog and gating (3 free, 21 for Plus) | Background audio mixed into render | `AudioSession.soundscape` | Free tier limited to 3; Plus unlocks all; selection is honored in the render |
| 25 | Personal Voice | Profile → Personal Voice → request authorization → select personal voice | System personal voice authorization | AVSpeechSynthesizer personal voice selection; fallback to premium system voice | Personal-voice narration | UserDefaults selection | Authorization explained; denial falls back gracefully |
| 26 | Face ID app lock | Profile → toggle Face ID lock → authenticate on launch | Biometric permission | LocalAuthentication gate on foreground | Lock screen cover | UserDefaults flag | Toggle works; failed auth keeps content hidden |
| 27 | Monthly cloud quota accounting | Every Plus cloud generation | User ID, month | Worker KV counter + local mirror; clear remaining count and reset date | Quota display; explicit error codes | Worker KV + local cache | Remaining quota visible; over-quota gives recovery date and BYO suggestion |

### Sub-Features & Detail Interactions

| # | Parent Feature | Sub-Feature | Detail Description | Interaction Pattern |
|---|---------------|-------------|--------------------|---------------------|
| 1.1 | Onboarding | Sign in with Apple is optional | Browsing and free generation work without an account; CloudKit sync requires the Apple ID signed into the device | Tap skip |
| 1.2 | Onboarding | Streaming script preview | While generating, affirmation lines appear one by one instead of a blank spinner | Auto animation |
| 1.3 | Onboarding | Domain cards | Four large cards: Love / Money / Career / Myself | Tap |
| 2.1 | Tonight | Moon fullness from streak | Moon disc grows with streak up to a full moon | Animation |
| 2.2 | Tonight | Morning vs evening layout | Morning shows the moon letter; evening shows the ritual buttons | Time-based |
| 3.1 | New Wish | Chip-only triage | All follow-up answers are chips; keyboard appears only if the user taps it | Tap chips |
| 4.1 | Generation | Raycast fallback chain | Cloud → retry → on-device → curated preset | Automatic |
| 5.1 | Audio | Breathing gaps | 1.2s silence between sentences; 1s fade in/out | Fixed |
| 6.1 | LoopGuard | Auto re-render | Second render attempt before surfacing failure | Automatic |
| 7.1 | Sleep mode | Lock screen controls | Now Playing metadata and remote commands | System controls |
| 8.1 | My Channel | Group by wish | Sections per wish with session count | List sections |
| 9.1 | Presets | Curated categories | Sleep, confidence, abundance, calm, love | Filter chips |
| 10.1 | Board | 9-image cap | Adding a 10th image prompts replacement | Tap/confirm |
| 11.1 | Journal | Speech dictation | Mic button fills the text field; can be edited before saving | Tap mic |
| 12.1 | Streak | Grace card UI | Cloud-covered moon icon shows remaining grace | Info sheet |
| 13.1 | Moon letter | Swipe actions | Left saves, right regenerates | Swipe |
| 14.1 | Time Capsule | Celebration share | Renders image with wish text and the moon phase of the wish date | Share sheet |
| 15.1 | Weekly report | Sunday notification | Local notification prompting the weekly report | Notification tap |
| 16.1 | Paywall | Three value peaks | 3rd free generation, first overnight tap, day-7 full moon | Contextual sheet |
| 17.1 | Profile | Diagnostics | Version, build, engine availability, quota, sync status | List |
| 18.1 | BYO API | Connection test | Sends a minimal completion request and shows status + latency | Button |
| 19.1 | Cloud sync | Sync indicator | Live "synced / syncing / offline" state | Status row |
| 21.1 | Support | Prefilled metadata | App version, iOS version, device model attached to ticket | Automatic |
| 22.1 | Notifications | Trial reminder | 2-day-before-trial-end local reminder when trial detected | Scheduled |
| 24.1 | Soundscapes | Gating labels | Lock badges for Plus-only soundscapes | Badge |
| 25.1 | Personal Voice | Authorization education | Sheet explains what the voice is used for before requesting | Sheet |
| 26.1 | Face ID | Re-lock on background | Locks when app leaves foreground | Automatic |

### Cross-Feature Dependencies

| Dependency | Source Feature | Target Feature | Data Passed | Trigger Condition |
|------------|---------------|----------------|-------------|-------------------|
| Wish → session | New Wish | My Channel | Wish title, category, sessions | After successful generation |
| Session → streak | Audio playback / Journal save | Tonight streak | Daily listen/journal event | First qualifying action of the day |
| Wish → Time Capsule | New Wish target date | Notification + celebration | Target date, wish ID | Notification scheduled at creation |
| Board photo → script | Vision Board | New Wish generation | Image (Base64/multipart) + caption | User taps generate from photo |
| Entitlement → generation routing | Paywall / Profile | AIEngineRouter | `isPlusActive`, BYO key presence | Every generation request |
| Cloud quota → Paywall | Generation | Paywall | Quota exhausted state | Worker returns quota exceeded |
| Moon phase → celebration card | Onboarding / Wish date | Time Capsule card | Phase for date | Card render |
| Journal → weekly report | Journal | Weekly report | Entry counts, methods | Sunday aggregation |

**Verification**: 27 primary features, 26 sub-features, 8 cross-feature dependencies — matches the Chinese guide's feature set (onboarding, generation, audio, overnight, library, board, journal, streak, time capsule, weekly report, paywall, profile, BYO, cloud, export, support, notifications, SOS, rituals, personal voice, lock, quota).

---

## Apple Design Guidelines Compliance

- **HIG — Onboarding**: value before permission; Sign in with Apple optional; permissions (notifications, microphone, personal voice, Face ID) requested in context with a purpose string.
- **HIG — Audio**: `AVAudioSession` category `.playback` with `.mixWithOthers`; Now Playing info; background audio capability; interruption and route-change handling.
- **HIG — Dynamic Type / VoiceOver**: all text uses semantic styles; Reduce Motion replaces the moon animation with a static moon; controls have accessibility labels.
- **HIG — Color**: dark-first interface with sufficient contrast on the midnight palette; gold used for one primary action per screen.
- **App Review 2.1(a)**: no dead ends; every AI path has a fallback.
- **App Review 3.1.2(c)**: paywall includes title/length/price, trial terms, privacy and terms links, restore.
- **App Review 5.1.1**: privacy policy declares CloudKit usage, audio data stored locally, BYO keys stored in Keychain, no tracking.
- **Health & Fitness framing**: motivational content only; no medical claims; no diagnosis.

---

## Technical Architecture

- **Language**: Swift 5.9+ (Swift 6 concurrency-safe patterns where practical)
- **UI**: SwiftUI (iOS 17+), custom Canvas moon rendering, TimelineView animations
- **Persistence**: SwiftData with `ModelConfiguration(cloudKitDatabase: .automatic)`
- **Audio**: AVFoundation — `AVSpeechSynthesizer`, `AVAudioEngine` offline render, `AVQueuePlayer`, `AVAudioSession`
- **AI**: 
  - Apple Foundation Models (`import FoundationModels`, `@available(iOS 26, *)`) — free/offline engine
  - GLM-5.3-Flash via shared Cloudflare Worker proxy (OpenAI-compatible `/chat/completions`)
  - BYO OpenAI-compatible endpoints with user keys in Keychain
- **Purchases**: StoreKit 2 (native) for subscriptions and consumable booster; entitlement cache
- **Notifications**: UserNotifications (local scheduling)
- **Biometrics**: LocalAuthentication
- **Networking**: URLSession async/await
- **Security**: Keys in Keychain; no secrets in source; no analytics SDKs

### Module Structure
```
Moonwish/
├── App/
│   ├── MoonwishApp.swift
│   └── AppEnvironment.swift
├── Models/
│   ├── Wish.swift
│   ├── AudioSession.swift
│   ├── DailyRecord.swift
│   ├── JournalEntry.swift
│   ├── BoardItem.swift
│   └── StreakState.swift
├── Services/
│   ├── AIEngineRouter.swift
│   ├── AppleIntelligenceService.swift
│   ├── GLMProxyService.swift
│   ├── BYOAPIService.swift
│   ├── ScriptValidator.swift
│   ├── AudioMixer.swift
│   ├── LoopGuard.swift
│   ├── TTSVoiceCatalog.swift
│   ├── SoundscapeCatalog.swift
│   ├── StreakEngine.swift
│   ├── MoonPhaseCalculator.swift
│   ├── CloudQuotaService.swift
│   ├── SubscriptionManager.swift
│   ├── ExportService.swift
│   ├── NotificationService.swift
│   └── SupportService.swift
├── Features/
│   ├── Onboarding/
│   ├── Tonight/
│   ├── NewWish/
│   ├── Player/
│   ├── Channel/
│   ├── Board/
│   ├── Journal/
│   ├── TimeCapsule/
│   ├── Paywall/
│   └── Profile/
├── DesignSystem/
│   ├── Theme.swift
│   ├── MoonCanvas.swift
│   └── Components.swift
├── Resources/
│   ├── Assets.xcassets
│   ├── Presets/ (20+ bundled m4a)
│   └── Soundscapes/
└── Info.plist / PrivacyInfo.xcprivacy
```

---

## ⚠️ Data Flow Diagram (MANDATORY)

```
Feature: Wish → Personalized audio
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── Wish text + domain + 3 chip answers                  │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── NewWishViewModel → validate → AIEngineRouter         │
│       │   free/offline → Apple FM; Plus → GLM proxy;      │
│       │   BYO → direct endpoint                           │
│       │                                                   │
│  Validation                                               │
│  └── ScriptValidator (JSON schema, length, sections)      │
│       │   fail → retry once → on-device → preset          │
│       │                                                   │
│  Rendering                                                │
│  └── AudioMixer (voice + soundscape) → m4a local file     │
│       │   LoopGuard crossfade/continuity check            │
│       │                                                   │
│  Persistence                                              │
│  └── SwiftData Wish + AudioSession metadata; CloudKit     │
│       │                                                   │
│  Display Output                                           │
│  └── PlayerView (loop / 8h / fade-out) + My Channel       │
│       │                                                   │
│  Cross-Feature Output                                     │
│  └── DailyRecord listen event → StreakEngine → Tonight    │
└───────────────────────────────────────────────────────────┘
```

```
Feature: Streak
┌───────────────────────────────────────────────────────────┐
│  Input: listen or journal event for today                 │
│  Processing: StreakEngine (+1, grace card on missed day)  │
│  Persistence: DailyRecord + StreakState (CloudKit)        │
│  Output: moon fullness in Tonight, grace card count       │
│  Cross-feature: weekly report aggregation                 │
└───────────────────────────────────────────────────────────┘
```

```
Feature: Paywall / entitlement
┌───────────────────────────────────────────────────────────┐
│  Input: purchase tap or context trigger                   │
│  Processing: StoreKit 2 products → transaction verify     │
│  Persistence: entitlement cache (UserDefaults/Keychain)   │
│  Output: Plus unlocked (overnight, 21 soundscapes, GLM)   │
│  Cross-feature: AIEngineRouter + quota display            │
└───────────────────────────────────────────────────────────┘
```

```
Feature: Vision board photo → audio
┌───────────────────────────────────────────────────────────┐
│  Input: photo(s) up to 9 + optional caption               │
│  Processing: board layout; vision-capable engine (GLM/BYO)│
│              or local caption heuristic for free tier     │
│  Persistence: BoardItem + AudioSession                    │
│  Output: collage + generated audio in My Channel          │
└───────────────────────────────────────────────────────────┘
```

```
Feature: Time Capsule
┌───────────────────────────────────────────────────────────┐
│  Input: wish + target date                                │
│  Processing: schedule local notification; on "It Happened"│
│              set fulfilled, render card with moon phase   │
│  Persistence: Wish.status / fulfilledAt                   │
│  Output: shareable celebration image                      │
└───────────────────────────────────────────────────────────┘
```

---

## Implementation Flow

1. Create Xcode project (xcodegen if absent), SwiftUI app target, iOS 17.0 deployment, bundle `com.zzoutuo.Moonwish`.
2. Design system: midnight palette, moon canvas, gold primary button, card styles.
3. SwiftData models + CloudKit container + sync status service.
4. Onboarding state machine (domain → wish → chips → generate → play).
5. AI layer: `AIEngineRouter`, Apple FM service (iOS 26 gate), GLM proxy service, BYO service, `ScriptValidator`.
6. Audio layer: voice catalog, soundscape catalog, offline mixer, loop guard, player service.
7. Tonight home with moon phase and streak engine.
8. New Wish flow + generation progress UI.
9. My Channel library and player controls (loop, 8h, fade).
10. Preset library (20+ bundled tracks) and SOS mode.
11. Vision board, journal, weekly report.
12. Time Capsule and celebration card.
13. StoreKit 2 paywall, entitlement cache, restore, manage subscription.
14. Profile: BYO settings, cloud sync status, export, support ticket, notifications, Personal Voice, Face ID lock.
15. PrivacyInfo.xcprivacy, Info.plist usage strings, background audio capability.
16. Build & run on iPhone and iPad simulators; fix warnings; verify offline behavior.

---

## UI/UX Design Specifications

- **Design language**: "Midnight Serenity"
- **Background**: deep midnight gradient `#0B1026 → #1A1F3D`
- **Primary action**: moonlight gold `#F5D9A8`
- **Accent**: moon halo white `#EEF2FF`
- **Cards**: iOS 26 Liquid Glass aesthetic; on iOS 17+ use layered translucent materials with subtle stroke
- **Typography**: New York (serif) for ritual headings, SF Pro for body; Dynamic Type throughout
- **Motion**: 4-7-8 moon breathing animation; moon waxing during generation; celebration ring fireworks; Reduce Motion → static moon
- **Layout trends**: Spotify-style horizontal audio cards; Duolingo-style streak bar; Apple Journal-style timeline
- **Tabs (5 max)**: Tonight (default), My Channel, Board, Journal, Profile
- **One primary button per screen**, gold, large tap target
- **Accessibility**: VoiceOver labels, minimum 44pt targets, contrast-checked text, VoiceOver order matched to visual order

---

## Code Generation Rules

- One feature per module; high cohesion, low coupling.
- Semantic naming; clear file structure.
- No comments unless the logic is non-obvious.
- SwiftUI + native frameworks first; no third-party dependencies unless strictly necessary.
- Apple-native first: StoreKit 2 instead of a purchase SDK; AVFoundation for audio; SwiftData for persistence.
- Never hardcode secrets; never log API keys; never embed the GLM key.
- All AI calls use structured output validation with deterministic fallbacks.
- Version read from `Bundle.main.infoDictionary`, never hardcoded.
- Free tier is entitlement-driven, no generation counters.

---

## Build & Deployment Checklist

- [ ] Bundle ID `com.zzoutuo.Moonwish`, signing team JP4TN5PTS3
- [ ] Deployment target 17.0; Apple FM code guarded by `@available(iOS 26, *)`
- [ ] Background audio mode `audio` enabled
- [ ] Usage strings: microphone (journal dictation), speech recognition (if used), notifications
- [ ] `PrivacyInfo.xcprivacy` declares no tracking, local audio storage, no required-reason APIs misuse
- [ ] StoreKit products: `com.zzoutuo.Moonwish.plus.monthly`, `com.zzoutuo.Moonwish.plus.yearly`, `com.zzoutuo.Moonwish.cloud.booster`
- [ ] Policies: privacy, terms, support deployed to GitHub Pages
- [ ] App Store metadata: name Moonwish, subtitle Manifest While You Sleep, Health & Fitness
- [ ] Test on iPhone and iPad simulators; verify offline playback and cloud-sync messaging
- [ ] In-app review notes describing Apple Intelligence requirement and BYO option

---

## Guide References

- https://github.com/asunnyboy861/GLM-Cloudflare (private worker proxy repo)
- https://docs.bigmodel.cn (GLM API documentation)
- https://api.z.ai/api/paas/v4/chat/completions (international GLM endpoint)
- Open-source references from the guide (architecture inspiration only): MacPaw/OpenAI (MIT), Recouse/EventSource (MIT), ggruen/CloudKitSyncMonitor (MIT), RevenueCat/purchases-ios (MIT), exyte/Grid (MIT), exyte/MediaPicker (MIT), apple/coreai-models, apple/foundation-models-utilities, anthropics/ClaudeForFoundationModels
- **Avoid**: meditohq/medito-app (AGPL-3.0) — architecture reference only, no code copying
