# iOS Troubleshooting Guide

Common iOS build and deployment issues and their solutions.

## Quick Fixes

### Xcode Build Script Error

**Error:** `Command PhaseScriptExecution failed with a nonzero exit code`

**Cause:** Malformed arguments in Xcode build phase script

**Fix:**
```bash
./scripts/ios/fix-xcode-project.sh
```

This fixes common Xcode project issues after `tauri ios init` regenerates the project.

**Note:** Run this script whenever you regenerate the iOS project.

### Code Signing Errors

**Error:** `No signing certificate "iOS Distribution" found`

**Fix:**

1. **Check certificates:**
   ```bash
   security find-identity -v -p codesigning
   ```

2. **Install certificate if missing:**
   ```bash
   # Import from .p12 file
   security import certificate.p12 -k ~/Library/Keychains/login.keychain
   ```

3. **Set development team:**
   ```bash
   export DEVELOPMENT_TEAM="YOUR_TEAM_ID"
   ```

### Provisioning Profile Issues

**Error:** `No provisioning profile matches`

**Fix:**

1. **Check installed profiles:**
   ```bash
   ls ~/Library/MobileDevice/Provisioning\ Profiles/
   ```

2. **Install profile:**
   - Double-click the `.mobileprovision` file
   - Or copy to `~/Library/MobileDevice/Provisioning Profiles/`

3. **Set profile UUID:**
   ```bash
   export PROVISIONING_PROFILE_UUID="your-uuid"
   ```

### Build Fails on Simulator

**Error:** Build fails when targeting simulator

**Possible causes:**

1. **Rust target not installed:**
   ```bash
   rustup target add aarch64-apple-ios-sim
   rustup target add x86_64-apple-ios  # For Intel Macs
   ```

2. **Clean build needed:**
   ```bash
   rm -rf src-tauri/target/aarch64-apple-ios-sim
   npm run tauri:ios:dev
   ```

3. **Xcode issues:**
   ```bash
   # Clean derived data
   rm -rf ~/Library/Developer/Xcode/DerivedData
   
   # Clean Xcode project
   xcodebuild clean -project src-tauri/gen/apple/circuit-assistant-mobile-companion.xcodeproj
   ```

## Common Build Issues

### Issue: "tauri ios xcode-script" Fails

**Symptoms:** Build fails in "Build Rust Code" phase

**Debug:**
```bash
# Check what the script is trying to do
cd src-tauri/gen/apple
npm run -- tauri ios xcode-script -v --help
```

**Fixes:**

1. **Run fix script:**
   ```bash
   ./scripts/ios/fix-xcode-project.sh
   ```

2. **Manually check script:**
   Open `src-tauri/gen/apple/circuit-assistant-mobile-companion.xcodeproj/project.pbxproj`
   
   Look for `shellScript` in "Build Rust Code" phase - should not have stray arguments

3. **Regenerate and fix:**
   ```bash
   npm run tauri ios init --force
   ./scripts/ios/fix-xcode-project.sh
   ```

### Issue: Frontend Assets Not Found

**Symptoms:** App builds but shows blank screen

**Fixes:**

1. **Build frontend:**
   ```bash
   npm run build
   ls -la dist/  # Verify files exist
   ```

2. **Check tauri.conf.json:**
   ```json
   {
     "build": {
       "frontendDist": "../dist"
     }
   }
   ```

3. **Rebuild iOS:**
   ```bash
   npm run tauri:ios:dev
   ```

### Issue: Rust Compilation Errors

**Error:** `error: could not compile ...`

**Fixes:**

1. **Clean Rust cache:**
   ```bash
   rm -rf src-tauri/target
   cargo clean --manifest-path src-tauri/Cargo.toml
   ```

2. **Update dependencies:**
   ```bash
   cd src-tauri
   cargo update
   cd ..
   ```

3. **Check Rust version:**
   ```bash
   rustc --version
   rustup update
   ```

### Issue: App Crashes on Launch (Device)

**Debug steps:**

1. **Connect device and check logs:**
   ```bash
   # Get device UDID
   xcrun xctrace list devices
   
   # View logs
   idevicesyslog | grep circuit
   ```

2. **Check crash reports:**
   - Xcode → Window → Devices and Simulators
   - Select your device
   - View Device Logs

3. **Enable Rust backtraces:**
   In `src-tauri/src/lib.rs`:
   ```rust
   std::env::set_var("RUST_BACKTRACE", "1");
   ```

### Issue: TestFlight Upload Fails

**Error:** Authentication or network errors

**Fixes:**

1. **Verify API credentials:**
   ```bash
   echo $APPSTORE_KEY_ID
   echo $APPSTORE_ISSUER_ID
   ls -la $APPSTORE_API_KEY_PATH
   ```

2. **Check API key permissions:**
   - Go to App Store Connect → Users and Access → Keys
   - Ensure key has "App Manager" or "Admin" role

