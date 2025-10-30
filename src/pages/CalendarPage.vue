<template>
  <q-page class="q-pa-md">
    <!-- Header -->
    <div class="row items-center q-mb-lg">
      <div class="col">
        <div class="text-h4 q-mb-sm">Circuit Overseer Visit Schedule</div>
        <div class="text-body1 text-grey-6">
          Manage weekly congregation visits from Tuesday to Sunday
        </div>
      </div>
      <div class="col-auto">
        <div class="row q-gutter-sm">
          <!-- View Toggle -->
          <q-btn-toggle
            v-model="currentView"
            :options="viewOptions"
            color="primary"
            text-color="white"
            toggle-color="primary"
            toggle-text-color="white"
            class="q-mr-md"
          />
          
          <q-btn
            color="primary"
            icon="add"
            label="New Visit"
            @click="addNewVisit"
          />
        </div>
      </div>
    </div>

    <!-- Week View -->
    <div v-if="currentView === 'week'">
      <!-- Week Navigation -->
      <q-card class="q-mb-lg">
        <q-card-section>
          <div class="row items-center q-mb-md">
            <div class="col">
              <div class="text-h6">
                <q-icon name="location_on" class="q-mr-sm" />
                Current Congregation Visit
              </div>
            </div>
            <div class="col-auto">
              <div class="row q-gutter-sm">
                <q-btn
                  flat
                  round
                  icon="chevron_left"
                  @click="previousWeek"
                  :disable="isLoading"
                >
                  <q-tooltip>Previous Week</q-tooltip>
                </q-btn>
                <q-btn
                  flat
                  round
                  icon="today"
                  @click="goToCurrentWeek"
                  :disable="isLoading"
                >
                  <q-tooltip>Current Week</q-tooltip>
                </q-btn>
                <q-btn
                  flat
                  round
                  icon="chevron_right"
                  @click="nextWeek"
                  :disable="isLoading"
                >
                  <q-tooltip>Next Week</q-tooltip>
                </q-btn>
              </div>
            </div>
          </div>
          
          <q-select
            v-model="selectedCongregation"
            :options="congregations"
            label="Select Congregation"
            filled
            class="q-mb-md"
          />
          
          <!-- Week Display -->
          <div class="row items-center">
            <div class="col">
              <div class="text-subtitle1 text-weight-medium">
                Week of {{ currentWeekStart }} - {{ currentWeekEnd }}
              </div>
              <div class="text-caption text-grey-6">
                {{ weekDescription }}
              </div>
            </div>
            <div class="col-auto">
              <q-chip
                :color="weekStatusColor"
                text-color="white"
                :icon="weekStatusIcon"
                :label="weekStatusText"
              />
            </div>
          </div>
        </q-card-section>
      </q-card>

      <!-- Swipeable Week Content -->
      <div 
        class="week-container"
        @touchstart="handleTouchStart"
        @touchmove="handleTouchMove"
        @touchend="handleTouchEnd"
      >
        <q-transition
          appear
          enter-active-class="animated fadeIn"
          leave-active-class="animated fadeOut"
          :duration="300"
        >
          <div :key="currentWeekKey">

    <!-- Weekly Schedule -->
    <div class="row q-gutter-md">
      <!-- Tuesday -->
      <div class="col-12 col-md-6 col-lg-4">
        <q-card class="visit-day-card">
          <q-card-section>
            <div class="text-h6 text-primary q-mb-md">
              <q-icon name="event" class="q-mr-sm" />
              Tuesday
            </div>
            
            <!-- Meeting with Talk -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Meeting with Talk</div>
              <q-input
                v-model="schedule.tuesday.meetingTime"
                label="Meeting Time"
                filled
                type="time"
                class="q-mb-sm"
              />
              <q-input
                v-model="schedule.tuesday.talkTitle"
                label="Talk Title"
                filled
                placeholder="Enter talk title"
              />
            </div>

            <!-- Notes -->
            <div>
              <div class="text-subtitle2 q-mb-sm">Notes</div>
              <q-input
                v-model="schedule.tuesday.notes"
                type="textarea"
                filled
                rows="2"
                placeholder="Add notes for Tuesday..."
              />
            </div>
          </q-card-section>
        </q-card>
      </div>

      <!-- Wednesday -->
      <div class="col-12 col-md-6 col-lg-4">
        <q-card class="visit-day-card">
          <q-card-section>
            <div class="text-h6 text-primary q-mb-md">
              <q-icon name="event" class="q-mr-sm" />
              Wednesday
            </div>
            
            <!-- Morning Service -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Morning Service</div>
              <q-input
                v-model="schedule.wednesday.morningTime"
                label="Morning Time"
                filled
                type="time"
              />
            </div>

            <!-- Afternoon Service -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Afternoon Service</div>
              <q-input
                v-model="schedule.wednesday.afternoonTime"
                label="Afternoon Time"
                filled
                type="time"
              />
            </div>

            <!-- Lunch Break -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Lunch Break</div>
              <q-input
                v-model="schedule.wednesday.lunchFamily"
                label="Lunch with Family"
                filled
                placeholder="Family name"
              />
            </div>

            <!-- Servants Meeting -->
            <div class="q-mb-md" v-if="schedule.wednesday.servantsMeeting">
              <div class="text-subtitle2 q-mb-sm">Servants Meeting</div>
              <q-input
                v-model="schedule.wednesday.servantsTime"
                label="Servants Time"
                filled
                type="time"
              />
            </div>

            <!-- Pioneers Meeting -->
            <div class="q-mb-md" v-if="schedule.wednesday.pioneersMeeting">
              <div class="text-subtitle2 q-mb-sm">Pioneers Meeting</div>
              <q-input
                v-model="schedule.wednesday.pioneersTime"
                label="Pioneers Time"
                filled
                type="time"
              />
            </div>

            <!-- Notes -->
            <div>
              <div class="text-subtitle2 q-mb-sm">Notes</div>
              <q-input
                v-model="schedule.wednesday.notes"
                type="textarea"
                filled
                rows="2"
                placeholder="Add notes for Wednesday..."
              />
            </div>
          </q-card-section>
        </q-card>
      </div>

      <!-- Thursday -->
      <div class="col-12 col-md-6 col-lg-4">
        <q-card class="visit-day-card">
          <q-card-section>
            <div class="text-h6 text-primary q-mb-md">
              <q-icon name="event" class="q-mr-sm" />
              Thursday
            </div>
            
            <!-- Morning Service -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Morning Service</div>
              <q-input
                v-model="schedule.thursday.morningTime"
                label="Morning Time"
                filled
                type="time"
              />
            </div>

            <!-- Afternoon Service -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Afternoon Service</div>
              <q-input
                v-model="schedule.thursday.afternoonTime"
                label="Afternoon Time"
                filled
                type="time"
              />
            </div>

            <!-- Lunch Break -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Lunch Break</div>
              <q-input
                v-model="schedule.thursday.lunchFamily"
                label="Lunch with Family"
                filled
                placeholder="Family name"
              />
            </div>

            <!-- Servants Meeting -->
            <div class="q-mb-md" v-if="schedule.thursday.servantsMeeting">
              <div class="text-subtitle2 q-mb-sm">Servants Meeting</div>
              <q-input
                v-model="schedule.thursday.servantsTime"
                label="Servants Time"
                filled
                type="time"
              />
            </div>

            <!-- Pioneers Meeting -->
            <div class="q-mb-md" v-if="schedule.thursday.pioneersMeeting">
              <div class="text-subtitle2 q-mb-sm">Pioneers Meeting</div>
              <q-input
                v-model="schedule.thursday.pioneersTime"
                label="Pioneers Time"
                filled
                type="time"
              />
            </div>

            <!-- Notes -->
            <div>
              <div class="text-subtitle2 q-mb-sm">Notes</div>
              <q-input
                v-model="schedule.thursday.notes"
                type="textarea"
                filled
                rows="2"
                placeholder="Add notes for Thursday..."
              />
            </div>
          </q-card-section>
        </q-card>
      </div>

      <!-- Friday -->
      <div class="col-12 col-md-6 col-lg-4">
        <q-card class="visit-day-card">
          <q-card-section>
            <div class="text-h6 text-primary q-mb-md">
              <q-icon name="event" class="q-mr-sm" />
              Friday
            </div>
            
            <!-- Morning Service -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Morning Service</div>
              <q-input
                v-model="schedule.friday.morningTime"
                label="Morning Time"
                filled
                type="time"
              />
            </div>

            <!-- Afternoon Service -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Afternoon Service</div>
              <q-input
                v-model="schedule.friday.afternoonTime"
                label="Afternoon Time"
                filled
                type="time"
              />
            </div>

            <!-- Lunch Break -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Lunch Break</div>
              <q-input
                v-model="schedule.friday.lunchFamily"
                label="Lunch with Family"
                filled
                placeholder="Family name"
              />
            </div>

            <!-- Servants Meeting -->
            <div class="q-mb-md" v-if="schedule.friday.servantsMeeting">
              <div class="text-subtitle2 q-mb-sm">Servants Meeting</div>
              <q-input
                v-model="schedule.friday.servantsTime"
                label="Servants Time"
                filled
                type="time"
              />
            </div>

            <!-- Pioneers Meeting -->
            <div class="q-mb-md" v-if="schedule.friday.pioneersMeeting">
              <div class="text-subtitle2 q-mb-sm">Pioneers Meeting</div>
              <q-input
                v-model="schedule.friday.pioneersTime"
                label="Pioneers Time"
                filled
                type="time"
              />
            </div>

            <!-- Notes -->
            <div>
              <div class="text-subtitle2 q-mb-sm">Notes</div>
              <q-input
                v-model="schedule.friday.notes"
                type="textarea"
                filled
                rows="2"
                placeholder="Add notes for Friday..."
              />
            </div>
          </q-card-section>
        </q-card>
      </div>

      <!-- Saturday -->
      <div class="col-12 col-md-6 col-lg-4">
        <q-card class="visit-day-card">
          <q-card-section>
            <div class="text-h6 text-primary q-mb-md">
              <q-icon name="event" class="q-mr-sm" />
              Saturday
            </div>
            
            <!-- Morning Service -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Morning Service</div>
              <q-input
                v-model="schedule.saturday.morningTime"
                label="Morning Time"
                filled
                type="time"
              />
            </div>

            <!-- Afternoon Service -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Afternoon Service</div>
              <q-input
                v-model="schedule.saturday.afternoonTime"
                label="Afternoon Time"
                filled
                type="time"
              />
            </div>

            <!-- Lunch Break -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Lunch Break</div>
              <q-input
                v-model="schedule.saturday.lunchFamily"
                label="Lunch with Family"
                filled
                placeholder="Family name"
              />
            </div>

            <!-- Servants Meeting -->
            <div class="q-mb-md" v-if="schedule.saturday.servantsMeeting">
              <div class="text-subtitle2 q-mb-sm">Servants Meeting</div>
              <q-input
                v-model="schedule.saturday.servantsTime"
                label="Servants Time"
                filled
                type="time"
              />
            </div>

            <!-- Pioneers Meeting -->
            <div class="q-mb-md" v-if="schedule.saturday.pioneersMeeting">
              <div class="text-subtitle2 q-mb-sm">Pioneers Meeting</div>
              <q-input
                v-model="schedule.saturday.pioneersTime"
                label="Pioneers Time"
                filled
                type="time"
              />
            </div>

            <!-- Notes -->
            <div>
              <div class="text-subtitle2 q-mb-sm">Notes</div>
              <q-input
                v-model="schedule.saturday.notes"
                type="textarea"
                filled
                rows="2"
                placeholder="Add notes for Saturday..."
              />
            </div>
          </q-card-section>
        </q-card>
      </div>

      <!-- Sunday -->
      <div class="col-12 col-md-6 col-lg-4">
        <q-card class="visit-day-card">
          <q-card-section>
            <div class="text-h6 text-primary q-mb-md">
              <q-icon name="event" class="q-mr-sm" />
              Sunday
            </div>
            
            <!-- Morning Service -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Morning Service</div>
              <q-input
                v-model="schedule.sunday.morningTime"
                label="Morning Time"
                filled
                type="time"
              />
            </div>

            <!-- Afternoon Service -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Afternoon Service</div>
              <q-input
                v-model="schedule.sunday.afternoonTime"
                label="Afternoon Time"
                filled
                type="time"
              />
            </div>

            <!-- Lunch Break -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Lunch Break</div>
              <q-input
                v-model="schedule.sunday.lunchFamily"
                label="Lunch with Family"
                filled
                placeholder="Family name"
              />
            </div>

            <!-- Servants Meeting -->
            <div class="q-mb-md" v-if="schedule.sunday.servantsMeeting">
              <div class="text-subtitle2 q-mb-sm">Servants Meeting</div>
              <q-input
                v-model="schedule.sunday.servantsTime"
                label="Servants Time"
                filled
                type="time"
              />
            </div>

            <!-- Pioneers Meeting -->
            <div class="q-mb-md" v-if="schedule.sunday.pioneersMeeting">
              <div class="text-subtitle2 q-mb-sm">Pioneers Meeting</div>
              <q-input
                v-model="schedule.sunday.pioneersTime"
                label="Pioneers Time"
                filled
                type="time"
              />
            </div>

            <!-- Weekend Congregation Meeting -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Weekend Congregation Meeting</div>
              <q-input
                v-model="schedule.sunday.congregationMeetingTime"
                label="Meeting Time"
                filled
                type="time"
                class="q-mb-sm"
              />
              <q-input
                v-model="schedule.sunday.talk1Title"
                label="First Talk Title"
                filled
                placeholder="First talk title"
                class="q-mb-sm"
              />
              <q-input
                v-model="schedule.sunday.talk2Title"
                label="Second Talk Title"
                filled
                placeholder="Second talk title"
              />
            </div>

            <!-- Elders Meeting -->
            <div class="q-mb-md">
              <div class="text-subtitle2 q-mb-sm">Elders Goodbye Meeting</div>
              <q-input
                v-model="schedule.sunday.eldersMeetingTime"
                label="Elders Meeting Time"
                filled
                type="time"
              />
            </div>

            <!-- Notes -->
            <div>
              <div class="text-subtitle2 q-mb-sm">Notes</div>
              <q-input
                v-model="schedule.sunday.notes"
                type="textarea"
                filled
                rows="2"
                placeholder="Add notes for Sunday..."
              />
            </div>
          </q-card-section>
        </q-card>
      </div>
    </div>

    <!-- Meeting Schedule Controls -->
    <q-card class="q-mt-lg">
      <q-card-section>
        <div class="text-h6 q-mb-md">
          <q-icon name="schedule" class="q-mr-sm" />
          Meeting Schedule Controls
        </div>
        <div class="row q-gutter-md">
          <div class="col-12 col-md-6">
            <q-checkbox
              v-model="scheduleControls.servantsMeeting"
              label="Schedule Servants Meeting"
              @update:model-value="updateServantsMeeting"
            />
            <q-select
              v-if="scheduleControls.servantsMeeting"
              v-model="scheduleControls.servantsDay"
              :options="servantsDayOptions"
              label="Servants Meeting Day"
              filled
              class="q-mt-sm"
            />
          </div>
          <div class="col-12 col-md-6">
            <q-checkbox
              v-model="scheduleControls.pioneersMeeting"
              label="Schedule Pioneers Meeting"
              @update:model-value="updatePioneersMeeting"
            />
            <q-select
              v-if="scheduleControls.pioneersMeeting"
              v-model="scheduleControls.pioneersDay"
              :options="pioneersDayOptions"
              label="Pioneers Meeting Day"
              filled
              class="q-mt-sm"
            />
          </div>
        </div>
      </q-card-section>
    </q-card>

          </div>
        </q-transition>
      </div>

      <!-- Save Button -->
      <div class="row justify-end q-mt-lg">
        <q-btn
          color="primary"
          icon="save"
          label="Save Schedule"
          @click="saveSchedule"
          size="lg"
        />
      </div>
    </div>

    <!-- Month View -->
    <div v-if="currentView === 'month'">
      <MonthView @week-select="handleWeekSelect" />
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useQuasar } from 'quasar'
import MonthView from '../components/MonthView.vue'

