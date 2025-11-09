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
              :loading="icsLoading"
            />
            <div v-if="icsFilePath" class="text-caption">
              <q-icon name="check_circle" color="positive" class="q-mr-xs" />
              <strong>Saved to:</strong> {{ icsFilePath }}
            </div>
          </div>

          <!-- vCard Export -->
          <div class="row items-center q-gutter-sm">
            <q-btn
              color="secondary"
              icon="contact_page"
              label="Export vCard"
              @click="exportVCard"
              :loading="vcardLoading"
            />
            <div v-if="vcardFilePath" class="text-caption">
              <q-icon name="check_circle" color="positive" class="q-mr-xs" />
              <strong>Saved to:</strong> {{ vcardFilePath }}
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
import { useQuasar } from 'quasar'
import { invoke } from '@tauri-apps/api/core'

const $q = useQuasar()

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
const icsLoading = ref(false)
const icsFilePath = ref('')

const exportICS = async () => {
  icsLoading.value = true
  icsFilePath.value = ''
  
  try {
    // On all platforms: Use direct export to appropriate directory
    // iOS/Android: Writes to app's Documents directory (accessible via Files app)
    // Desktop: Writes to app data directory
    const filePath = await invoke<string>('export_ics')
    icsFilePath.value = filePath
    
    $q.notify({
      type: 'positive',
      message: 'ICS calendar file exported successfully!',
      caption: isMobile.value 
        ? 'Saved to Files app → Circuit Assistant' 
        : 'Circuit Overseer Visit event created',
      position: 'top'
    })
  } catch (error) {
    console.error('ICS export failed:', error)
    $q.notify({
      type: 'negative',
      message: 'Failed to export ICS file',
      caption: error instanceof Error ? error.message : 'Unknown error',
      position: 'top'
    })
  } finally {
    icsLoading.value = false
  }
}

// vCard Export
const vcardLoading = ref(false)
const vcardFilePath = ref('')

const exportVCard = async () => {
  vcardLoading.value = true
  vcardFilePath.value = ''
  
  try {
    // On all platforms: Use direct export to appropriate directory
    // iOS/Android: Writes to app's Documents directory (accessible via Files app)
    // Desktop: Writes to app data directory
    const filePath = await invoke<string>('export_vcard')
    vcardFilePath.value = filePath
    
    $q.notify({
      type: 'positive',
      message: 'vCard file exported successfully!',
      caption: isMobile.value 
        ? 'Saved to Files app → Circuit Assistant' 
        : 'Contact: John Smith',
      position: 'top'
    })
  } catch (error) {
    console.error('vCard export failed:', error)
    $q.notify({
      type: 'negative',
      message: 'Failed to export vCard file',
      caption: error instanceof Error ? error.message : 'Unknown error',
      position: 'top'
    })
  } finally {
    vcardLoading.value = false
  }
}
</script>