3. **Manual upload:**
   ```bash
   # Build IPA
   ./scripts/ios/build-local.sh device
   
   # Upload with Transporter app
   # (Download from Mac App Store)
   ```

4. **Use altool (legacy):**
   ```bash
   xcrun altool --upload-app \
                --type ios \
                --file "build/ios-export/Circuit Assistant Mobile Companion.ipa" \
                --apiKey "$APPSTORE_KEY_ID" \
                --apiIssuer "$APPSTORE_ISSUER_ID"
   ```

## Advanced Debugging

### Inspect Generated Xcode Project

```bash
# Open project.pbxproj in editor
code src-tauri/gen/apple/circuit-assistant-mobile-companion.xcodeproj/project.pbxproj

# Look for build phases, specifically "Build Rust Code"
# Check shellScript for malformed commands
```

### Debug Build Phase Scripts

Add debugging to Xcode scripts:

1. Open Xcode project
2. Select target → Build Phases
3. Find "Build Rust Code" phase
4. Add at top of script:
   ```bash
   set -x  # Enable verbose output
   echo "Configuration: $CONFIGURATION"
   echo "Platform: $PLATFORM_DISPLAY_NAME"
   echo "Arch: $ARCHS"
   ```

### Verify Build Products

```bash
# After successful build
ls -la src-tauri/target/aarch64-apple-ios-sim/debug/libcircuit_assistant_mobile_companion.a

# Check app bundle
ls -la src-tauri/gen/apple/build/Build/Products/Debug-iphonesimulator/*.app
```

### Test Archive Validity

```bash
# After archive creation
ls -la build/ios.xcarchive

# Verify app in archive
ls -la build/ios.xcarchive/Products/Applications/*.app

# Check for dSYMs
ls -la build/ios.xcarchive/dSYMs/
```

## File-Related Issues

### Document Directory Not Working

**Error:** Can't read/write files on iOS

**Cause:** Using wrong path APIs

**Solution:** Code already uses correct APIs:
```rust
// ✅ Correct (current implementation)
app.path().document_dir()    // For user documents
app.path().app_data_dir()    // For app data

// ❌ Wrong (old code)
dirs::document_dir()          // Doesn't work on iOS
```

### Files Not Showing in Files App

**Issue:** Created files don't appear in iOS Files app

**Solutions:**

1. **Enable file sharing:** In `Info.plist`:
   ```xml
   <key>UIFileSharingEnabled</key>
   <true/>
   <key>LSSupportsOpeningDocumentsInPlace</key>
   <true/>
   ```

2. **Use correct directory:**
   ```rust
   // Files visible in Files app
   app.path().document_dir()
   
   // Files hidden from user
   app.path().app_data_dir()
   ```

3. **Create placeholder file:**
   Already implemented - creates `CircuitAssistant-README.txt` on first launch

## Environment Issues

### NDK/Android Variables Conflict

**Problem:** Android environment variables interfere with iOS builds

**Solution:** Don't source Android environment when building iOS:
```bash
# ❌ Don't do this before iOS build
source setup-android-env.sh

# ✅ Just build iOS directly
npm run tauri:ios:dev
```

### Xcode Command Line Tools

**Error:** `xcrun: error: unable to find utility`

**Fix:**
```bash
# Install or reset command line tools
xcode-select --install

# Or select Xcode path
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Verify
xcode-select -p
```

## Diagnostic Checklist

Before reporting issues:

- [ ] **Xcode installed:** `xcodebuild -version`
- [ ] **Rust targets installed:** `rustup target list | grep ios`
- [ ] **Frontend built:** `ls -la dist/index.html`
- [ ] **Fix script run:** `./scripts/ios/fix-xcode-project.sh`
- [ ] **Clean build attempted:** `rm -rf src-tauri/target/aarch64-apple-ios*`
- [ ] **Development team set:** `echo $DEVELOPMENT_TEAM`
- [ ] **Xcode project opens:** `open src-tauri/gen/apple/*.xcodeproj`

## Getting Help

When reporting iOS issues, include:

1. **Xcode version:**
   ```bash
   xcodebuild -version
   ```

2. **Build error output:**
   ```bash
   npm run tauri:ios:dev 2>&1 | tee ios-build.log
   ```

3. **Environment info:**
   ```bash
   echo "macOS: $(sw_vers -productVersion)"
   echo "Xcode: $(xcodebuild -version | head -1)"
   echo "Rust: $(rustc --version)"
   echo "Node: $(node --version)"
   echo "Targets: $(rustup target list | grep apple-ios)"
   ```

4. **Project state:**
   ```bash
   ls -la src-tauri/gen/apple/
   ```

## Related Documentation

- [iOS Setup Guide](./ios-setup.md)
- [Tauri iOS Documentation](https://v2.tauri.app/develop/ios/)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)


