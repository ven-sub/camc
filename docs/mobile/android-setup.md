# Android Setup Guide

Complete guide for setting up Android development and building locally.

## Prerequisites

- macOS with Android Studio installed (recommended) or Android SDK
- Node.js and npm
- Rust toolchain

## Quick Start

```bash
# 1. Setup Android environment
npm run android:setup

# 2. Start an emulator (existing or new)
npm run android:emulator:list    # See available emulators
npm run android:emulator:start   # Start default emulator

# 3. Build and run
npm run tauri:android:dev
```

## Detailed Setup

### 1. Android SDK Installation

You can use either:
- **Android Studio** (recommended) - includes SDK and NDK
- **Command line tools only** (minimal setup)

#### Option A: Using Android Studio (Recommended)

1. Download and install [Android Studio](https://developer.android.com/studio)
2. Open Android Studio → Settings → Appearance & Behavior → System Settings → Android SDK
3. Install:
   - Android SDK Platform (API 34 or higher)
   - Android SDK Build-Tools
   - NDK (Side by side) version 29.0.13846066
   - Android SDK Command-line Tools

#### Option B: Command Line Tools Only

```bash
# Run the setup script
./scripts/android/setup.sh

# This will:
# - Download Android command-line tools
# - Accept SDK licenses
# - Install required SDK components
# - Install NDK
```

### 2. Environment Variables

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export NDK_HOME="$ANDROID_HOME/ndk/29.0.13846066"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"
```

Then reload: `source ~/.zshrc`

Or use the setup script for current session:

```bash
source setup-android-env.sh
```

### 3. Initialize Tauri Android Project

```bash
# First time only
npm run android:init
```

This generates the Android project in `src-tauri/gen/android/`.

### 4. Emulator Setup

#### Using Existing Android Studio Emulators

The best approach is to use emulators you've already created in Android Studio:

```bash
# List all available emulators (Android Studio + CLI)
npm run android:emulator:list

# Start an existing emulator by name
./scripts/android/emulator.sh start "Medium_Phone_API_36.0"
```

#### Creating a New Emulator

```bash
# Create default emulator (if you don't have one)
npm run android:emulator:create

# Or specify a name
./scripts/android/emulator.sh create "MyCustomEmulator"
```

### 5. Building and Running

#### Development Build (Hot Reload)

```bash
# Make sure emulator is running first
npm run android:emulator:status

# Build and deploy with hot reload
npm run tauri:android:dev
```

#### Release Build

```bash
# Build APK for release
npm run tauri:android:build:release

# Output: src-tauri/gen/android/app/build/outputs/apk/release/
```

## Package.json Scripts

| Script | Description |
|--------|-------------|
| `android:init` | Initialize Tauri Android project |
| `android:emulator:list` | List all emulators |
| `android:emulator:create` | Create a new emulator |
| `android:emulator:start` | Start emulator |
| `android:emulator:stop` | Stop emulator |
| `android:emulator:status` | Check emulator status |
| `android:devices` | List connected devices |
| `android:logcat` | View app logs |
| `android:debug` | Debug tools menu |
| `android:rebuild` | Clean rebuild |
| `tauri:android:dev` | Build and run in dev mode |
| `tauri:android:build` | Build APK (debug) |
| `tauri:android:build:release` | Build APK (release) |

## Common Commands

### Check Environment

```bash
# Verify ANDROID_HOME
echo $ANDROID_HOME

# Verify NDK_HOME
echo $NDK_HOME

# Check connected devices
adb devices

# Check emulator status
./scripts/android/emulator.sh status
```

### Emulator Management

```bash
# List available emulators
emulator -list-avds

# Start specific emulator
./scripts/android/emulator.sh start "Pixel_5_API_34"

# Stop emulator
./scripts/android/emulator.sh stop

# Restart emulator
./scripts/android/emulator.sh restart
```

### Building

```bash
# Clean rebuild
npm run android:rebuild

# Build only (no deployment)
npm run tauri:android:build

# Build and install
npm run tauri:android:dev
```

## Troubleshooting

See [Android Troubleshooting Guide](./android-troubleshooting.md) for common issues and solutions.

## Next Steps

- Read the [Android Troubleshooting Guide](./android-troubleshooting.md)
- Learn about [debugging Android apps](./android-troubleshooting.md#debugging)
- Check out [features documentation](../features/)


