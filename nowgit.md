# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | Moonwish |
| **Git URL** | git@github.com:asunnyboy861/Moonwish.git |
| **Repo URL** | https://github.com/asunnyboy861/Moonwish |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ Enabled (from `/docs`) |

## App Store

| Item | Value |
|------|-------|
| **Apple App ID** | 6832170798 |
| **App Store URL** | https://apps.apple.com/us/app/id6832170798?mt=8 |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/Moonwish/ | ✅ Active |
| Support | https://asunnyboy861.github.io/Moonwish/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/Moonwish/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/Moonwish/terms.html | ✅ Active |

## Repository Structure

```
Moonwish/
├── Moonwish.xcodeproj/            # Xcode project (generated with xcodegen)
├── Moonwish/                      # iOS app source
│   ├── App/
│   ├── DesignSystem/
│   ├── Models/
│   ├── Services/
│   ├── Views/
│   ├── Resources/
│   ├── Info.plist
│   ├── Moonwish.entitlements
│   └── PrivacyInfo.xcprivacy
├── MoonwishTests/                 # Unit tests
├── docs/                          # Policy pages (GitHub Pages source)
│   ├── index.html
│   ├── support.html
│   ├── privacy.html
│   └── terms.html
├── .github/workflows/
│   └── deploy.yml
├── project.yml                    # xcodegen source of truth
├── us.md
├── capabilities.md
├── icon.md
├── price.md
├── nowgit.md
├── keytext.md                     # Excluded from repo (.gitignore, confidential ASO)
├── COMPETITOR_REPORT.md           # Excluded from repo (.gitignore, confidential)
└── app_audit.md                   # Excluded from repo (.gitignore)
```

## Notes

- `GLMProxySecret.txt` is local-only and gitignored. It is excluded from Release builds through `EXCLUDED_SOURCE_FILE_NAMES`.
- The GLM Worker whitelist entry is `appId = moonwish`, `bundleId = com.zzoutuo.Moonwish`.
- Dependency-free build: SwiftUI, SwiftData, AVFoundation, StoreKit 2, CloudKit, Speech, LocalAuthentication.
