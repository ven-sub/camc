# Calendar Feature

## Overview

The Calendar page provides a month view for managing Circuit Overseer events, visits, and appointments.

## Current Implementation

### Display
- **QCalendar** component for month view
- **Event badges** on dates with events
- **Color-coded** events for visual distinction
- **Click events** to view details

### Import Events

**File Format:** JSON

```json
[
  {
    "title": "Circuit Overseer Visit",
    "date": "2025-11-15",
    "time": "7:00 PM",
    "location": "Kingdom Hall",
    "description": "Weekly meeting with Circuit Overseer talk",
    "color": "primary"
  }
]
```

**Required Fields:**
- `title` (string) - Event name
- `date` (string) - ISO date format (YYYY-MM-DD)

**Optional Fields:**
- `time` (string) - Event time
- `location` (string) - Event location
- `description` (string) - Event details
- `color` (string) - Badge color (primary, green, blue, purple, orange)

### Workflow

1. Click **"Import Events"** button
2. Select JSON file with events
3. Events automatically load and display
4. Click any event badge to see full details
5. Details show in modal dialog

## Sample Events

See `events-sample.json` in project root for example format.

## Planned Features

- [ ] **Database persistence** - Save events to SQLite
- [ ] **Add/Edit/Delete** events in UI
- [ ] **Week view** and day view options
- [ ] **Search** and filter events
- [ ] **Export** events to ICS format
- [ ] **Recurring events** support
- [ ] **Reminders** and notifications
- [ ] **Sync** across devices via CRDT

## Technical Details

**Component:** `src/pages/CalendarPage.vue`

**Dependencies:**
- `@quasar/quasar-ui-qcalendar` - Calendar component
- `@tauri-apps/plugin-dialog` - File selection
- `@tauri-apps/plugin-fs` - File reading

**Data Storage:** Currently in-memory (component state)

**Future:** SQLite table `CalendarEvents`

## Usage

### Import Events

```bash
# Create sample events
npm run tauri -- invoke create_sample_events

# Or manually create JSON file
cat > my-events.json << EOF
[
  {
    "title": "My Event",
    "date": "2025-12-01",
    "time": "2:00 PM",
    "location": "Meeting Place",
    "description": "Event details",
    "color": "blue"
  }
]
EOF
```

Then import via the Calendar page UI.

### Programmatic Access (Future)

```typescript
// Add event
await invoke('add_calendar_event', {
  title: 'New Event',
  date: '2025-12-01',
  time: '2:00 PM'
});

// Get events
const events = await invoke('get_calendar_events', {
  startDate: '2025-11-01',
  endDate: '2025-11-30'
});
```

## Related Documentation

- [File Export Feature](./file-export.md)
- [Architecture](../architecture/design-overview.md)


