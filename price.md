# Pricing Configuration

## Monetization Model: Subscription (IAP) with Consumable Booster

Moonwish is free to download with a genuinely usable free tier. Plus is an auto-renewable subscription (monthly or annual with a 7-day trial). A consumable "Cloud Booster" adds 30 GLM cloud generations for heavy months. Users who configure their own API key get unlimited generation on their own quota.

## Subscription Group
- **Group Name**: Moonwish Plus
- **Reference Name**: Moonwish Plus
- **Products in group**: `com.zzoutuo.Moonwish.plus.monthly`, `com.zzoutuo.Moonwish.plus.yearly`

## Subscription Tiers (Auto-Renewable)

### 1. Plus Monthly
- **Reference Name**: Moonwish Plus Monthly
- **Product ID**: `com.zzoutuo.Moonwish.plus.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $7.99 USD per month
- **Display Name**: `Moonwish Plus Monthly` (21 chars, ≤35 ✅)
- **Description**: `Daily AI audio, overnight sleep mode, 21 soundscapes` (52 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: Moonwish Plus
- **Restore Purchases**: ✅ Required

### 2. Plus Yearly
- **Reference Name**: Moonwish Plus Yearly
- **Product ID**: `com.zzoutuo.Moonwish.plus.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $29.99 USD per year (69% savings vs monthly)
- **Display Name**: `Moonwish Plus Yearly` (20 chars, ≤35 ✅)
- **Description**: `A year of sleep manifestation plus a 7-day free trial` (53 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: Moonwish Plus (same group as monthly)
- **Restore Purchases**: ✅ Required

## Consumable Products

### 1. Cloud Booster
- **Reference Name**: Moonwish Cloud Booster
- **Product ID**: `com.zzoutuo.Moonwish.cloud.booster`
- **Type**: Consumable (30 GLM cloud generations, no expiry)
- **Price**: $1.99 USD (consumable)
- **Display Name**: `30 Cloud Generations` (22 chars, ≤35 ✅)
- **Description**: `Adds 30 deep cloud-generated sessions to your account` (53 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: N/A — consumables are not restorable; balance is stored per account

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - Unlimited on-device AI-personalized audio sessions
  - 20+ curated preset audio library
  - Vision board with up to 9 photos
  - 369 / scripting / gratitude journal with voice dictation
  - Forgiving moon streak with one monthly grace card
  - System voices and 3 basic soundscapes
  - SwiftData + CloudKit automatic backup
  - Morning moon letter, weekly moon report, Time Capsule
- **Conversion hooks**:
  - Unlimited on-device AI sessions and 30 cloud-generated deep sessions each month
  - 8-hour seamless overnight mode with fade-out sleep timer
  - All 21 soundscapes and rituals plus Personal Voice
  - Audio download and export of your whole channel

## Pro Features Unlocked (All Paid Tiers)

| Feature | Free | Plus (Monthly / Yearly) |
|---------|:----:|:-----------------------:|
| Personalized AI session generation | Unlimited (on-device engine) | Unlimited Apple AI + 30 GLM cloud sessions per month |
| Overnight audio | ❌ | ✅ 8-hour seamless loop with sleep fade timer |
| Preset audio library | 20+ tracks | 20+ tracks |
| Soundscapes | 3 basic | All 21 |
| Personal Voice narration | ❌ | ✅ |
| Audio download & export | ❌ | ✅ |
| Vision board photo → AI session | Local caption mode only | ✅ Vision-capable cloud engine |
| Journal, streak, moon letter, Time Capsule | ✅ | ✅ |
| Cloud backup (SwiftData + CloudKit) | ✅ | ✅ |
| SOS calm mode | ✅ | ✅ |
| Weekly moon report | ✅ | ✅ |
| BYO API key unlimited generation | ✅ (own key) | ✅ (own key) |
| Cloud Booster (30 generations, consumable) | ✅ Separate $1.99 purchase | ✅ Separate $1.99 purchase |

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial (auto-converts to paid annual subscription)
- **Available for**: Plus Yearly only

## Policy Pages Required
- Support Page: ✅ (includes subscription management and cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (required for auto-renewable subscriptions)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms included in Terms of Use
- [x] Cancellation instructions included in Support Page
- [x] Pricing clearly stated in PaywallView (title, length, price per option)
- [x] Free trial terms included: "7 days free, then $29.99/year, cancel anytime"
- [x] Restore purchases functionality implemented (StoreKit 2 `Transaction.currentEntitlements`)
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options or competitor prices
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] BYO key users generate unlimited on their own quota — no free-generation counter dead code (`canGenerate = isPlusActive || hasBYOKey || appleIntelligenceAvailable`)
