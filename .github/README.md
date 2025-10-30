# GitHub Actions CI/CD

This directory contains GitHub Actions workflows for the CAMC (Circuit Assistant Mobile Companion) project.

## Workflows Overview

### 1. CI (`ci.yml`)
**Triggers:** Push to main/develop, Pull Requests
**Purpose:** Fast feedback for code quality
- Lints frontend and Rust code
- Type checks TypeScript
- Runs tests
- Builds frontend
- Validates Tauri configuration

### 2. Test (`test.yml`)
**Triggers:** Push to main/develop, Pull Requests
**Purpose:** Comprehensive testing across platforms
- Frontend tests
- Rust unit tests
- Cross-platform compatibility testing
- Build validation

### 3. Build Desktop (`build-desktop.yml`)
**Triggers:** Push to main, Tags, Manual
**Purpose:** Build desktop applications
- **macOS:** Intel (x86_64) and Apple Silicon (aarch64)
- **Windows:** x64 MSI/EXE
- Uploads build artifacts

### 4. Build iOS (`build-ios.yml`)
**Triggers:** Tags (v*), Manual
**Purpose:** Build iOS applications
- **iOS:** Device and Simulator builds
- Only runs on releases to save CI minutes
- Uploads build artifacts

### 5. Build Android (`build-android.yml`)
**Triggers:** Tags (v*), Manual
**Purpose:** Build Android applications
- **Android:** APK/AAB builds
- Only runs on releases to save CI minutes
- Uploads build artifacts

### 6. Release (`release.yml`)
**Triggers:** Tags (v*), Manual
**Purpose:** Create releases with desktop platform builds
- Builds desktop platforms (macOS, Windows, Linux)
- Creates GitHub release
- Uploads release assets
- Mobile builds run separately via their own workflows

## Platform Support

| Platform | Runner | Build Target | Output | Trigger |
|----------|--------|--------------|--------|---------|
| macOS Intel | macos-latest | x86_64-apple-darwin | .dmg | Push/PR/Release |
| macOS Apple Silicon | macos-latest | aarch64-apple-darwin | .dmg | Push/PR/Release |
| Windows | windows-latest | x86_64-pc-windows-msvc | .msi/.exe | Push/PR/Release |
| Linux | ubuntu-latest | x86_64-unknown-linux-gnu | .AppImage | Release only |
| iOS | macos-latest | aarch64-apple-ios | .ipa | Release only |
| Android | ubuntu-latest | aarch64-linux-android | .apk/.aab | Release only |

## Build Artifacts

All workflows upload build artifacts that can be downloaded from the Actions tab:
- `camc-macos-intel` - macOS Intel build
- `camc-macos-apple-silicon` - macOS Apple Silicon build
- `camc-windows` - Windows build
- `camc-ios-v*` - iOS build (release only)
- `camc-android-v*` - Android build (release only)

## GitHub Secrets

For production releases, you may need to configure these secrets:

### iOS Signing (Optional)
- `APPLE_CERTIFICATE` - Apple Developer certificate
- `APPLE_CERTIFICATE_PASSWORD` - Certificate password
- `APPLE_PROVISIONING_PROFILE` - Provisioning profile

### Android Signing (Optional)
- `ANDROID_KEYSTORE` - Android keystore file
- `ANDROID_KEYSTORE_PASSWORD` - Keystore password
- `ANDROID_KEY_ALIAS` - Key alias
- `ANDROID_KEY_PASSWORD` - Key password

## Usage

### Automatic Builds
- Push to `main` branch triggers desktop builds and CI
- Create a tag (e.g., `v1.0.0`) to trigger all builds including mobile
- Pull requests run CI and test workflows
- Mobile builds (iOS/Android) only run on releases to save CI minutes

### Manual Builds
- Go to Actions tab in GitHub
- Select the workflow you want to run
- Click "Run workflow"
- For releases, you can specify a version

### Local Development
```bash
# Install dependencies
npm ci

# Install Tauri CLI
npm install -g @tauri-apps/cli@next

# Run development server
npm run tauri:dev

# Build for current platform
npm run tauri:build
```

## Troubleshooting

### Common Issues

1. **Build failures on mobile platforms**
   - Ensure all dependencies are properly installed
   - Check that platform-specific tools are available

2. **iOS build issues**
   - Requires macOS runner (Xcode)
   - May need Apple Developer account for signed builds

3. **Android build issues**
   - Requires Android SDK setup
   - Check Java version compatibility

4. **Rust compilation errors**
   - Ensure all Rust targets are installed
   - Check Cargo.toml dependencies

### Monitoring Builds

- Check the Actions tab for build status
- Download artifacts from successful builds
- Review logs for detailed error information

## Future Enhancements

- [ ] Add automated testing with real devices
- [ ] Implement code coverage reporting
- [ ] Add security scanning
- [ ] Set up automated deployment to app stores
- [ ] Add performance benchmarking