const $q = useQuasar()

// View state
const currentView = ref('week')
const viewOptions = [
  { label: 'Week', value: 'week', icon: 'view_week' },
  { label: 'Month', value: 'month', icon: 'calendar_month' }
]

// Congregation data
const selectedCongregation = ref('')
const congregations = ref([
  'Central Congregation',
  'North Congregation',
  'South Congregation',
  'East Congregation',
  'West Congregation'
])

// Week navigation state
const currentWeekOffset = ref(0) // 0 = current week, -1 = previous week, 1 = next week
const isLoading = ref(false)

// Touch/swipe handling
const touchStartX = ref(0)
const touchStartY = ref(0)
const isSwipeGesture = ref(false)

// Current week calculation with offset
const getWeekDates = (offset: number = 0) => {
  const today = new Date()
  const tuesday = new Date(today)
  const dayOfWeek = today.getDay()
  const daysToTuesday = dayOfWeek === 0 ? 2 : (2 - dayOfWeek + 7) % 7
  tuesday.setDate(today.getDate() + daysToTuesday + (offset * 7))
  
  const sunday = new Date(tuesday)
  sunday.setDate(tuesday.getDate() + 6)
  
  return { tuesday, sunday }
}

const currentWeekStart = computed(() => {
  const { tuesday } = getWeekDates(currentWeekOffset.value)
  return tuesday.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric' 
  })
})

