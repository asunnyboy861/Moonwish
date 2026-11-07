# App Review Information

## App Description for Reviewers

Moonwish is a bedtime manifestation companion. A user speaks or types one wish, answers up to three tap-only follow-up questions, and receives a personalized affirmation audio rendered locally on the device. The audio can loop overnight with a fade-out timer. Wishes, journal entries, vision board items, and streaks are stored with SwiftData and synchronized through the user's private CloudKit database.

Moonwish is motivational and mindfulness content. It does not provide medical advice, diagnosis, or treatment.

## AI Backends

Moonwish uses three AI paths, in this order:

1. **Apple Intelligence (default, free)**: on supported devices (iPhone 15 Pro or later, iOS 26 or later), scripts are generated on-device with Foundation Models. No key and no account are required.
2. **Moonwish Cloud (Plus)**: scripts can be generated through the app's own Cloudflare Worker proxy to GLM-5.3-Flash. The proxy validates StoreKit 2 subscription receipts.
3. **Custom API key (optional)**: a user may configure any OpenAI-compatible endpoint. The key is stored in the iOS Keychain and is only sent to the endpoint the user chooses.

If no engine is available (for example, iOS 17-25 on older hardware, or a simulator), the app falls back to a deterministic on-device script composer so the user always receives audio. No generation button ever dead-ends in an error.

### Reviewer steps on an Apple Intelligence-capable device
1. Launch the app and tap "Create my first wish".
2. Choose a life area, type one wish, tap through the suggested chips, then tap "Generate my audio".
3. The script streams on screen, then the personalized audio plays.

### Reviewer steps on a device without Apple Intelligence
1. Complete the same steps. The app uses its on-device script composer; audio is still produced and playable.
2. To test a cloud model, open Profile → Custom API key, enter your own OpenAI-compatible key and endpoint, then tap "Test connection".

## Subscription Testing

| Product ID | Type | Price | Trial |
|------------|------|-------|-------|
| `com.zzoutuo.Moonwish.plus.monthly` | Auto-renewable | $7.99 / month | None |
| `com.zzoutuo.Moonwish.plus.yearly` | Auto-renewable | $29.99 / year | 7 days |
| `com.zzoutuo.Moonwish.cloud.booster` | Consumable | $1.99 | None |

The paywall is reachable from Tonight (crown button), Profile → Explore Moonwish Plus, and any locked premium feature (overnight mode, Plus soundscapes, downloads).

## Required Links (In-App)

- Privacy Policy: https://asunnyboy861.github.io/Moonwish/privacy.html
- Terms of Use: https://asunnyboy861.github.io/Moonwish/terms.html
- Support: https://asunnyboy861.github.io/Moonwish/support.html

These links appear in the Paywall (below the subscribe button) and in Profile → Support & legal.

## Privacy Notes

- No tracking SDKs and no advertising identifiers.
- Audio files are rendered and stored locally on the device.
- CloudKit stores wishes, journal entries, vision board metadata, sessions metadata, and streak data in the user's private database.
- Custom API keys are stored in the iOS Keychain.
- The vision board stores user-selected photos in the app's local Application Support directory.
- Microphone and speech recognition are used only when the user taps a dictation button.

## Review Notes

- The app requests notification permission only after the user enables the evening reminder, and explains the value in context.
- Personal Voice authorization is requested only when the user turns on Personal Voice in Profile.
- Face ID is optional and controlled by a user toggle in Profile.
- The minimum deployment target is iOS 17.0; Apple Intelligence code is guarded with `@available(iOS 26.0, *)`.
