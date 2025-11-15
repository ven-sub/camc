# File Export Feature

## Overview

Export data in standard formats (ICS, vCard, JSON) for sharing and integration with other apps.

## Supported Formats

### 1. ICS (iCalendar) Export

**Format:** RFC 5545 (iCalendar)  
**Extension:** `.ics`  
**Use Case:** Import into Apple Calendar, Google Calendar, Outlook, etc.

**Sample Output:**
```
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Circuit Assistant//EN
BEGIN:VEVENT
UID:sample-event-001@circuitassistant.org
DTSTAMP:20251109T120000Z
DTSTART:20251115T100000Z
DTEND:20251115T110000Z
SUMMARY:Circuit Overseer Visit
DESCRIPTION:Weekly meeting with Circuit Overseer talk
LOCATION:Kingdom Hall
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR
```

**Usage:**
```typescript
import { invoke } from '@tauri-apps/api/core'

// Export ICS file
const filePath = await invoke('export_ics')
console.log('ICS exported to:', filePath)
```

### 2. vCard Export

**Format:** vCard 3.0 (RFC 2426)  
**Extension:** `.vcf`  
**Use Case:** Import contacts into phone, email clients, CRM systems

**Sample Output:**
```
BEGIN:VCARD
VERSION:3.0
FN:John Smith
N:Smith;John;;;
ORG:Kingdom Hall of Jehovah's Witnesses
TITLE:Elder
TEL;TYPE=CELL:+1-555-123-4567
EMAIL:john.smith@example.com
ADR;TYPE=HOME:;;123 Main Street;Anytown;CA;12345;USA
NOTE:Circuit Overseer Contact
END:VCARD
```

**Usage:**
```typescript
// Export vCard file
const filePath = await invoke('export_vcard')
console.log('vCard exported to:', filePath)
```

### 3. JSON Export

**Format:** Custom JSON structure  
**Extension:** `.json`  
**Use Case:** Data backup, custom integrations

**Usage:**
```typescript
// Create sample events JSON
const filePath = await invoke('create_sample_events')
console.log('JSON exported to:', filePath)

// List JSON files
const files = await invoke('list_json_files')

// Read JSON file
const content = await invoke('read_json_file', { 
  filePath: files[0].path 
})
```

## File Locations

### Mobile (iOS/Android)

**Directory:** App's Documents folder (visible in Files app)

**iOS:**
- Files app → On My iPhone → Circuit Assistant

**Android:**
- Files app → Internal Storage → Documents → org.circuitassistant.camc

### Desktop

**macOS:**
```
~/Library/Application Support/org.circuitassistant.camc/
```

**Windows:**
```
C:\Users\<username>\AppData\Local\org.circuitassistant.camc\
```

**Linux:**
```
~/.local/share/org.circuitassistant.camc/
```

## Implementation

### Backend Commands (Rust)

**File:** `src-tauri/src/exports.rs`

```rust
// Export ICS calendar
#[tauri::command]
pub fn export_ics(app: AppHandle) -> Result<String, String>

// Export vCard contact
#[tauri::command]
pub fn export_vcard(app: AppHandle) -> Result<String, String>

// Get ICS content (for mobile sharing)
#[tauri::command]
pub fn get_ics_content() -> String

// Get vCard content (for mobile sharing)
#[tauri::command]
pub fn get_vcard_content() -> String

// List JSON files in Documents
#[tauri::command]
pub fn list_json_files(app: AppHandle) -> Result<Vec<FileInfo>, String>

// Read JSON file
#[tauri::command]
pub fn read_json_file(file_path: String) -> Result<String, String>

// Create sample events JSON
#[tauri::command]
pub fn create_sample_events(app: AppHandle) -> Result<String, String>
```

### Frontend Composable

**File:** `src/composables/useFileExport.ts`

```typescript
export function useFileExport() {
  const exportICS = async () => {
    const filePath = await invoke('export_ics')
    // Show notification
  }
  
  const exportVCard = async () => {
    const filePath = await invoke('export_vcard')
    // Show notification
  }
  
  return { exportICS, exportVCard }
}
```

## Mobile Considerations

On iOS and Android, direct file system access is restricted. There are two approaches:

### Approach 1: Write to Documents (Current)

Files are saved to the app's Documents directory, visible in the Files app.

**Pros:**
- Simple implementation
- Files persist
- User can access via Files app

**Cons:**
- User must navigate to Files app
- Extra step to share

### Approach 2: Share Dialog (Future)

Use native share dialog to let user choose destination.

```rust
// Future implementation
#[tauri::command]
pub fn share_ics(content: String) -> Result<(), String> {
    #[cfg(mobile)]
    {
        // Use platform share API
        platform_share(content, "event.ics", "text/calendar")
    }
}
```

## Testing

### Desktop

1. Run app: `npm run tauri:dev`
2. Go to Prototypes page
3. Click "Export ICS Calendar"
4. Check file location in notification
5. Open file in Calendar app

### Mobile

1. Build and run: `npm run tauri:android:dev` or `npm run tauri:ios:dev`
2. Go to Prototypes page
3. Click export button
4. Open Files app
5. Navigate to app's Documents folder
6. Find exported file

## Future Enhancements

- [ ] **Batch export** - Export multiple events/contacts at once
- [ ] **Custom templates** - User-defined export formats
- [ ] **Direct sharing** - Native share dialog on mobile
- [ ] **Cloud sync** - Optional backup to iCloud/Google Drive
- [ ] **Import** - Import ICS/vCard files
- [ ] **PDF export** - Generate printable reports

## Related Documentation

- [Calendar Feature](./calendar.md)
- [Architecture](../architecture/design-overview.md)
- [Prototypes Page](../../src/pages/PrototypesPage.vue)