const currentWeekEnd = computed(() => {
  const { sunday } = getWeekDates(currentWeekOffset.value)
  return sunday.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric' 
  })
})

const currentWeekKey = computed(() => {
  const { tuesday } = getWeekDates(currentWeekOffset.value)
  return tuesday.toISOString().split('T')[0]
})

const weekDescription = computed(() => {
  const { tuesday } = getWeekDates(currentWeekOffset.value)
  const today = new Date()
  const diffTime = tuesday.getTime() - today.getTime()
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  
  if (diffDays === 0) return 'This week'
  if (diffDays === 7) return 'Next week'
  if (diffDays === -7) return 'Last week'
  if (diffDays > 0) return `${diffDays} days from now`
  return `${Math.abs(diffDays)} days ago`
})

const weekStatusColor = computed(() => {
  const { tuesday } = getWeekDates(currentWeekOffset.value)
  const today = new Date()
  const diffTime = tuesday.getTime() - today.getTime()
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  
  if (diffDays === 0) return 'green'
  if (diffDays > 0) return 'blue'
  return 'orange'
})

const weekStatusIcon = computed(() => {
  const { tuesday } = getWeekDates(currentWeekOffset.value)
  const today = new Date()
  const diffTime = tuesday.getTime() - today.getTime()
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  
  if (diffDays === 0) return 'today'
  if (diffDays > 0) return 'schedule'
  return 'history'
})

