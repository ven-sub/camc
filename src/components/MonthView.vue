<template>
  <div class="month-view">
    <!-- Month Navigation -->
    <div class="row items-center q-mb-lg">
      <div class="col">
        <div class="text-h5 text-weight-medium">
          {{ currentMonthYear }}
        </div>
      </div>
      <div class="col-auto">
        <div class="row q-gutter-sm">
          <q-btn
            flat
            round
            icon="chevron_left"
            @click="previousMonth"
            :disable="isLoading"
          >
            <q-tooltip>Previous Month</q-tooltip>
          </q-btn>
          <q-btn
            flat
            round
            icon="today"
            @click="goToCurrentMonth"
            :disable="isLoading"
          >
            <q-tooltip>Current Month</q-tooltip>
          </q-btn>
          <q-btn
            flat
            round
            icon="chevron_right"
            @click="nextMonth"
            :disable="isLoading"
          >
            <q-tooltip>Next Month</q-tooltip>
          </q-btn>
        </div>
      </div>
    </div>

    <!-- Calendar Grid -->
    <q-card>
      <q-card-section class="q-pa-none">
        <!-- Days of Week Header -->
        <div class="row no-wrap">
          <div 
            v-for="day in daysOfWeek" 
            :key="day"
            class="col calendar-header-cell"
          >
            <div class="text-center text-weight-medium text-grey-7 q-py-sm">
              {{ day }}
            </div>
          </div>
        </div>

        <!-- Calendar Days -->
        <div 
          v-for="week in calendarWeeks" 
          :key="week[0].date"
          class="row no-wrap calendar-week"
        >
          <div 
            v-for="day in week" 
            :key="day.date"
            class="col calendar-day-cell"
            :class="{
              'calendar-day-other-month': !day.isCurrentMonth,
              'calendar-day-today': day.isToday,
              'calendar-day-selected': day.isSelected
            }"
            @click="selectDay(day)"
          >
            <div class="calendar-day-content">
              <!-- Date Number -->
              <div class="calendar-date-number">
                {{ day.dayNumber }}
              </div>
              
              <!-- Events -->
              <div class="calendar-events">
                <div 
                  v-for="event in day.events" 
                  :key="event.id"
                  class="calendar-event"
                  :class="`calendar-event-${event.type}`"
                  @click.stop="handleEventClick(event)"
                >
                  <q-icon 
                    :name="event.icon" 
                    size="12px" 
                    class="q-mr-xs"
                  />
                  <span class="calendar-event-text">{{ event.title }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </q-card-section>
    </q-card>

    <!-- Legend -->
    <div class="row q-mt-md q-gutter-md">
      <div class="col-12 col-md-6">
        <div class="text-subtitle2 q-mb-sm">Event Types</div>
        <div class="row q-gutter-sm">
          <div class="calendar-legend-item">
            <div class="calendar-event-sample calendar-event-visit"></div>
            <span class="text-caption">Congregation Visit</span>
          </div>
          <div class="calendar-legend-item">
            <div class="calendar-event-sample calendar-event-meeting"></div>
            <span class="text-caption">Meeting</span>
          </div>
          <div class="calendar-legend-item">
            <div class="calendar-event-sample calendar-event-holiday"></div>
            <span class="text-caption">Holiday</span>
          </div>
          <div class="calendar-legend-item">
            <div class="calendar-event-sample calendar-event-appointment"></div>
            <span class="text-caption">Appointment</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useQuasar } from 'quasar'

const $q = useQuasar()

// Props
interface Props {
  onWeekSelect?: (weekStart: Date) => void
}

const props = withDefaults(defineProps<Props>(), {
  onWeekSelect: undefined
})

// State
const currentDate = ref(new Date())
const isLoading = ref(false)
const selectedDate = ref<Date | null>(null)

// Constants
const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

// Computed properties
const currentMonthYear = computed(() => {
  return currentDate.value.toLocaleDateString('en-US', { 
    month: 'long', 
    year: 'numeric' 
  })
})

