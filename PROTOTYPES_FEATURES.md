# Prototypes Page Features

## Overview
The Prototypes page provides test functionality for file export features using Rust backend commands.

## Implemented Features

### 1. ICS Calendar Export
**Button:** "Export ICS Calendar"
**Icon:** event (calendar icon)
**Color:** Primary (blue)

**Functionality:**
- Creates a sample ICS (iCalendar) file with a "Circuit Overseer Visit" event
- Event details:
  - Title: Circuit Overseer Visit
  - Date: November 15, 2025, 10:00 AM - 11:00 AM (UTC)
  - Location: Kingdom Hall
  - Description: Weekly meeting with Circuit Overseer talk
  - Status: CONFIRMED
- Saves file as `sample_event.ics` in app data directory
- Shows success notification with event name
- Displays full file path next to button after export

**File Format:** Standard iCalendar (RFC 5545) format
**File Extension:** `.ics`

### 2. vCard Contact Export
**Button:** "Export vCard"
**Icon:** contact_page (contact card icon)
**Color:** Secondary (teal)

**Functionality:**
- Creates a sample vCard file with contact information
- Contact details:
  - Name: John Smith
  - Organization: Kingdom Hall of Jehovah's Witnesses
  - Title: Elder
  - Phone: +1-555-123-4567
  - Email: john.smith@example.com
  - Address: 123 Main Street, Anytown, CA 12345, USA
  - Note: Circuit Overseer Contact
- Saves file as `sample_contact.vcf` in app data directory
- Shows success notification with contact name
- Displays full file path next to button after export

**File Format:** vCard 3.0 (RFC 2426)
**File Extension:** `.vcf`

## Technical Implementation

### Backend (Rust)
**Files Modified:**
- `src-tauri/src/main.rs` - Desktop builds
- `src-tauri/src/lib.rs` - Mobile builds (iOS/Android)

**Commands Added:**
1. `export_ics() -> Result<String, String>`
   - Uses `dirs::data_local_dir()` to get app data directory
   - Creates directory if needed with `fs::create_dir_all()`
   - Writes ICS content with proper RFC 5545 formatting
   - Returns full file path as string

2. `export_vcard() -> Result<String, String>`
   - Uses `dirs::data_local_dir()` to get app data directory
   - Creates directory if needed with `fs::create_dir_all()`
   - Writes vCard content in version 3.0 format
   - Returns full file path as string

**File Storage Location:**
- **macOS:** `~/Library/Application Support/org.circuitassistant.camc/`
- **Windows:** `C:\Users\<username>\AppData\Local\org.circuitassistant.camc\`
- **Linux:** `~/.local/share/org.circuitassistant.camc/`
- **iOS:** App's Documents directory (sandboxed)
- **Android:** App's internal storage (sandboxed)

### Frontend (Vue/TypeScript)
**File:** `src/pages/PrototypesPage.vue`

**Features:**
- Loading states for both export buttons
- Error handling with user-friendly notifications
- File path display with success icon
- Responsive layout
- Info section explaining file storage location

**UI Components:**
- Quasar buttons with icons
- Quasar notifications (success/error)
- Inline file path display
- Icon indicators for success

### Permissions
**Files Updated:**
- `src-tauri/capabilities/default.json` (desktop)
- `src-tauri/capabilities/mobile.json` (iOS/Android)

**Permissions Added:**
- `fs:allow-create` - Create files
- `fs:allow-mkdir` - Create directories
- `fs:allow-write-text-file` - Write text content
- `fs:allow-write-file` - Write file data

## Cross-Platform Support
✅ **Windows** - Fully supported
✅ **macOS** - Fully supported  
✅ **Linux** - Fully supported
✅ **iOS** - Fully supported (sandboxed storage)
✅ **Android** - Fully supported (sandboxed storage)

## File Compatibility
**ICS Files:**
- Can be imported into:
  - Apple Calendar (macOS, iOS)
  - Google Calendar
  - Microsoft Outlook
  - Thunderbird
  - Any RFC 5545 compatible calendar app

**vCard Files:**
- Can be imported into:
  - Apple Contacts (macOS, iOS)
  - Google Contacts
  - Microsoft Outlook
  - Android Contacts
  - Any vCard 3.0 compatible contact manager

## Testing
To test these features:
1. Navigate to **Prototypes** page (science icon in navigation)
2. Click **"Export ICS Calendar"** button
3. Verify success notification appears
4. Check file path is displayed next to button
5. Navigate to shown file path to verify file was created
6. Try importing the ICS file into a calendar app
7. Click **"Export vCard"** button
8. Verify success notification appears
9. Check file path is displayed next to button
10. Try importing the vCard file into a contacts app

## Future Enhancements
- [ ] Allow custom event data input before export
- [ ] Support multiple events in single ICS file
- [ ] Add vCard photo support
- [ ] Batch export functionality
- [ ] Share dialog integration for mobile
- [ ] Custom file name selection
- [ ] Export history/list

