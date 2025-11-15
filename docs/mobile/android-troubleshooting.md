# Android Troubleshooting & Debugging Guide

Complete guide for debugging Android app issues and common problems.

## Quick Fixes

### App Crashes on Launch

**Symptoms:** App opens then immediately closes

**Most Common Cause:** Frontend assets not bundled properly

**Quick Fix:**
```bash
npm run android:rebuild
```

This script will:
1. Build frontend (`npm run build`)
2. Clean Android builds
3. Uninstall old app
4. Deploy fresh build

### Can't Find Android SDK/NDK

**Symptoms:** Build fails with "NDK_HOME not found" or similar

**Fix:**
```bash
# Set environment for current session
source setup-android-env.sh

# Or add to ~/.zshrc permanently
echo 'export ANDROID_HOME="$HOME/Library/Android/sdk"' >> ~/.zshrc
echo 'export NDK_HOME="$ANDROID_HOME/ndk/29.0.13846066"' >> ~/.zshrc
source ~/.zshrc
```

### Port Already in Use

**Symptoms:** `Port 1421 is already in use`

**Fix:**
```bash
npm run kill-dev
# Then restart
npm run tauri:android:dev
```

## Debugging Tools

### 1. Debug Script (`android-debug.sh`)

Main tool for Android debugging:

```bash
./scripts/android/debug.sh crash      # Get crash logs
./scripts/android/debug.sh watch      # Watch live logs (filtered)
./scripts/android/debug.sh watch-all  # Watch all logs
./scripts/android/debug.sh info       # Get app info
./scripts/android/debug.sh clear      # Clear logs
./scripts/android/debug.sh uninstall  # Uninstall app
```

### 2. Rebuild Script

Clean rebuild from scratch:

```bash
./scripts/android/rebuild.sh
```

### 3. Manual ADB Commands

```bash
# View logs in real-time
adb logcat

# Filter for app
adb logcat | grep circuit

# Clear logs
adb logcat -c

# Check connected devices
adb devices

# Uninstall app
adb uninstall org.circuitassistant.camc

# Force stop app
adb shell am force-stop org.circuitassistant.camc

# Launch app manually
adb shell am start -n org.circuitassistant.camc/.MainActivity

# Get app info
adb shell dumpsys package org.circuitassistant.camc
```

## Common Issues & Solutions

### 1. Invalid Resource ID Crash

**Error in logs:**
```
E/tassistant.camc: Invalid resource ID 0x00000000.
F/libc: Fatal signal 6 (SIGABRT)
```

**Cause:** Tauri can't find web assets (HTML, JS, CSS)

**Solutions:**

1. **Build frontend first:**
   ```bash
   npm run build
   ```

2. **Check tauri.conf.json:**
   ```json
   {
     "build": {
       "frontendDist": "../dist"
     }
   }
   ```

3. **Clean rebuild:**
   ```bash
   npm run android:rebuild
   ```

### 2. Rust Panic on AppHandle/PathError

**Error in logs:**
```
panicked at 'Failed to get app data dir'
panicked at 'called `Result::unwrap()` on an `Err` value'
```

**Cause:** Using `dirs` crate instead of Tauri's path APIs on Android

**Solution:** Already fixed in current code - uses `app.path().app_data_dir()` and `app.path().document_dir()`

### 3. NDK Not Found

**Error:**
```
failed to load Android environment: NDK_HOME doesn't point to an existing directory
```

**Solutions:**

1. **Check NDK installed:**
   ```bash
   ls $HOME/Library/Android/sdk/ndk/
   ```

2. **Install NDK:**
   ```bash
   ./scripts/android/setup.sh
   ```

3. **Set NDK_HOME:**
   ```bash
   export NDK_HOME="$HOME/Library/Android/sdk/ndk/29.0.13846066"
   ```

### 4. Emulator Not Starting

**Problem:** Emulator command hangs or fails

**Solutions:**

1. **Use Android Studio emulator:**
   ```bash
   ./scripts/android/emulator.sh list
   ./scripts/android/emulator.sh start "Your_Emulator_Name"
   ```

2. **Check emulator status:**
   ```bash
   ./scripts/android/emulator.sh status
   ```

3. **Restart emulator:**
   ```bash
   ./scripts/android/emulator.sh restart
   ```

### 5. Build Failures

**Problem:** Compilation errors during Android build

**Common causes and fixes:**

**Rust compilation error:**
```bash
# Clean Rust cache
rm -rf src-tauri/target/aarch64-linux-android

# Rebuild
npm run tauri:android:dev
```

**Gradle build error:**
```bash
# Clean Gradle cache
rm -rf src-tauri/gen/android/.gradle
rm -rf src-tauri/gen/android/app/build

# Rebuild
npm run tauri:android:dev
```