const weekStatusText = computed(() => {
  const { tuesday } = getWeekDates(currentWeekOffset.value)
  const today = new Date()
  const diffTime = tuesday.getTime() - today.getTime()
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  
  if (diffDays === 0) return 'Current'
  if (diffDays > 0) return 'Upcoming'
  return 'Past'
})

// Schedule data structure
const schedule = ref({
  tuesday: {
    meetingTime: '',
    talkTitle: '',
    notes: ''
  },
  wednesday: {
    morningTime: '',
    afternoonTime: '',
    lunchFamily: '',
    servantsMeeting: false,
    servantsTime: '',
    pioneersMeeting: false,
    pioneersTime: '',
    notes: ''
  },
  thursday: {
    morningTime: '',
    afternoonTime: '',
    lunchFamily: '',
    servantsMeeting: false,
    servantsTime: '',
    pioneersMeeting: false,
    pioneersTime: '',
    notes: ''
  },
  friday: {
    morningTime: '',
    afternoonTime: '',
    lunchFamily: '',
    servantsMeeting: false,
    servantsTime: '',
    pioneersMeeting: false,
    pioneersTime: '',
    notes: ''
  },
  saturday: {
    morningTime: '',
    afternoonTime: '',
    lunchFamily: '',
    servantsMeeting: false,
    servantsTime: '',
    pioneersMeeting: false,
    pioneersTime: '',
    notes: ''
  },
  sunday: {
    morningTime: '',
    afternoonTime: '',
    lunchFamily: '',
    servantsMeeting: false,
    servantsTime: '',
    pioneersMeeting: false,
    pioneersTime: '',
    congregationMeetingTime: '',
    talk1Title: '',
    talk2Title: '',
    eldersMeetingTime: '',
    notes: ''
  }
})

