export interface CalendarEvent {
  title: string
  date: string // ISO date string (YYYY-MM-DD)
  time?: string
  location?: string
  description?: string
  color?: string
}

/**
 * Parses and validates event data from JSON
 * Handles both array format and nested object format
 */
export function parseEventsData(jsonData: any): CalendarEvent[] {
  // Get the array of events (either direct array or nested in .events property)
  const eventsArray = Array.isArray(jsonData) 
    ? jsonData 
    : jsonData.events && Array.isArray(jsonData.events)
    ? jsonData.events
    : null

  if (!eventsArray) {
    throw new Error('Invalid JSON format. Expected an array of events.')
  }

  // Filter and map events
  return eventsArray
    .filter(event => event.title && event.date)
    .map(event => ({
      title: event.title,
      date: event.date,
      time: event.time,
      location: event.location,
      description: event.description,
      color: event.color || 'primary'
    }))
}

