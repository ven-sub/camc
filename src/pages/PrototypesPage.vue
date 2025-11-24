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

          <!-- Fillable PDF Generation -->
          <div class="row items-center q-gutter-sm">
            <q-btn
              color="deep-purple"
              icon="picture_as_pdf"
              label="Create Fillable PDF"
              @click="showPdfDialog = true"
            />
          </div>

          <!-- Print Preview List -->
          <div class="row items-center q-gutter-sm">
            <q-btn
              color="orange"
              icon="print"
              label="Print Preview List"
              @click="openPrintList"
            />
          </div>

          <!-- Model CRUD -->
          <div class="row items-center q-gutter-sm">
            <q-btn
              color="teal"
              icon="database"
              label="Model CRUD"
              @click="openModelCrud"
            />
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

    <!-- PDF Type Selection Dialog -->
    <q-dialog v-model="showPdfDialog">
      <q-card style="min-width: 350px">
        <q-card-section>
          <div class="text-h6">Select Form Type</div>
          <div class="text-caption text-grey-7">Choose a form to generate</div>
        </q-card-section>

        <q-card-section class="q-pt-none q-gutter-sm">
          <q-btn
            color="primary"
            icon="event"
            label="Meeting Schedule"
            @click="generatePdf('printpdf')"
            :loading="pdfLoading === 'printpdf'"
            class="full-width"
            align="left"
          />
          <q-btn
            color="secondary"
            icon="map"
            label="Territory Assignment"
            @click="generatePdf('lopdf')"
            :loading="pdfLoading === 'lopdf'"
            class="full-width"
            align="left"
          />
          <q-btn
            color="accent"
            icon="assignment"
            label="Service Report"
            @click="generatePdf('genpdf')"
            :loading="pdfLoading === 'genpdf'"
            class="full-width"
            align="left"
          />
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Cancel" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { invoke } from '@tauri-apps/api/core'
import { useFileExport } from '../composables/useFileExport'

const router = useRouter()

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

// PDF Dialog State
const showPdfDialog = ref(false)
const pdfLoading = ref<string | null>(null)

const generatePdf = async (type: 'printpdf' | 'lopdf' | 'genpdf') => {
  pdfLoading.value = type
  try {
    const commandMap = {
      printpdf: 'generate_pdf_printpdf',
      lopdf: 'generate_pdf_lopdf',
      genpdf: 'generate_pdf_genpdf'
    }
    const formNames = {
      printpdf: 'Meeting Schedule',
      lopdf: 'Territory Assignment',
      genpdf: 'Service Report'
    }
    
    const filePath = await invoke<string>(commandMap[type])
    
    // Show success notification (similar to existing exports)
    console.log(`${formNames[type]} PDF created:`, filePath)
    showPdfDialog.value = false
  } catch (error) {
    console.error('PDF generation failed:', error)
  } finally {
    pdfLoading.value = null
  }
}

const openPrintList = () => {
  router.push('/print-list')
}

const openModelCrud = () => {
  router.push('/model-crud')
}
</script>

