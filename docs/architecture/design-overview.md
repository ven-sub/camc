# Circuit Assistant Mobile Companion - Architecture

## Overview

Circuit Assistant Mobile Companion (CAMC) is a cross-platform application for Circuit Overseers to manage schedules, congregation reports, and circuit history. Built with Tauri 2, it runs on iOS, macOS, Android, and Windows with a unified data model.

## Core Principles

1. **Cross-platform** - Single codebase for all platforms
2. **Offline-first** - Works without internet using local SQLite database
3. **Peer-to-peer sync** - CRDTs enable multi-device consistency
4. **Privacy-first** - No centralized cloud storage

## Technology Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Vue 3 + Quasar + TypeScript |
| **Backend** | Rust + Tauri 2 |
| **Database** | SQLite (`camc.db`) |
| **Sync Engine** | CRDT (Automerge / Yjs / custom) |
| **Build** | GitHub Actions + Fastlane |
| **Packaging** | Xcode (iOS/macOS), Gradle (Android), MSIX (Windows) |

## Architecture Layers

### 1. Frontend (Vue 3 + Quasar)

**Purpose:** Cross-platform UI with responsive design

**Key Files:**
- `src/App.vue` - Main app shell
- `src/pages/` - Page components (Calendar, Prototypes, Settings)
- `src/components/` - Shared components (NavigationDrawer, ToolbarActions)
- `src/router/` - Vue Router configuration
- `src/composables/` - Reusable logic (useFileExport)

**Responsive Design:**
- **Desktop:** Left-hand navigation drawer
- **Mobile/Tablet:** Bottom navigation tabs
- **Auto-adjusts** based on screen size using Quasar breakpoints

### 2. Backend (Rust + Tauri)

**Purpose:** Native OS integration, file system access, database operations

**Key Files:**
- `src-tauri/src/main.rs` - Desktop entry point
- `src-tauri/src/lib.rs` - Mobile entry point (iOS/Android)
- `src-tauri/src/commands.rs` - Tauri commands (greet, get_platform, test_db)
- `src-tauri/src/exports.rs` - File export commands (ICS, vCard, JSON)
- `src-tauri/src/db.rs` - Database initialization

**Platform-Specific Paths:**
```rust
// Mobile (iOS/Android) - uses Documents directory
app.path().document_dir()

// Desktop - uses app data directory
app.path().app_data_dir()
```

### 3. Data Layer (SQLite)

**Database:** `camc.db`

**Current Tables:**
- `CalendarEvents` - Calendar events and appointments
- *(More tables planned: Congregations, Reports, etc.)*

**Location:**
- **macOS:** `~/Library/Application Support/org.circuitassistant.camc/`
- **iOS:** App's Documents directory (visible in Files app)
- **Android:** App's internal storage
- **Windows:** `%LOCALAPPDATA%\org.circuitassistant.camc\`

### 4. Sync Layer (CRDT) [Planned]

**Purpose:** Conflict-free replication across devices

**Use Cases:**
1. Multi-device usage (CO using desktop + mobile)
2. Shared data between COs (PSS/SCE instructors)
3. Circuit data transfer (replace manual export/import)

**Technology Options:**
- Automerge
- Yjs
- Custom lightweight implementation

**Sync Methods:**
- Local WiFi (peer-to-peer)
- Bluetooth
- Manual export/import (current fallback)

## Application Flow

### Startup Sequence

1. **Initialize Tauri app** (`main.rs` or `lib.rs`)
2. **Setup database** - `db::init_db(&app.handle())`
3. **Register plugins** - dialog, fs
4. **Register commands** - greet, export_ics, export_vcard, etc.
5. **Create placeholder** - Ensures Documents folder visible on iOS
6. **Load Vue app** - Frontend takes over

### Command Flow

```
Frontend (Vue)
    ↓
  invoke("command_name", args)
    ↓
Tauri Bridge
    ↓
