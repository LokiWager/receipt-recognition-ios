# Receipt Scanner iOS

A privacy-focused iOS app to scan, parse, and analyze grocery receipts from major Canadian retailers.

## Features

- **Local-first**: All processing happens on-device using Apple's Vision Framework
- **Privacy-focused**: User data is stored locally using SwiftData
- **Multi-retailer support**: Costco, T&T, Walmart, No Frills, Food Basics
- **Bilingual OCR**: Supports English and Chinese text recognition

## Requirements

- iOS 18.0+
- Xcode 15.4+
- Swift 6.0
- XcodeGen (for project generation)

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/receipt-recognition-ios.git
cd receipt-recognition-ios
```

### 2. Install dependencies

```bash
# Install XcodeGen
brew install xcodegen

# Install Ruby dependencies
bundle install
```

### 3. Generate Xcode project

```bash
xcodegen generate
```

### 4. Open in Xcode

```bash
open ReceiptScanner.xcodeproj
```

## Project Structure

```
ReceiptScanner/
├── App/                    # App entry point and main views
├── Models/                 # SwiftData models (Receipt, Item)
├── Views/                  # SwiftUI views
├── ViewModels/             # View models (business logic)
├── Services/               # OCR, Parsing, Persistence services
├── Coordinators/           # Navigation coordinators
└── Resources/              # Assets, localizations
```

## Architecture

The app follows **MVVM-C** (Model-View-ViewModel-Coordinator) pattern:

- **Models**: SwiftData entities for Receipt and Item
- **Views**: SwiftUI views for UI
- **ViewModels**: Business logic and state management
- **Coordinators**: Navigation flow management
- **Services**: OCR, parsing, and database operations

## CI/CD

The project uses GitHub Actions for continuous integration:

- **CI Workflow**: Runs on pull requests - builds and runs tests
- **Deploy Workflow**: Runs on push to main - builds and deploys to TestFlight

### Setting up CI/CD

1. Create a private repository for Match certificates
2. Configure the following GitHub secrets:
   - `MATCH_DEPLOY_KEY`: SSH key for certificates repo
   - `MATCH_PASSWORD`: Encryption password for Match
   - `MATCH_GIT_URL`: URL of certificates repository
   - `APP_STORE_CONNECT_API_KEY_ID`: App Store Connect API Key ID
   - `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect Issuer ID
   - `APP_STORE_CONNECT_API_KEY_CONTENT`: Base64-encoded API key content

## Fastlane

### Available lanes

```bash
# Run tests
bundle exec fastlane test

# Build debug
bundle exec fastlane build_debug

# Deploy to TestFlight
bundle exec fastlane beta

# Sync development certificates
bundle exec fastlane sync_dev_certs
```

## License

This project is proprietary and confidential.