// Meeting schedule controls
const scheduleControls = ref({
  servantsMeeting: false,
  servantsDay: 'wednesday',
  pioneersMeeting: false,
  pioneersDay: 'thursday'
})

const servantsDayOptions = [
  { label: 'Wednesday', value: 'wednesday' },
  { label: 'Thursday', value: 'thursday' },
  { label: 'Friday', value: 'friday' },
  { label: 'Saturday', value: 'saturday' },
  { label: 'Sunday', value: 'sunday' }
]

const pioneersDayOptions = [
  { label: 'Wednesday', value: 'wednesday' },
  { label: 'Thursday', value: 'thursday' },
  { label: 'Friday', value: 'friday' },
  { label: 'Saturday', value: 'saturday' },
  { label: 'Sunday', value: 'sunday' }
]

// Methods
const addNewVisit = () => {
  $q.dialog({
    title: 'New Visit',
    message: 'Create a new congregation visit schedule?',
    cancel: true,
    persistent: true
  }).onOk(() => {
    // Reset schedule
    Object.keys(schedule.value).forEach(day => {
      Object.keys(schedule.value[day]).forEach(field => {
        if (typeof schedule.value[day][field] === 'string') {
          schedule.value[day][field] = ''
        } else if (typeof schedule.value[day][field] === 'boolean') {
          schedule.value[day][field] = false
        }
      })
    })
    $q.notify({
      type: 'positive',
      message: 'New visit schedule created',
      position: 'top'
    })
  })
}