const calendarWeeks = computed(() => {
  const year = currentDate.value.getFullYear()
  const month = currentDate.value.getMonth()
  
  // Get first day of month and calculate starting Sunday
  const firstDay = new Date(year, month, 1)
  const startDate = new Date(firstDay)
  startDate.setDate(firstDay.getDate() - firstDay.getDay())
  
  const weeks = []
  const today = new Date()
  
  for (let week = 0; week < 6; week++) {
    const weekDays = []
    
    for (let day = 0; day < 7; day++) {
      const date = new Date(startDate)
      date.setDate(startDate.getDate() + (week * 7) + day)
      
      const dayNumber = date.getDate()
      const isCurrentMonth = date.getMonth() === month
      const isToday = date.toDateString() === today.toDateString()
      const isSelected = selectedDate.value && date.toDateString() === selectedDate.value.toDateString()
      
      weekDays.push({
        date: date.toISOString(),
        dayNumber,
        isCurrentMonth,
        isToday,
        isSelected,
        events: getEventsForDate(date)
      })
    }
    
    weeks.push(weekDays)
  }
  
  return weeks
})

// Sample events data (in real app, this would come from database)
const sampleEvents = ref([
  // Congregation Visits (spanning Tuesday to Sunday)
  {
    id: 'visit-1',
    type: 'visit',
    title: 'Central Congregation',
    icon: 'location_on',
    startDate: new Date(2024, 11, 3), // December 3, 2024 (Tuesday)
    endDate: new Date(2024, 11, 8),   // December 8, 2024 (Sunday)
    congregation: 'Central Congregation'
  },
  {
    id: 'visit-2',
    type: 'visit',
    title: 'North Congregation',
    icon: 'location_on',
    startDate: new Date(2024, 11, 10), // December 10, 2024 (Tuesday)
    endDate: new Date(2024, 11, 15),   // December 15, 2024 (Sunday)
    congregation: 'North Congregation'
  },
  {
    id: 'visit-3',
    type: 'visit',
    title: 'South Congregation',
    icon: 'location_on',
    startDate: new Date(2024, 11, 17), // December 17, 2024 (Tuesday)
    endDate: new Date(2024, 11, 22),  // December 22, 2024 (Sunday)
    congregation: 'South Congregation'
  },
  
  // Other appointments
  {
    id: 'meeting-1',
    type: 'meeting',
    title: 'Circuit Assembly',
    icon: 'groups',
    startDate: new Date(2024, 11, 7), // December 7, 2024
    endDate: new Date(2024, 11, 7),
    congregation: null
  },
  {
    id: 'holiday-1',
    type: 'holiday',
    title: 'Christmas',
    icon: 'celebration',
    startDate: new Date(2024, 11, 25), // December 25, 2024
    endDate: new Date(2024, 11, 25),
    congregation: null
  },
  {
    id: 'appointment-1',
    type: 'appointment',
    title: 'Elder Meeting',
    icon: 'event',
    startDate: new Date(2024, 11, 12), // December 12, 2024
    endDate: new Date(2024, 11, 12),
    congregation: null
  }
])

// Methods
const getEventsForDate = (date: Date) => {
  return sampleEvents.value.filter(event => {
    const eventStart = new Date(event.startDate)
    const eventEnd = new Date(event.endDate)
    
    // Check if date falls within event range
    return date >= eventStart && date <= eventEnd
  })
}

const previousMonth = async () => {
  if (isLoading.value) return
  
  isLoading.value = true
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() - 1, 1)
  
  await new Promise(resolve => setTimeout(resolve, 200))
  isLoading.value = false
}

const nextMonth = async () => {
  if (isLoading.value) return
  
  isLoading.value = true
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() + 1, 1)
  
  await new Promise(resolve => setTimeout(resolve, 200))
  isLoading.value = false
}

const goToCurrentMonth = async () => {
  if (isLoading.value) return
  
  isLoading.value = true
  currentDate.value = new Date()
  
  await new Promise(resolve => setTimeout(resolve, 200))
  isLoading.value = false
  
  $q.notify({
    type: 'positive',
    message: 'Returned to current month',
    position: 'top',
    timeout: 1000
  })
}