Rust Backend (src-tauri/src/*.rs)
    ↓
OS APIs / File System / Database
    ↓
Return Result<T, String>
    ↓
Frontend handles success/error
```

## Key Features

### 1. Calendar Management

**Files:**
- `src/pages/CalendarPage.vue`
- `src/utils/events.ts`

**Features:**
- Month view using QCalendar
- Import events from JSON
- Color-coded event badges
- Event details dialog

**Data Flow:**
1. User imports JSON file
2. Frontend parses events
3. Events stored in component state
4. Calendar renders with badges
5. *(Future: Persist to SQLite)*

### 2. File Export (Prototypes)

**Files:**
- `src/pages/PrototypesPage.vue`
- `src-tauri/src/exports.rs`
- `src/composables/useFileExport.ts`

**Supported Formats:**
- **ICS (iCalendar)** - Calendar events
- **vCard** - Contact information
- **JSON** - Custom data structures

**Export Flow:**
1. User clicks export button
2. Frontend calls Rust command
3. Rust generates file content
4. Rust writes to platform-specific directory
5. Returns file path
6. Frontend shows success notification

### 3. Settings & Configuration

**Files:**
- `src/pages/SettingsPage.vue`

**Settings Categories:**
- App information
- Platform detection
- Database connection test
- *(Future: Sync preferences, theme, etc.)*

## Project Structure

```
camc/
├── docs/                          # Documentation
│   ├── getting-started/
│   ├── mobile/                    # Android & iOS guides
│   ├── features/                  # Feature documentation
│   └── architecture/              # This file
│
├── scripts/                       # Build and utility scripts
│   ├── android/                   # Android-specific scripts
│   ├── ios/                       # iOS-specific scripts
│   └── dev/                       # Development utilities
│
├── src/                           # Frontend (Vue 3)
│   ├── App.vue
│   ├── main.ts
│   ├── components/
│   ├── pages/
│   ├── router/
│   ├── composables/
│   └── utils/
│
├── src-tauri/                     # Backend (Rust)
│   ├── src/
│   │   ├── main.rs                # Desktop entry
│   │   ├── lib.rs                 # Mobile entry
│   │   ├── commands.rs
│   │   ├── exports.rs
│   │   └── db.rs
│   ├── Cargo.toml
│   ├── tauri.conf.json
│   └── gen/                       # Generated mobile projects
│       ├── android/
│       └── apple/
│
├── .github/workflows/             # CI/CD
├── fastlane/                      # iOS deployment
└── package.json                   # Node dependencies
```

## Build Process

### Development

```bash
# Desktop
npm run tauri:dev

# Android (emulator)
npm run tauri:android:dev

# iOS (simulator)
npm run tauri:ios:dev
```

### Production

```bash
# Desktop (current platform)
npm run tauri:build

# Android APK
npm run tauri:android:build:release

# iOS IPA (for TestFlight)
./scripts/ios/build-local.sh testflight
```

## Cross-Platform Considerations

### Path Handling

**Always use Tauri's path APIs:**
```rust
// ✅ Correct
app.path().document_dir()     // Mobile
app.path().app_data_dir()     // Desktop

// ❌ Wrong (doesn't work on mobile)
dirs::document_dir()
dirs::data_local_dir()
```

### Responsive UI

**Use Quasar breakpoints:**
```vue
<template>
  <q-page-container>
    <!-- Desktop: drawer open -->
    <NavigationDrawer v-if="$q.platform.is.desktop" />
    
    <!-- Mobile: bottom tabs -->
    <BottomNav v-else />
  </q-page-container>
</template>
```

### Platform Detection

```typescript
// Frontend
import { Platform } from 'quasar'
if (Platform.is.ios) { /* iOS-specific */ }
if (Platform.is.android) { /* Android-specific */ }

// Backend
#[cfg(target_os = "ios")]
fn ios_specific() { }

#[cfg(target_os = "android")]
fn android_specific() { }
```

## Security

### Code Signing

- **iOS:** Requires provisioning profile and signing certificate
- **Android:** Signs with keystore (release builds)
- **macOS:** Notarization required for distribution
- **Windows:** Optional code signing certificate

### Permissions

**iOS (Info.plist):**
- File access (automatic with Tauri)
- User Documents access

**Android (AndroidManifest.xml):**
- Storage permissions
- Network access (future)

## Testing

**Current:** Manual testing on each platform

**Planned:**
- Unit tests (Rust + Vitest)
- Integration tests
- End-to-end tests
- Device farm testing (AWS)

## Deployment

### iOS
- **TestFlight:** `./scripts/ios/build-local.sh testflight`
- **App Store:** Via App Store Connect

### Android
- **Internal Testing:** Upload APK to Play Console
- **Production:** Via Play Store

### Desktop
- **macOS:** DMG or PKG
- **Windows:** MSIX or installer EXE

## Future Enhancements

1. **CRDT Sync Implementation**
2. **Congregation Database**
3. **Report Generation**
4. **Data Import/Export**
5. **Theme Customization**
6. **Multi-language Support**
7. **Backup/Restore**

## Related Documentation

- [Getting Started](../getting-started/index.md)
- [Android Setup](../mobile/android-setup.md)
- [iOS Setup](../mobile/ios-setup.md)
- [Feature Documentation](../features/)