const updateServantsMeeting = (value: boolean) => {
  if (value) {
    schedule.value[scheduleControls.value.servantsDay].servantsMeeting = true
  } else {
    // Clear all servants meetings
    Object.keys(schedule.value).forEach(day => {
      if (day !== 'tuesday') {
        schedule.value[day].servantsMeeting = false
        schedule.value[day].servantsTime = ''
      }
    })
  }
}

const updatePioneersMeeting = (value: boolean) => {
  if (value) {
    schedule.value[scheduleControls.value.pioneersDay].pioneersMeeting = true
  } else {
    // Clear all pioneers meetings
    Object.keys(schedule.value).forEach(day => {
      if (day !== 'tuesday') {
        schedule.value[day].pioneersMeeting = false
        schedule.value[day].pioneersTime = ''
      }
    })
  }
}

const saveSchedule = () => {
  $q.notify({
    type: 'positive',
    message: 'Schedule saved successfully',
    position: 'top'
  })
  // TODO: Implement actual save functionality
}

// Week navigation methods
const previousWeek = async () => {
  if (isLoading.value) return
  
  isLoading.value = true
  currentWeekOffset.value -= 1
  
  // Simulate loading delay for smooth UX
  await new Promise(resolve => setTimeout(resolve, 200))
  isLoading.value = false
  
  $q.notify({
    type: 'info',
    message: `Viewing ${weekDescription.value}`,
    position: 'top',
    timeout: 1000
  })
}

const nextWeek = async () => {
  if (isLoading.value) return
  
  isLoading.value = true
  currentWeekOffset.value += 1
  
  // Simulate loading delay for smooth UX
  await new Promise(resolve => setTimeout(resolve, 200))
  isLoading.value = false
  
  $q.notify({
    type: 'info',
    message: `Viewing ${weekDescription.value}`,
    position: 'top',
    timeout: 1000
  })
}

