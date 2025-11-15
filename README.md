# Circuit Assistant Mobile Companion (CAMC)

> Cross-platform application for Circuit Overseers to manage schedules, congregation reports, and circuit history.

[![Tauri](https://img.shields.io/badge/Tauri-2.0-24C8D8?logo=tauri)](https://v2.tauri.app/)
[![Vue 3](https://img.shields.io/badge/Vue-3-42B883?logo=vue.js)](https://vuejs.org/)
[![Rust](https://img.shields.io/badge/Rust-1.70+-CE422B?logo=rust)](https://www.rust-lang.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0+-3178C6?logo=typescript)](https://www.typescriptlang.org/)

## ✨ Features

- 📅 **Calendar** - Manage circuit visits, events, and appointments
- 📤 **File Export** - Export to ICS, vCard, and JSON formats
- 📱 **Cross-Platform** - iOS, macOS, Android, Windows support
- 🔒 **Offline-First** - Local SQLite database, no internet required
- 🔄 **Sync Ready** - CRDT-based peer-to-peer sync (coming soon)

## 🚀 Quick Start

### Prerequisites

- **Node.js** 18+ and npm
- **Rust** toolchain ([Install](https://rustup.rs/))
- **Xcode** (for iOS/macOS builds)
- **Android Studio** or Android SDK (for Android builds)

### Installation

```bash
# Clone repository
git clone <repository-url>
cd camc

# Install dependencies
npm install

# Run desktop app
npm run tauri:dev
```

## 📚 Documentation

- **[Getting Started](docs/getting-started/index.md)** - Complete setup guide
- **[Architecture](docs/architecture/design-overview.md)** - System design and tech stack
- **[Android Setup](docs/mobile/android-setup.md)** - Build for Android
- **[iOS Setup](docs/mobile/ios-setup.md)** - Build for iOS
- **[Features](docs/features/)** - Feature documentation
  - [Calendar](docs/features/calendar.md)
  - [File Export](docs/features/file-export.md)

## 🛠️ Development

### Desktop

```bash
# Development with hot reload
npm run tauri:dev

# Build for production
npm run tauri:build
```

### Android

```bash
# Setup environment
source setup-android-env.sh

# Start emulator
npm run android:emulator:start

# Run app
npm run tauri:android:dev
```

See [Android Setup Guide](docs/mobile/android-setup.md) for detailed instructions.

### iOS

```bash
# Run on simulator
npm run tauri:ios:dev

# Build IPA for TestFlight
npm run ios:build testflight
```

See [iOS Setup Guide](docs/mobile/ios-setup.md) for detailed instructions.

## 📦 Available Scripts

### Development
- `npm run dev` - Frontend dev server (Vite)
- `npm run tauri:dev` - Desktop app with hot reload
- `npm run tauri:android:dev` - Android with hot reload
- `npm run tauri:ios:dev` - iOS with hot reload

### Building
- `npm run build` - Build frontend
- `npm run tauri:build` - Build desktop app
- `npm run tauri:android:build` - Build Android APK
- `npm run ios:build` - Build iOS IPA

### Android Utilities
- `npm run android:setup` - Setup Android environment
- `npm run android:emulator:list` - List emulators
- `npm run android:emulator:start` - Start emulator
- `npm run android:debug` - Debug tools
- `npm run android:rebuild` - Clean rebuild

### iOS Utilities
- `npm run ios:fix` - Fix Xcode project issues

### Development Utilities
- `npm run kill-dev` - Kill hanging dev servers
- `npm run type-check` - TypeScript type checking

## 🏗️ Project Structure

```
camc/
├── docs/                    # Documentation
│   ├── getting-started/
│   ├── mobile/              # Android & iOS guides
│   ├── features/            # Feature docs
│   └── architecture/        # System design
│
├── scripts/                 # Build and utility scripts
│   ├── android/             # Android-specific
│   ├── ios/                 # iOS-specific
│   └── dev/                 # Development utilities
│
├── src/                     # Frontend (Vue 3 + Quasar)
│   ├── components/
│   ├── pages/
│   ├── router/
│   ├── composables/
│   └── utils/
│
├── src-tauri/               # Backend (Rust + Tauri)
│   ├── src/
│   │   ├── main.rs          # Desktop entry point
│   │   ├── lib.rs           # Mobile entry point
│   │   ├── commands.rs      # Tauri commands
│   │   ├── exports.rs       # File export logic
│   │   └── db.rs            # Database operations
│   ├── Cargo.toml
│   └── tauri.conf.json
│
├── .github/workflows/       # CI/CD
├── fastlane/                # iOS deployment
└── package.json
```

## 🔧 Technology Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Vue 3, Quasar, TypeScript |
| **Backend** | Rust, Tauri 2 |
| **Database** | SQLite |
| **Sync** | CRDT (Automerge/Yjs, planned) |
| **Mobile** | iOS (Xcode), Android (Gradle) |
| **CI/CD** | GitHub Actions, Fastlane |

## 🐛 Troubleshooting

### Common Issues

**Port already in use:**
```bash
npm run kill-dev
```

**Android build fails:**
```bash
npm run android:rebuild
```

**iOS build fails:**
```bash
npm run ios:fix
```

### Detailed Guides
- [Android Troubleshooting](docs/mobile/android-troubleshooting.md)
- [iOS Troubleshooting](docs/mobile/ios-troubleshooting.md)

## 🗺️ Roadmap

- [x] Desktop app (macOS, Windows)
- [x] Calendar with import
- [x] File export (ICS, vCard)
- [x] Android support
- [x] iOS support
- [ ] Database persistence for calendar
- [ ] CRDT peer-to-peer sync
- [ ] Congregation management
- [ ] Report generation
- [ ] Multi-language support

## 📄 License

[Your License]

## 🤝 Contributing

Contributions welcome! See [Getting Started](docs/getting-started/index.md) for development setup.

## 📧 Contact

[Your Contact Information]

---

**Built with ❤️ using Tauri, Vue, and Rust**
