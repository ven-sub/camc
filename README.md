# CAMC App

A cross-platform Tauri 2 + Vue 3 + TypeScript application with support for desktop and mobile platforms.

## Features

- **Cross-platform**: Supports macOS, Windows, Linux, iOS, and Android
- **Modern Stack**: Tauri 2 + Vue 3 + TypeScript + Vite
- **Local-first**: No server dependency required
- **Type-safe**: Full TypeScript support for both frontend and backend
- **Fast**: Rust backend with Vue 3 frontend

## Project Structure

```
camc/
├── src/                    # Vue 3 frontend
│   ├── App.vue            # Main Vue component
│   ├── main.ts            # Vue app entry point
│   ├── style.css          # Global styles
│   └── vite-env.d.ts      # TypeScript declarations
├── src-tauri/             # Rust backend
│   ├── src/
│   │   └── main.rs        # Rust main file
│   ├── Cargo.toml         # Rust dependencies
│   ├── tauri.conf.json    # Tauri configuration
│   └── icons/             # App icons
├── package.json           # Node.js dependencies and scripts
├── vite.config.ts         # Vite configuration
├── tsconfig.json          # TypeScript configuration
└── README.md              # This file
```

## Prerequisites

### Desktop Development
- **Node.js** (v18 or later)
- **Rust** (latest stable)
- **Platform-specific tools**:
  - **Windows**: Microsoft Visual Studio C++ Build Tools
  - **macOS**: Xcode Command Line Tools
  - **Linux**: `libwebkit2gtk-4.0-dev`, `build-essential`, `curl`, `wget`, `libssl-dev`, `libgtk-3-dev`, `libayatana-appindicator3-dev`, `librsvg2-dev`

### Mobile Development

#### Android
- **Android Studio** with Android SDK
- **Java Development Kit (JDK)** 11 or later
- **Android SDK** API level 30 or later
- **Gradle** (usually comes with Android Studio)

#### iOS (macOS only)
- **Xcode** (latest version)
- **iOS SDK** (latest version)
- **CocoaPods** (`sudo gem install cocoapods`)

## Installation

1. **Clone and navigate to the project**:
   ```bash
   cd camc
   ```

2. **Install Node.js dependencies**:
   ```bash
   npm install
   ```

3. **Install Tauri CLI globally** (if not already installed):
   ```bash
   npm install -g @tauri-apps/cli@next
   ```

## Development

### Desktop Development

1. **Start the development server**:
   ```bash
   npm run tauri:dev
   ```
   This will:
   - Start the Vite dev server on `http://localhost:1420`
   - Compile and run the Tauri application
   - Enable hot reload for both frontend and backend changes

2. **Frontend-only development** (for web development):
   ```bash
   npm run dev
   ```

### Mobile Development

#### Android Development

1. **Setup Android development environment**:
   - Install Android Studio
   - Set up Android SDK
   - Create an Android Virtual Device (AVD) or connect a physical device

2. **Initialize Android project**:
   ```bash
   npm run tauri:android
   ```

3. **Run on Android**:
   ```bash
   npm run tauri:android:dev
   ```

4. **Build for Android**:
   ```bash
   npm run tauri:android:build
   ```

#### iOS Development (macOS only)

1. **Setup iOS development environment**:
   - Install Xcode from the App Store
   - Install iOS Simulator
   - Install CocoaPods: `sudo gem install cocoapods`

2. **Initialize iOS project**:
   ```bash
   npm run tauri:ios
   ```

3. **Run on iOS**:
   ```bash
   npm run tauri:ios:dev
   ```

4. **Build for iOS**:
   ```bash
   npm run tauri:ios:build
   ```

## Building

### Desktop Builds

1. **Build for current platform**:
   ```bash
   npm run tauri:build
   ```

2. **Build for specific platforms**:
   ```bash
   # Windows (from any platform)
   npm run tauri:build -- --target x86_64-pc-windows-msvc
   
   # macOS (from macOS)
   npm run tauri:build -- --target x86_64-apple-darwin
   npm run tauri:build -- --target aarch64-apple-darwin
   
   # Linux (from Linux)
   npm run tauri:build -- --target x86_64-unknown-linux-gnu
   ```

### Mobile Builds

1. **Android APK**:
   ```bash
   npm run tauri:android:build
   ```

2. **iOS App**:
   ```bash
   npm run tauri:ios:build
   ```

## Available Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start Vite dev server (web only) |
| `npm run build` | Build Vue frontend for production |
| `npm run preview` | Preview production build |
| `npm run tauri:dev` | Start Tauri development (desktop) |
| `npm run tauri:build` | Build Tauri app for desktop |
| `npm run tauri:android` | Initialize Android project |
| `npm run tauri:ios` | Initialize iOS project |
| `npm run tauri:android:dev` | Run on Android device/emulator |
| `npm run tauri:ios:dev` | Run on iOS device/simulator |
| `npm run tauri:android:build` | Build Android APK |
| `npm run tauri:ios:build` | Build iOS app |

## Configuration

### Tauri Configuration

The main Tauri configuration is in `src-tauri/tauri.conf.json`. Key settings:

- **Bundle identifier**: `com.camc.app`
- **App name**: `CAMC App`
- **Window settings**: 800x600 default, resizable
- **Security**: Custom CSP disabled for development

### Vite Configuration

The Vite configuration in `vite.config.ts` is optimized for Tauri:

- **Port**: 1420 (Tauri default)
- **Strict port**: Prevents port conflicts
- **Watch exclusions**: Ignores `src-tauri` directory

## Development Tips

1. **Hot Reload**: Both frontend and backend support hot reload during development
2. **TypeScript**: Full type safety across the entire stack
3. **Rust Commands**: Add new Tauri commands in `src-tauri/src/main.rs`
4. **Vue Components**: Create reusable components in `src/components/`
5. **Styling**: Use CSS, SCSS, or CSS-in-JS as preferred

## Troubleshooting

### Common Issues

1. **Rust not found**: Install Rust from [rustup.rs](https://rustup.rs/)
2. **Node modules issues**: Delete `node_modules` and run `npm install`
3. **Tauri CLI not found**: Install globally with `npm install -g @tauri-apps/cli@next`
4. **Android build fails**: Ensure Android SDK is properly configured
5. **iOS build fails**: Ensure Xcode and iOS SDK are installed

### Platform-Specific Issues

#### Windows
- Install Microsoft Visual Studio C++ Build Tools
- Ensure Windows SDK is installed

#### macOS
- Install Xcode Command Line Tools: `xcode-select --install`
- For iOS development, ensure Xcode is up to date

#### Linux
- Install required system dependencies:
  ```bash
  sudo apt update
  sudo apt install libwebkit2gtk-4.0-dev build-essential curl wget libssl-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev
  ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple platforms
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the [Tauri documentation](https://tauri.app/)
- Check the [Vue 3 documentation](https://v3.vuejs.org/)
- Open an issue in this repository