const goToCurrentWeek = async () => {
  if (isLoading.value) return
  
  isLoading.value = true
  currentWeekOffset.value = 0
  
  // Simulate loading delay for smooth UX
  await new Promise(resolve => setTimeout(resolve, 200))
  isLoading.value = false
  
  $q.notify({
    type: 'positive',
    message: 'Returned to current week',
    position: 'top',
    timeout: 1000
  })
}

// Touch/swipe handling methods
const handleTouchStart = (event: TouchEvent) => {
  touchStartX.value = event.touches[0].clientX
  touchStartY.value = event.touches[0].clientY
  isSwipeGesture.value = false
}

const handleTouchMove = (event: TouchEvent) => {
  if (!touchStartX.value || !touchStartY.value) return
  
  const touchCurrentX = event.touches[0].clientX
  const touchCurrentY = event.touches[0].clientY
  
  const diffX = touchStartX.value - touchCurrentX
  const diffY = touchStartY.value - touchCurrentY
  
  // Determine if this is a horizontal swipe (more horizontal than vertical movement)
  if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > 50) {
    isSwipeGesture.value = true
    event.preventDefault() // Prevent scrolling during swipe
  }
}

const handleTouchEnd = (event: TouchEvent) => {
  if (!isSwipeGesture.value || !touchStartX.value) return
  
  const touchEndX = event.changedTouches[0].clientX
  const diffX = touchStartX.value - touchEndX
  
  // Minimum swipe distance
  const minSwipeDistance = 100
  
  if (Math.abs(diffX) > minSwipeDistance) {
    if (diffX > 0) {
      // Swipe left - go to next week
      nextWeek()
    } else {
      // Swipe right - go to previous week
      previousWeek()
    }
  }
  
  // Reset touch state
  touchStartX.value = 0
  touchStartY.value = 0
  isSwipeGesture.value = false
}

// Handle week selection from month view
const handleWeekSelect = (weekStartDate: Date) => {
  // Calculate the week offset from current week
  const today = new Date()
  const currentTuesday = new Date(today)
  const dayOfWeek = today.getDay()
  const daysToTuesday = dayOfWeek === 0 ? 2 : (2 - dayOfWeek + 7) % 7
  currentTuesday.setDate(today.getDate() + daysToTuesday)
  
  // Calculate difference in weeks
  const diffTime = weekStartDate.getTime() - currentTuesday.getTime()
  const diffWeeks = Math.round(diffTime / (1000 * 60 * 60 * 24 * 7))
  
  // Set the week offset and switch to week view
  currentWeekOffset.value = diffWeeks
  currentView.value = 'week'
  
  $q.notify({
    type: 'positive',
    message: `Switched to week view for ${weekStartDate.toLocaleDateString()}`,
    position: 'top',
    timeout: 2000
  })
}

// Initialize component
onMounted(() => {
  // Load any saved schedule data for current week
  // TODO: Implement data loading from database
})
</script>

<style scoped>
.visit-day-card {
  min-height: 400px;
}

.visit-day-card .q-card__section {
  padding: 16px;
}

.week-container {
  position: relative;
  overflow: hidden;
  touch-action: pan-y; /* Allow vertical scrolling but handle horizontal swipes */
}

.week-container:active {
  cursor: grabbing;
}

/* Smooth transitions for week changes */
.animated {
  animation-duration: 0.3s;
  animation-fill-mode: both;
}

.fadeIn {
  animation-name: fadeIn;
}

.fadeOut {
  animation-name: fadeOut;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateX(20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

@keyframes fadeOut {
  from {
    opacity: 1;
    transform: translateX(0);
  }
  to {
    opacity: 0;
    transform: translateX(-20px);
  }
}

/* Loading state */
.week-container.loading {
  opacity: 0.7;
  pointer-events: none;
}

/* Mobile-specific styles */
@media (max-width: 768px) {
  .week-container {
    padding: 0 8px;
  }
  
  .visit-day-card {
    min-height: 350px;
  }
  
  .visit-day-card .q-card__section {
    padding: 12px;
  }
}
</style>