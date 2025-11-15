# Getting Started with Circuit Assistant Mobile Companion

Welcome! This guide will help you set up and start developing CAMC.

## Prerequisites

- **macOS** (for iOS builds) or **Windows/Linux** (for Android/desktop)
- **Node.js** 18+ and npm
- **Rust** toolchain (install from [rustup.rs](https://rustup.rs/))
- **Xcode** (for iOS/macOS, macOS only)
- **Android Studio** or Android SDK (for Android)

## Quick Setup

### 1. Clone and Install

```bash
# Clone repository
git clone <repository-url>
cd camc

# Install dependencies
npm install

# Install Rust targets (optional, for mobile)
rustup target add aarch64-apple-ios          # iOS device
rustup target add aarch64-apple-ios-sim      # iOS simulator
rustup target add aarch64-linux-android      # Android
```

### 2. Run Desktop App

```bash
# Development mode (hot reload)
npm run tauri:dev

# Build for production
npm run tauri:build
```

### 3. Mobile Development

**Android:**
```bash
# Setup environment
source setup-android-env.sh

# Start emulator
npm run android:emulator:start

# Run app
npm run tauri:android:dev
```

See [Android Setup Guide](../mobile/android-setup.md) for details.

**iOS:**
```bash
# Run on simulator
npm run tauri:ios:dev

# Or open in Xcode
open src-tauri/gen/apple/circuit-assistant-mobile-companion.xcodeproj
```

See [iOS Setup Guide](../mobile/ios-setup.md) for details.

## Project Structure

```
camc/
├── docs/              # Documentation (you are here!)
├── scripts/           # Build and utility scripts
├── src/               # Frontend (Vue 3 + Quasar)
├── src-tauri/         # Backend (Rust + Tauri)
├── .github/           # CI/CD workflows
└── fastlane/          # iOS deployment automation
```

## Key Commands

### Development

```bash
npm run dev                    # Frontend only (Vite dev server)
npm run tauri:dev              # Desktop app with hot reload
npm run tauri:android:dev      # Android with hot reload
npm run tauri:ios:dev          # iOS with hot reload
```

### Building

```bash
npm run build                  # Build frontend
npm run tauri:build            # Build desktop app
npm run tauri:android:build    # Build Android APK
./scripts/ios/build-local.sh   # Build iOS IPA
```

### Utilities

```bash
npm run kill-dev               # Kill hanging dev servers
npm run android:emulator:list  # List Android emulators
npm run android:debug          # Android debugging tools
```

## Development Workflow

### Making Changes

1. **Frontend changes** - Edit files in `src/`
   - Auto-reloads in dev mode
   - Vue components, TypeScript, styles

2. **Backend changes** - Edit files in `src-tauri/src/`
   - Requires rebuild (auto-triggers in dev mode)
   - Rust commands, database, file operations

3. **Test on platforms:**
   - Desktop: `npm run tauri:dev`
   - Android: `npm run tauri:android:dev`
   - iOS: `npm run tauri:ios:dev`

### Adding Features

1. Create frontend component in `src/components/` or `src/pages/`
2. Add Rust command in `src-tauri/src/commands.rs` or `src-tauri/src/exports.rs`
3. Register command in `main.rs` and `lib.rs`:
   ```rust
   .invoke_handler(tauri::generate_handler![
       your_new_command,
       // ... other commands
   ])
   ```
4. Call from frontend:
   ```typescript
   import { invoke } from '@tauri-apps/api/core'
   const result = await invoke('your_new_command', { args })
   ```

## Common Issues

### Port Already in Use

```bash
npm run kill-dev
```

### Android Build Fails

```bash
npm run android:rebuild
```

See [Android Troubleshooting](../mobile/android-troubleshooting.md)

### iOS Build Fails

```bash
./scripts/ios/fix-xcode-project.sh
```

See [iOS Troubleshooting](../mobile/ios-troubleshooting.md)

### Clean Everything

```bash
# Clean frontend
rm -rf dist node_modules
npm install
npm run build

# Clean Rust
rm -rf src-tauri/target
cargo clean --manifest-path src-tauri/Cargo.toml

# Clean mobile projects
rm -rf src-tauri/gen/android/build
rm -rf src-tauri/gen/android/.gradle
rm -rf src-tauri/target/aarch64-*
```

## Documentation

- **[Architecture](../architecture/design-overview.md)** - System design and technology stack
- **[Android Setup](../mobile/android-setup.md)** - Detailed Android guide
- **[iOS Setup](../mobile/ios-setup.md)** - Detailed iOS guide
- **[Features](../features/)** - Feature documentation
  - [Calendar](../features/calendar.md)
  - [File Export](../features/file-export.md)

## Getting Help

- **Check documentation** in `docs/`
- **Read error messages** carefully
- **Check logs:**
  - Android: `npm run android:logcat`
  - iOS: Xcode console
  - Desktop: Terminal output
- **Review troubleshooting guides:**
  - [Android](../mobile/android-troubleshooting.md)
  - [iOS](../mobile/ios-troubleshooting.md)

## Next Steps

1. ✅ Run desktop app: `npm run tauri:dev`
2. ✅ Explore the UI (Calendar, Prototypes, Settings)
3. ✅ Read [Architecture documentation](../architecture/design-overview.md)
4. ✅ Set up mobile development:
   - [Android](../mobile/android-setup.md)
   - [iOS](../mobile/ios-setup.md)
5. ✅ Start building features!

Welcome to the team! 🚀


