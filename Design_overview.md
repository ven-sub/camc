# Circuit Assistant Mobile Companion (CAMC)

## Overview
Circuit Assistant Mobile Companion (CAMC) is a cross-platform application designed to assist Circuit Overseers (COs) in managing schedules, congregation reports, and circuit history. CAMC will run on 
**iOS, macOS, Android, and Windows**, with a unified local data model that supports 
**offline-first operation** and 
**peer-to-peer synchronization** using 
**CRDTs** (Conflict-Free Replicated Data Types).

---

## Core Objectives
1. **Cross-platform**: Single codebase targeting desktop (macOS, Windows) and mobile (iOS, Android).
2. **Offline-first**: Operates without an internet connection; uses SQLite (`camc.db`) as the local data store.
3. **Peer-to-peer sync**: Uses CRDTs to merge data from multiple devices with **eventual consistency**.
4. **Privacy-first**: No centralized cloud storage of personal or circuit data.

---

## Key Features (Phase 1)
- **Calendar** — Weekly/monthly view with circuit visits, events, and appointments.  
- **Congregation** — Congregation details, contacts, statistics. TODO, will implement soon.
- **Reports** - Report Templates, Generated reports for specific periods of time etc. TODO, will implement soon.  
- **Settings** — Configuration of sync preferences, CRDT peer discovery, and export/import options.  

*(Notes app removed from initial build.)*

---

## Data Model
- **SQLite Database:** `camc.db`
- **Tables:** CalendarEvents.
- **Sync Layer:** CRDT-based merge engine enabling multi-device consistency and user-to-user data sharing.

---

## CRDT Use Cases
1. **Multi-device usage** — COs can use CAMC on desktop and mobile devices; updates merge automatically when devices reconnect.
2. **Shared data between COs** — PSS and SCE instructors can share class and schedule data directly.
3. **Circuit data transfer** — Replace manual import/export with CRDT-based peer-to-peer sync for history and weekly assignments.

---

## UI Design
- **Desktop (macOS/Windows):** Left-hand navigation panel.
- **Tablet/Mobile:** Bottom navigation toolbar (tab-based).
- **Responsive Layout:** Adjusts dynamically to screen size using shared components.

---

## Technology Stack
| Layer | Technology |
|-------|-------------|
| **Frontend** | Vue 3 + Quasar + Tauri 2 + Rust + TypeScript |
| **Database** | SQLite (`camc.db`) |
| **Sync Engine** | CRDT (Automerge / Yjs / custom lightweight implementation) |
| **Build & Delivery** | GitHub Actions + AWS Device Farm for CI/CD |
| **Packaging** | iOS/macOS (Xcode Cloud or macOS runner), Android (Gradle), Windows (MSIX or exe) |

---

## Next Steps
- ✅ Scaffold prototype and `camc.db`
- ⏳ Implement CalendarEvents database table and persistence
- ⏳ Define CRDT schema and sync workflow
- ⏳ Implement Calendar module
- ⏳ Integrate CI/CD pipeline (GitHub → AWS)
- ⏳ Prepare CRDT peer discovery and testing framework

---

**Last Updated:** 2025-10-28  
