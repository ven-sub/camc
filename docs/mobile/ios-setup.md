# iOS Setup Guide

Complete guide for building and deploying iOS app locally and via TestFlight.

## Prerequisites

- macOS with Xcode installed
- Apple Developer account
- Node.js and npm
- Rust toolchain

## Quick Start

```bash
# Build for iOS simulator
./scripts/ios/build-local.sh simulator

# Build for device (requires signing)
./scripts/ios/build-local.sh device
```

## Detailed Setup

### 1. Install Dependencies

```bash
# Install npm dependencies
npm install

# Install Rust iOS targets
rustup target add aarch64-apple-ios          # Device
rustup target add aarch64-apple-ios-sim      # Simulator (ARM)
rustup target add x86_64-apple-ios           # Simulator (Intel, optional)
```

### 2. Initialize Tauri iOS Project

```bash
# First time only
npm run tauri:ios init

# Or manually
npm run tauri ios init
```

This generates the Xcode project in `src-tauri/gen/apple/`.

### 3. Code Signing Setup (Device Builds Only)

#### Install Provisioning Profile

1. Download your provisioning profile from Apple Developer
2. Double-click to install, or copy to:
   ```
   ~/Library/MobileDevice/Provisioning Profiles/
   ```

#### Install Signing Certificate

```bash
# Import certificate (if needed)
security import certificate.p12 -k ~/Library/Keychains/login.keychain

# Verify installed
security find-identity -v -p codesigning
```

You should see your Apple Distribution certificate.

#### Set Environment Variables

```bash
export DEVELOPMENT_TEAM="YOUR_TEAM_ID"
export PROVISIONING_PROFILE_UUID="YOUR_PROFILE_UUID"
```

Or set in `tauri.conf.json`:
```json
{
  "bundle": {
    "iOS": {
      "developmentTeam": "YOUR_TEAM_ID"
    }
  }
}
```

### 4. Building

#### For Simulator (No Signing Required)

```bash
# Using build script
./scripts/ios/build-local.sh simulator

# Or via npm
npm run tauri:ios:dev

# Or open in Xcode
open src-tauri/gen/apple/circuit-assistant-mobile-companion.xcodeproj
# Select a simulator, then press ⌘+R
```

#### For Physical Device

```bash
# Build IPA for device
./scripts/ios/build-local.sh device

# Output: build/ios-export/Circuit Assistant Mobile Companion.ipa
```

#### For TestFlight/App Store

```bash
# Build and upload
./scripts/ios/build-local.sh testflight
```

See [iOS TestFlight Guide](#testflight-deployment) below.

## Development Workflow

### Running on Simulator

```bash
# Hot reload development
npm run tauri:ios:dev
```

This will:
1. Build frontend with hot reload
2. Build Rust code
3. Launch in simulator
4. Auto-reload on changes

### Running from Xcode

Useful for debugging:

```bash
# Open project
open src-tauri/gen/apple/circuit-assistant-mobile-companion.xcodeproj

# Select target: circuit-assistant-mobile-companion_iOS
# Select simulator (e.g., iPhone 15 Pro)
# Press ⌘+R to build and run
```

**Important:** When running from Xcode directly, ensure you've run the fix script first:

```bash
./scripts/ios/fix-xcode-project.sh
```

### Debugging

#### View Logs

In Xcode:
- Open Debug area (⌘+⇧+Y)
- View console output

From terminal:
```bash
# View simulator logs
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Circuit"'
```

#### Rust Debugging

Enable backtraces in `src-tauri/src/lib.rs`:
```rust
std::env::set_var("RUST_BACKTRACE", "1");
```

#### JavaScript Debugging

Use Safari Web Inspector:
1. Open Safari
2. Develop → Simulator → [Your App]
3. Inspect WebView

## TestFlight Deployment

### Setup App Store Connect API

#### Option A: API Key File (Recommended)

1. Go to App Store Connect → Users and Access → Keys
2. Generate new key with "App Manager" role
3. Download the `.p8` file
4. Note the Key ID and Issuer ID

Set environment variables:
```bash
export APPSTORE_API_KEY_PATH="/path/to/AuthKey_XXXXXXXX.p8"
export APPSTORE_KEY_ID="your-key-id"
export APPSTORE_ISSUER_ID="your-issuer-id"
```

#### Option B: Private Key as Environment Variable

```bash
export APPSTORE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
...your key content...
-----END PRIVATE KEY-----"
export APPSTORE_KEY_ID="your-key-id"
export APPSTORE_ISSUER_ID="your-issuer-id"
```

### Build and Upload

```bash
# Build IPA and upload to TestFlight
./scripts/ios/build-local.sh testflight
```

The script will:
1. Build frontend
2. Create Xcode archive
3. Export IPA
4. Upload to App Store Connect
5. Submit for TestFlight review

### Manual Upload (Alternative)

If automatic upload fails:

1. Build IPA:
   ```bash
   ./scripts/ios/build-local.sh device
   ```

2. Upload using Transporter app:
   - Open Transporter (install from App Store)
   - Drag the IPA file
   - Click "Deliver"

## Project Structure

```
src-tauri/gen/apple/
├── circuit-assistant-mobile-companion.xcodeproj/  # Xcode project
├── circuit-assistant-mobile-companion_iOS/        # iOS app config
│   ├── Info.plist
│   └── *.entitlements
├── Assets.xcassets/                               # App icons
├── Sources/                                       # iOS entry point
└── assets/                                        # Web assets
```

## Common Commands

### Build Commands

```bash
# Development with hot reload
npm run tauri:ios:dev

# Build for simulator
./scripts/ios/build-local.sh simulator

# Build IPA for device
./scripts/ios/build-local.sh device

# Build and upload to TestFlight
./scripts/ios/build-local.sh testflight
```

### Xcode Commands

```bash
# Open project
open src-tauri/gen/apple/circuit-assistant-mobile-companion.xcodeproj

# Build from command line
xcodebuild -project src-tauri/gen/apple/circuit-assistant-mobile-companion.xcodeproj \
           -scheme circuit-assistant-mobile-companion_iOS \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Archive for release
xcodebuild archive -project src-tauri/gen/apple/circuit-assistant-mobile-companion.xcodeproj \
                   -scheme circuit-assistant-mobile-companion_iOS \
                   -archivePath build/ios.xcarchive
```

### Simulator Commands

```bash
# List available simulators
xcrun simctl list devices available

# Boot a simulator
xcrun simctl boot "iPhone 15 Pro"

# Install app on simulator
xcrun simctl install booted path/to/app.app

# Uninstall app from simulator
xcrun simctl uninstall booted org.circuitassistant.camc
```

## Troubleshooting

See [iOS Troubleshooting Guide](./ios-troubleshooting.md) for common issues and solutions.

## Next Steps

- Read the [iOS Troubleshooting Guide](./ios-troubleshooting.md)
- Learn about [app architecture](../architecture/design-overview.md)
- Explore [features documentation](../features/)


