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
- **Dependencies**: None (pure Swift + Apple frameworks)

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
├── App/                        # App entry, config
│   ├── HeroesAndMoreApp.swift  # @main entry point
│   ├── ContentView.swift       # Root navigation (MainTabView + auth gate)
│   └── Config.swift            # API URLs, keychain keys, pagination settings
│
├── Models/                     # Data models (Codable structs)
│   ├── User.swift              # User, Profile, AuthTokens, NotificationSettings
│   ├── Listing.swift           # Listing, Bid, Offer, AutoBid, AuctionEvent, Order
│   ├── Collection.swift        # Collection, CollectionItem, ValueSnapshot
│   ├── Order.swift             # Order, ShippingAddress, Review
│   ├── Alert.swift             # Notification, Wishlist, SavedSearch, PriceAlert
│   ├── PriceGuide.swift        # PriceGuideItem, GradePrice, SaleRecord
│   ├── Category.swift          # Category, SearchResult, AutocompleteResult
│   ├── Social.swift            # FeedItem, Conversation, Message, ForumThread
│   └── Scanner.swift           # ScanResult, ScanMatch, ScanSession
│
├── Services/                   # API client & feature services (all actors)
│   ├── APIClient.swift         # Main HTTP client, auth refresh, file uploads
│   ├── AuthManager.swift       # Login/register/logout, profile, device tokens
│   ├── KeychainService.swift   # Secure token storage (Security framework)
│   ├── MarketplaceService.swift # Listings, bidding, offers, orders
│   ├── CollectionService.swift # Collections CRUD, value tracking, import/export
│   ├── PriceGuideService.swift # Price guide items, grades, sales history
│   ├── AlertService.swift      # Notifications, wishlists, saved searches
│   ├── SocialService.swift     # Feed, following, messages, forums
│   ├── ScannerService.swift    # Image scanning, scan history
│   ├── CategoryService.swift   # Categories, search, autocomplete
│   └── NetworkMonitor.swift    # Connection detection (Network framework)
│
└── Views/                      # SwiftUI views
    ├── Auth/
    │   └── AuthView.swift      # Login/register with segmented picker
    ├── Marketplace/
    │   ├── MarketplaceView.swift
    │   ├── ListingDetailView.swift    # Includes BidSheet, OfferSheet, SellYoursCTA
    │   ├── CreateListingView.swift    # Create new listing form (Sell tab)
    │   └── SavedListingsView.swift
    ├── Collections/
    │   ├── CollectionsView.swift
    │   └── CollectionDetailView.swift
    ├── PriceGuide/
    │   ├── PriceGuideView.swift
    │   └── PriceGuideDetailView.swift
    ├── Scanner/
    │   └── ScannerView.swift
    ├── Profile/
    │   ├── ProfileView.swift
    │   ├── MyOrdersView.swift
    │   └── MyOffersView.swift
    ├── Alerts/
    │   ├── NotificationsView.swift
    │   ├── WishlistsView.swift
    │   ├── SavedSearchesView.swift
    │   └── PriceAlertsView.swift
    ├── Social/
    │   ├── FollowingView.swift
    │   ├── MessagesView.swift
    │   └── ForumsView.swift
    └── Components/
        ├── SearchBar.swift
        ├── PriceText.swift
        ├── AsyncImageView.swift
        ├── FullscreenImageViewer.swift  # Pinch-to-zoom, drag-pan, double-tap image viewer
        └── LoadingView.swift
```

## API Configuration

Edit `HeroesAndMore/App/Config.swift`:
```swift
#if DEBUG
static let apiBaseURL = "http://localhost:8000/api/v1"
#else
static let apiBaseURL = "https://www.heroesandmore.com/api/v1"
#endif

// Keychain Keys
static let accessTokenKey = "com.heroesandmore.accessToken"
static let refreshTokenKey = "com.heroesandmore.refreshToken"
static let userIdKey = "com.heroesandmore.userId"

// Pagination
static let defaultPageSize = 20

// Cache
static let imageCacheLimit = 100 // MB
static let cacheExpirationInterval = 3600 // seconds
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

## Running Tests

```bash
# Run from Xcode: Cmd+U
# Or via xcodebuild:
xcodebuild test -project HeroesAndMore.xcodeproj -scheme HeroesAndMore -destination 'platform=iOS Simulator,name=iPhone 15'
```

Test files in `HeroesAndMoreTests/`:
- `AuthManagerTests.swift` - Authentication flow tests
- `UserModelTests.swift` - User model encoding/decoding
- `MarketplaceServiceTests.swift` - Listing, bidding, offer operations
- `CollectionServiceTests.swift` - Collection CRUD and value tracking

## Key Patterns

### API Calls (Actor-based)
```swift
let response: PaginatedResponse<Listing> = try await APIClient.shared.request(
    path: "/marketplace/listings/",
    method: .get,
    queryItems: [URLQueryItem(name: "page", value: "1")]
)

// File upload
let result: ScanResult = try await APIClient.shared.upload(
    path: "/scanner/scan/",
    imageData: imageData,
    imageName: "scan.jpg"
)
```