const selectDay = (day: any) => {
  selectedDate.value = new Date(day.date)
  
  // If day has congregation visit events, navigate to that week
  const visitEvents = day.events.filter((event: any) => event.type === 'visit')
  if (visitEvents.length > 0) {
    const visitEvent = visitEvents[0]
    const tuesdayDate = new Date(visitEvent.startDate)
    
    $q.notify({
      type: 'info',
      message: `Opening ${visitEvent.congregation} week schedule`,
      position: 'top',
      timeout: 1500
    })
    
    // Emit event to parent to switch to week view
    if (props.onWeekSelect) {
      props.onWeekSelect(tuesdayDate)
    }
  }
}

const handleEventClick = (event: any) => {
  if (event.type === 'visit') {
    const tuesdayDate = new Date(event.startDate)
    
    $q.notify({
      type: 'info',
      message: `Opening ${event.congregation} week schedule`,
      position: 'top',
      timeout: 1500
    })
    
    if (props.onWeekSelect) {
      props.onWeekSelect(tuesdayDate)
    }
  } else {
    $q.notify({
      type: 'info',
      message: `${event.title} - ${event.startDate.toLocaleDateString()}`,
      position: 'top',
      timeout: 2000
    })
  }
}

// Initialize
onMounted(() => {
  // Set current month
  currentDate.value = new Date()
})
</script>

<style scoped>
.month-view {
  padding: 16px;
}

.calendar-header-cell {
  border-right: 1px solid #e0e0e0;
  border-bottom: 1px solid #e0e0e0;
  min-height: 40px;
}

.calendar-header-cell:last-child {
  border-right: none;
}

.calendar-week {
  border-bottom: 1px solid #e0e0e0;
}

.calendar-week:last-child {
  border-bottom: none;
}

.calendar-day-cell {
  border-right: 1px solid #e0e0e0;
  min-height: 120px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.calendar-day-cell:last-child {
  border-right: none;
}

.calendar-day-cell:hover {
  background-color: #f5f5f5;
}

.calendar-day-other-month {
  background-color: #fafafa;
  color: #bdbdbd;
}

.calendar-day-today {
  background-color: #e3f2fd;
  font-weight: bold;
}

.calendar-day-selected {
  background-color: #bbdefb;
}

.calendar-day-content {
  padding: 8px;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.calendar-date-number {
  font-size: 14px;
  font-weight: 500;
  margin-bottom: 4px;
}

.calendar-events {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.calendar-event {
  display: flex;
  align-items: center;
  padding: 2px 4px;
  border-radius: 3px;
  font-size: 11px;
  cursor: pointer;
  transition: opacity 0.2s;
}

.calendar-event:hover {
  opacity: 0.8;
}

.calendar-event-visit {
  background-color: #2196f3;
  color: white;
}

.calendar-event-meeting {
  background-color: #4caf50;
  color: white;
}

.calendar-event-holiday {
  background-color: #ff9800;
  color: white;
}

.calendar-event-appointment {
  background-color: #9c27b0;
  color: white;
}

.calendar-event-text {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 80px;
}

.calendar-legend-item {
  display: flex;
  align-items: center;
  gap: 4px;
}

.calendar-event-sample {
  width: 12px;
  height: 12px;
  border-radius: 2px;
}

/* Dark mode support */
.body--dark .calendar-header-cell,
.body--dark .calendar-day-cell {
  border-color: #424242;
}

.body--dark .calendar-day-cell:hover {
  background-color: #424242;
}

.body--dark .calendar-day-other-month {
  background-color: #303030;
  color: #757575;
}

.body--dark .calendar-day-today {
  background-color: #1e3a5f;
}

.body--dark .calendar-day-selected {
  background-color: #2c5282;
}

/* Mobile responsiveness */
@media (max-width: 768px) {
  .calendar-day-cell {
    min-height: 80px;
  }
  
  .calendar-date-number {
    font-size: 12px;
  }
  
  .calendar-event {
    font-size: 10px;
    padding: 1px 2px;
  }
  
  .calendar-event-text {
    max-width: 60px;
  }
}
</style>

