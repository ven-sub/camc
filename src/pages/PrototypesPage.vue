<template>
  <q-page class="q-pa-md">
    <div class="text-h4 q-mb-sm">Prototypes</div>
    <div class="text-body1 text-grey-6 q-mb-lg">
      Test various features and components
    </div>

    <q-card>
      <q-card-section>
        <div class="text-h6 q-mb-md">File Export Tests</div>
        
        <div class="q-gutter-md">
          <!-- ICS Calendar Export -->
          <div class="row items-center q-gutter-sm">
            <q-btn
              color="primary"
              icon="event"
              label="Export ICS Calendar"
              @click="exportICS"
              :loading="icsExport.loading.value"
            />
            <div v-if="icsExport.filePath.value" class="text-caption">
              <q-icon name="check_circle" color="positive" class="q-mr-xs" />
              <strong>Saved to:</strong> {{ icsExport.filePath.value }}
            </div>
          </div>

          <!-- vCard Export -->
          <div class="row items-center q-gutter-sm">
            <q-btn
              color="secondary"
              icon="contact_page"
              label="Export vCard"
              @click="exportVCard"
              :loading="vcardExport.loading.value"
            />
            <div v-if="vcardExport.filePath.value" class="text-caption">
              <q-icon name="check_circle" color="positive" class="q-mr-xs" />
              <strong>Saved to:</strong> {{ vcardExport.filePath.value }}
            </div>
          </div>

          <!-- Sample Events Export -->
          <div class="row items-center q-gutter-sm">
            <q-btn
              color="accent"
              icon="event_note"
              label="Create Sample Events"
              @click="createSampleEvents"
              :loading="eventsExport.loading.value"
            />
            <div v-if="eventsExport.filePath.value" class="text-caption">
              <q-icon name="check_circle" color="positive" class="q-mr-xs" />
              <strong>Saved to:</strong> {{ eventsExport.filePath.value }}
            </div>
          </div>
        </div>
      </q-card-section>

      <q-separator />

      <q-card-section>
        <div class="text-subtitle2 text-grey-7">
          <q-icon name="info" class="q-mr-xs" />
          Files are saved to the app's local data directory
        </div>
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { invoke } from '@tauri-apps/api/core'
import { useFileExport } from '../composables/useFileExport'

// Platform detection for user feedback messages
const isMobile = ref(false)

onMounted(async () => {
  try {
    const platform = await invoke<string>('get_platform')
    isMobile.value = platform === 'ios' || platform === 'android'
  } catch (error) {
    console.error('Failed to detect platform:', error)
  }
})

// ICS Export
const icsExport = useFileExport({
  commandName: 'export_ics',
  successMessage: 'ICS calendar file exported successfully!',
  mobileCaption: 'Saved to Files app → Circuit Assistant',
  desktopCaption: 'Circuit Overseer Visit event created'
})

const exportICS = () => icsExport.execute(isMobile.value)

// vCard Export
const vcardExport = useFileExport({
  commandName: 'export_vcard',
  successMessage: 'vCard file exported successfully!',
  mobileCaption: 'Saved to Files app → Circuit Assistant',
  desktopCaption: 'Contact: John Smith'
})

const exportVCard = () => vcardExport.execute(isMobile.value)

// Sample Events Export
const eventsExport = useFileExport({
  commandName: 'create_sample_events',
  successMessage: 'Sample events file created successfully!',
  mobileCaption: 'Saved to Files app → Circuit Assistant → events-sample.json',
  desktopCaption: '5 sample events created'
})

const createSampleEvents = () => eventsExport.execute(isMobile.value)
</script>