### Authentication
```swift
@EnvironmentObject var authManager: AuthManager

// Login
await authManager.login(username: "user", password: "pass")

// Check auth
if authManager.isAuthenticated { ... }

// Logout
await authManager.logout()
```

### State Management
- `@EnvironmentObject` - Global app state (AuthManager, NetworkMonitor)
- `@StateObject` - Lifetime-scoped objects
- `@State` - Local view state
- `@Published` - Observable properties in manager classes

### Keychain Storage (Actor-based)
```swift
// Store token
await KeychainService.shared.set(key: Config.accessTokenKey, value: token)

// Retrieve token
let token = await KeychainService.shared.get(key: Config.accessTokenKey)

// Clear all
await KeychainService.shared.clear()
```

## Services API

### AuthManager
- `login(username, password)` - Stores tokens, fetches user
- `register(username, email, password, passwordConfirm)` - Auto-login on success
- `logout()` - Clears tokens and user
- `updateProfile(bio, location, website)` - PATCH profile
- `uploadAvatar(imageData)` - Multipart avatar upload
- `registerDeviceToken(token)` - FCM push registration
- `loginWithGoogle(idToken)` - OAuth integration

### MarketplaceService
- `getListings(page, category, search, listingType, condition, minPrice, maxPrice, sort)`
- `getListing(id)` - Full listing detail
- `placeBid(listingId, amount)` - Auction bidding
- `makeOffer(listingId, amount, message)` - Make offer
- `saveListing(id)` / `unsaveListing(id)` - Watch/save

### CollectionService
- `getMyCollections(page)` / `getPublicCollections(page)`
- `createCollection(name, description, isPublic)`
- `addItemToCollection()` - With grades, cert numbers, prices
- `getCollectionValue(id)` - Current valuation
- `exportCollection(id, format)` - JSON/CSV export
- `importCollection(fileData, fileName, collectionName)`

### PriceGuideService
- `getItems(page, category, search, sort)`
- `getGradePrices(itemId)` - Prices by grade (PSA 10, BGS 9.5, etc.)
- `getSales(itemId, page)` - Sales history
- `getPriceHistory(itemId, period)` - For charting
- `getTrending()` - Trending items

## Data Models

### PaginatedResponse
```swift
struct PaginatedResponse<T: Codable>: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [T]
}
```

### Key Enums
- `ListingType`: `.fixedPrice`, `.auction`
- `Condition`: `.mint`, `.nearMint`, `.excellent`, `.good`, `.fair`, `.poor`
- `OfferStatus`: `.pending`, `.accepted`, `.declined`, `.countered`, `.expired`
- `OrderStatus`: `.pending`, `.paid`, `.shipped`, `.delivered`, `.completed`, `.cancelled`

## CI/CD Configuration

**Codemagic** (`codemagic.yaml`):
- **Instance**: Mac mini M1
- **Triggers**: Push to main/release branches
- **Workflow**: Build -> Archive -> Upload to TestFlight

Environment variables needed:
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY_IDENTIFIER`
- `APP_STORE_CONNECT_PRIVATE_KEY`
- `CERTIFICATE_PRIVATE_KEY`

## TestFlight Distribution

1. Requires Apple Developer Account ($99/year)
2. Configure Codemagic with App Store Connect API key
3. Push to `main` branch triggers build
4. Build auto-uploads to TestFlight
5. Invite testers via App Store Connect

## Tab Bar Layout (MainTabView)

| Tab | View | Icon | Tag |
|-----|------|------|-----|
| Marketplace | `MarketplaceView` | `storefront` | 0 |
| Collections | `CollectionsView` | `square.grid.2x2` | 1 |
| Sell | `CreateListingView` | `plus.circle.fill` | 2 |
| Prices | `PriceGuideView` | `chart.line.uptrend.xyaxis` | 3 |
| Profile | `ProfileView` | `person.circle` | 4 |

Unauthenticated users see `AuthView` instead of tabs (gated in `ContentView`).

## Common Issues

**Build fails on Codemagic**: Check signing certificates and provisioning profiles.

**API returns 401**: Token expired, AuthManager should auto-refresh.

**Images not loading**: Check `Info.plist` has `NSAppTransportSecurity` configured for HTTP (debug only).

**Keychain errors in simulator**: Reset simulator (Device > Erase All Content and Settings).

## Bundle Info

- **Bundle ID**: `com.heroesandmore.app`
- **Version**: 1.0.0
- **Build**: 1
- **Xcode**: 15.0+
- **Swift**: 5.9+

## Permissions (Info.plist)

- `NSCameraUsageDescription` - Camera access for scanning
- `NSPhotoLibraryUsageDescription` - Photo library access for images
- `ITSAppUsesNonExemptEncryption` - false (no export compliance required)
