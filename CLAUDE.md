# CLAUDE.md

This file provides guidance to Claude Code when working with the HeroesAndMore iOS app.

## Project Overview

Native SwiftUI iOS application for the HeroesAndMore collectibles marketplace. Connects to the Django REST API.

## Tech Stack

- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Minimum iOS**: 16.0
- **Architecture**: MVVM with async/await
- **Auth**: JWT tokens stored in Keychain
- **Build/Deploy**: Codemagic CI/CD to TestFlight

## Related Repositories

| Repo | URL |
|------|-----|
| Web (API) | https://github.com/nadermx/heroesandmore |
| Android | https://github.com/nadermx/heroesandmore-android |
| iOS | https://github.com/nadermx/heroesandmore-ios (this repo) |

## Team

| Name | Email |
|------|-------|
| John | john@nader.mx |
| Tony | tmgormond@gmail.com |
| Jim | jim@sickboys.com |

## Project Structure

```
HeroesAndMore/
├── App/                    # App entry, config
│   ├── HeroesAndMoreApp.swift
│   ├── ContentView.swift
│   └── Config.swift        # API URLs, keys
├── Models/                 # Data models (Codable)
├── Services/               # API client, auth, network
│   ├── APIClient.swift     # Main HTTP client
│   ├── AuthManager.swift   # JWT auth state
│   ├── KeychainService.swift
│   └── *Service.swift      # Feature services
└── Views/                  # SwiftUI views
    ├── Auth/
    ├── Marketplace/
    ├── Collections/
    ├── PriceGuide/
    ├── Scanner/
    ├── Profile/
    ├── Alerts/
    ├── Social/
    └── Components/
```

## API Configuration

Edit `HeroesAndMore/App/Config.swift`:
```swift
#if DEBUG
static let apiBaseURL = "http://localhost:8000/api/v1"
#else
static let apiBaseURL = "https://www.heroesandmore.com/api/v1"
#endif
```

## Building

### Without Mac (Codemagic)
1. Push to GitHub
2. Codemagic builds on their Macs
3. Uploads to TestFlight automatically

### With Mac (Local)
```bash
open HeroesAndMore.xcodeproj
# Cmd+R to run in simulator
```

## Key Patterns

### API Calls
```swift
let response: PaginatedResponse<Listing> = try await APIClient.shared.request(
    path: "/marketplace/listings/",
    method: .get,
    queryItems: [URLQueryItem(name: "page", value: "1")]
)
```

### Authentication
```swift
@EnvironmentObject var authManager: AuthManager
// Login
await authManager.login(username: "user", password: "pass")
// Check auth
if authManager.isAuthenticated { ... }
```

### Views
All views use SwiftUI with `@State`, `@StateObject`, and `@EnvironmentObject` for state management.

## TestFlight Distribution

1. Requires Apple Developer Account ($99/year)
2. Configure Codemagic with App Store Connect API key
3. Push to `main` branch triggers build
4. Build auto-uploads to TestFlight
5. Invite testers via App Store Connect

## Common Issues

**Build fails on Codemagic**: Check signing certificates and provisioning profiles.

**API returns 401**: Token expired, AuthManager should auto-refresh.

**Images not loading**: Check `Info.plist` has `NSAppTransportSecurity` configured for HTTP (debug only).
