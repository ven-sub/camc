<template>
  <q-page class="q-pa-md">
    <!-- Header -->
    <div class="row items-center q-mb-lg">
      <div class="col">
        <div class="text-h4 q-mb-sm">Event Calendar</div>
        <div class="text-body1 text-grey-6">
          Import and view your congregation events
        </div>
      </div>
      <div class="col-auto">
        <q-btn
          color="primary"
          icon="upload_file"
          label="Import Events"
          @click="openFileSelector"
        />
      </div>
    </div>

    <!-- Calendar Display -->
    <q-card v-if="events.length > 0">
      <q-card-section>
        <QCalendarMonth
          v-model="selectedDate"
          animated
          bordered
          :day-height="100"
        >
          <template #day="{ scope }">
            <template v-if="getEventsForDay(scope.timestamp.date).length > 0">
              <div
                v-for="(event, index) in getEventsForDay(scope.timestamp.date)"
                :key="index"
                class="q-event"
                :class="`bg-${event.color || 'primary'}`"
                @click.stop="showEventDetails(event)"
              >
                <div class="q-event-title text-white">{{ event.title }}</div>
              </div>
            </template>
          </template>
        </QCalendarMonth>
      </q-card-section>
    </q-card>

    <!-- No Events Message -->
    <q-card v-else class="text-center q-pa-xl">
      <q-icon name="event" size="64px" color="grey-5" class="q-mb-md" />
      <div class="text-h6 text-grey-6 q-mb-md">No Events Loaded</div>
      <div class="text-body2 text-grey-7 q-mb-lg">
        Click "Import Events" to load your event calendar from a JSON file
      </div>
      <q-btn
        color="primary"
        icon="upload_file"
        label="Import Events"
        @click="openFileSelector"
      />
    </q-card>

    <!-- Event Details Dialog -->
    <q-dialog v-model="showEventDialog">
      <q-card style="min-width: 350px">
        <q-card-section>
          <div class="text-h6">{{ selectedEvent?.title }}</div>
        </q-card-section>

        <q-card-section class="q-pt-none">
          <div v-if="selectedEvent?.date" class="q-mb-sm">
            <q-icon name="event" class="q-mr-sm" />
            <strong>Date:</strong> {{ formatDate(selectedEvent.date) }}
          </div>
          <div v-if="selectedEvent?.time" class="q-mb-sm">
            <q-icon name="schedule" class="q-mr-sm" />
            <strong>Time:</strong> {{ selectedEvent.time }}
          </div>
          <div v-if="selectedEvent?.location" class="q-mb-sm">
            <q-icon name="location_on" class="q-mr-sm" />
            <strong>Location:</strong> {{ selectedEvent.location }}
          </div>
          <div v-if="selectedEvent?.description" class="q-mt-md">
            <strong>Description:</strong>
            <div class="q-mt-sm">{{ selectedEvent.description }}</div>
          </div>
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Close" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useQuasar } from 'quasar'
import { QCalendarMonth } from '@quasar/quasar-ui-qcalendar'
import '@quasar/quasar-ui-qcalendar/dist/index.css'
import { open } from '@tauri-apps/plugin-dialog'
import { readTextFile } from '@tauri-apps/plugin-fs'

const $q = useQuasar()

// Calendar state
const selectedDate = ref(new Date().toISOString().slice(0, 10))

// Events data
interface CalendarEvent {
  title: string
  date: string // ISO date string (YYYY-MM-DD)
  time?: string
  location?: string
  description?: string
  color?: string
}

const events = ref<CalendarEvent[]>([])

// Event dialog
const showEventDialog = ref(false)
const selectedEvent = ref<CalendarEvent | null>(null)

// Methods
const openFileSelector = async () => {
  try {
    // Open file dialog to select JSON file
    const selected = await open({
      multiple: false,
      filters: [{
        name: 'JSON',
        extensions: ['json']
      }]
    })

    if (selected && typeof selected === 'string') {
      await loadEventsFromFile(selected)
    }
  } catch (error) {
    console.error('Error opening file selector:', error)
    $q.notify({
      type: 'negative',
      message: 'Failed to open file selector',
      caption: error instanceof Error ? error.message : 'Unknown error',
      position: 'top'
    })
  }
}

const loadEventsFromFile = async (filePath: string) => {
  try {
    // Read the JSON file
    const contents = await readTextFile(filePath)
    
    // Parse JSON
    const jsonData = JSON.parse(contents)
    
    // Validate and load events
    if (Array.isArray(jsonData)) {
      events.value = jsonData.filter(event => 
        event.title && event.date
      ).map(event => ({
        title: event.title,
        date: event.date,
        time: event.time,
        location: event.location,
        description: event.description,
        color: event.color || 'primary'
      }))
      
      $q.notify({
        type: 'positive',
        message: `Successfully loaded ${events.value.length} events`,
        position: 'top'
      })
    } else if (jsonData.events && Array.isArray(jsonData.events)) {
      // Handle case where events are nested in an object
      events.value = jsonData.events.filter(event => 
        event.title && event.date
      ).map(event => ({
        title: event.title,
        date: event.date,
        time: event.time,
        location: event.location,
        description: event.description,
        color: event.color || 'primary'
      }))
      
      $q.notify({
        type: 'positive',
        message: `Successfully loaded ${events.value.length} events`,
        position: 'top'
      })
    } else {
      throw new Error('Invalid JSON format. Expected an array of events.')
    }
  } catch (error) {
    console.error('Error loading events:', error)
    $q.notify({
      type: 'negative',
      message: 'Failed to load events',
      caption: error instanceof Error ? error.message : 'Unknown error',
      position: 'top'
    })
  }
}

const getEventsForDay = (date: string) => {
  return events.value.filter(event => event.date === date)
}

const showEventDetails = (event: CalendarEvent) => {
  selectedEvent.value = event
  showEventDialog.value = true
}

const formatDate = (dateString: string) => {
  const date = new Date(dateString + 'T00:00:00')
  return date.toLocaleDateString('en-US', { 
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}
</script>

<style scoped>
.q-event {
  cursor: pointer;
  margin: 2px 0;
  padding: 2px 4px;
  border-radius: 2px;
  font-size: 11px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.q-event:hover {
  opacity: 0.8;
}

.q-event-title {
  font-weight: 500;
}
</style>
