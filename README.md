# HeroesAndMore iOS App

Native SwiftUI iOS application for the HeroesAndMore collectibles marketplace.

## Features

- **Marketplace**: Browse, search, and filter listings. View details, place bids, make offers.
- **Collections**: Create and manage collections, track values over time.
- **Price Guide**: Browse price data, view charts, set price alerts.
- **Scanner**: Scan collectibles using camera to identify and price items.
- **Profile**: Manage orders, offers, notifications, wishlists, and settings.
- **Social**: Messages, following, forums.

## Requirements

- iOS 16.0+
- Xcode 15.0+ (for building)
- Apple Developer Account (for TestFlight distribution)

## Project Structure

```
ios/
├── HeroesAndMore/
│   ├── App/                    # App entry, configuration
│   │   ├── HeroesAndMoreApp.swift
│   │   ├── ContentView.swift
│   │   └── Config.swift
│   ├── Models/                 # Data models
│   ├── Services/               # API client, auth, network
│   └── Views/                  # SwiftUI views
│       ├── Auth/
│       ├── Marketplace/
│       ├── Collections/
│       ├── PriceGuide/
│       ├── Scanner/
│       ├── Profile/
│       ├── Alerts/
│       ├── Social/
│       └── Components/
├── HeroesAndMore.xcodeproj/
├── codemagic.yaml              # CI/CD configuration
└── exportOptions.plist         # App Store export options
```

## Building Without a Mac

This project uses Codemagic for cloud-based iOS builds:

1. **Create accounts**:
   - Apple Developer Program ($99/year): https://developer.apple.com/programs/
   - Codemagic (free tier): https://codemagic.io

2. **Configure Codemagic**:
   - Connect your GitHub repository
   - Add App Store Connect API key credentials
   - Codemagic will handle code signing automatically

3. **Push to trigger builds**:
   - Push to `main` branch triggers TestFlight deployment
   - Push to any branch triggers development build

## Local Development (Requires Mac)

```bash
cd ios
open HeroesAndMore.xcodeproj
```

Select a simulator and press Cmd+R to run.

## API Configuration

The app connects to:
- **Debug**: `http://localhost:8000/api/v1`
- **Release**: `https://www.heroesandmore.com/api/v1`

To change the API URL, edit `HeroesAndMore/App/Config.swift`.

## TestFlight Distribution

Once builds are uploaded to App Store Connect:

1. Go to App Store Connect > Your App > TestFlight
2. Add internal testers (up to 100, instant access)
3. Add external testers (up to 10,000, requires review)
4. Testers receive email invitation
5. Testers install TestFlight app, then your app

## Environment Variables (Codemagic)

Set these in Codemagic dashboard:

- `APP_STORE_CONNECT_ISSUER_ID`: Your App Store Connect API issuer ID
- `APP_STORE_CONNECT_KEY_IDENTIFIER`: Your API key ID
- `APP_STORE_CONNECT_PRIVATE_KEY`: Your .p8 private key content
- `CERTIFICATE_PRIVATE_KEY`: Code signing certificate (auto-managed by Codemagic)

## Architecture

- **SwiftUI**: Declarative UI framework
- **Async/Await**: Modern Swift concurrency
- **Actor isolation**: Thread-safe API client
- **Keychain**: Secure token storage
- **JWT**: API authentication

## License

Proprietary - HeroesAndMore