**Frontend build error:**
```bash
# Clean frontend
rm -rf dist node_modules
npm install
npm run build

# Then build Android
npm run tauri:android:dev
```

### 6. App Installed But Won't Launch

**Problem:** App installs successfully but doesn't open

**Debug steps:**

1. **Check logs during manual launch:**
   ```bash
   adb logcat -c
   adb shell am start -n org.circuitassistant.camc/.MainActivity
   adb logcat | grep -E "(circuit|ERROR|FATAL)"
   ```

2. **Check app permissions:**
   ```bash
   ./scripts/android/debug.sh info
   ```

3. **Reinstall clean:**
   ```bash
   adb uninstall org.circuitassistant.camc
   npm run tauri:android:dev
   ```

### 7. UI Issues / Blank Screen

**Problem:** App launches but shows blank/white screen

**Debug with Chrome DevTools:**

1. Open Chrome on your computer
2. Navigate to `chrome://inspect`
3. Find your app's WebView
4. Click "inspect"
5. Check Console for JavaScript errors

**Common causes:**
- Frontend build errors (check `dist/` folder)
- Asset loading issues
- JavaScript runtime errors

**Fix:**
```bash
# Rebuild frontend
npm run build

# Check dist folder has files
ls -la dist/

# Rebuild Android
npm run android:rebuild
```

## Advanced Debugging

### Enable Rust Backtraces

```bash
export RUST_BACKTRACE=1
npm run tauri:android:dev
```

### Inspect APK Contents

```bash
# Find APK
APK="src-tauri/gen/android/app/build/outputs/apk/debug/app-universal-debug.apk"

# List all files
unzip -l "$APK"

# Check for web assets
unzip -l "$APK" | grep -E "\.(html|js|css|woff)"

# Check for native libraries
unzip -l "$APK" | grep "\.so$"

# Extract and inspect
unzip -d /tmp/apk-contents "$APK"
ls -R /tmp/apk-contents/
```

### Debug in Android Studio

1. **Open project:**
   ```bash
   studio src-tauri/gen/android
   ```

2. **View logs:** Use Logcat panel (better than command line)

3. **Set breakpoints:** In MainActivity.kt or other Kotlin files

4. **Analyze APK:**
   - Build → Analyze APK
   - Select your APK
   - Inspect file sizes and contents

### Watch Logs Continuously

```bash
# All app logs
adb logcat | grep circuit

# Errors only
adb logcat *:E | grep circuit

# Specific tag
adb logcat -s "circuit_assistant"

# Save to file
adb logcat | grep circuit > debug.log
```

### Test on Physical Device

```bash
# Enable USB debugging on device (Settings → Developer Options)

# Connect via USB

# Verify connection
adb devices

# Build and deploy
npm run tauri:android:dev
```

## Diagnostic Checklist

Before reporting issues, verify:

- [ ] **Frontend built:** `ls -la dist/index.html`
- [ ] **Environment set:** `echo $ANDROID_HOME && echo $NDK_HOME`
- [ ] **Device connected:** `adb devices` shows device
- [ ] **App uninstalled:** `adb uninstall org.circuitassistant.camc`
- [ ] **Logs cleared:** `adb logcat -c`
- [ ] **Clean build attempted:** `npm run android:rebuild`
- [ ] **Logs captured:** `./scripts/android/debug.sh crash`

## Log Files

Debug tools save logs automatically:

```bash
# List recent crash logs
ls -lt android-crash-*.log

# List recent launch logs  
ls -lt app-launch-*.log

# View latest crash
cat $(ls -t android-crash-*.log | head -1)

# Search for errors
grep -i "error" *.log
grep -i "exception" *.log
grep -i "fatal" *.log
```

## Getting Help

When reporting issues, include:

1. **Error message:**
   ```bash
   ./scripts/android/debug.sh crash
   ```

2. **Environment info:**
   ```bash
   echo "OS: $(uname -s) $(uname -r)"
   echo "Android SDK: $ANDROID_HOME"
   echo "NDK: $NDK_HOME"
   echo "ADB: $(adb --version | head -1)"
   echo "Rust: $(rustc --version)"
   echo "Node: $(node --version)"
   echo "npm: $(npm --version)"
   ```

3. **Build output:** Full output from `npm run tauri:android:dev`

4. **APK info:**
   ```bash
   ls -lh src-tauri/gen/android/app/build/outputs/apk/debug/
   ```

## Related Documentation

- [Android Setup Guide](./android-setup.md)
- [Tauri Android Documentation](https://v2.tauri.app/develop/android/)
- [Android Developer Guide](https://developer.android.com/guide)


