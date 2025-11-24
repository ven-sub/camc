<template>
  <q-page class="q-pa-md">
    <div class="row items-center q-mb-md">
      <q-btn
        flat
        icon="arrow_back"
        label="Back"
        @click="goBack"
        class="q-mr-md"
      />
      <div class="text-h4">Print Preview List</div>
    </div>

    <!-- Toolbar -->
    <q-card class="q-mb-md">
      <q-card-section>
        <div class="row items-center q-gutter-md">
          <q-btn
            color="primary"
            icon="add"
            label="Add Item"
            @click="showAddDialog = true"
          />
          <q-btn-toggle
            v-model="viewMode"
            toggle-color="primary"
            :options="[
              { label: 'Basic', value: 'basic' },
              { label: 'Detailed', value: 'detailed' }
            ]"
          />
          <q-space />
          <q-btn
            color="secondary"
            icon="settings"
            label="Print Settings"
            @click="showSettingsDialog = true"
          />
          <q-btn
            color="positive"
            icon="print"
            label="Print"
            @click="handlePrint"
          />
          <q-btn
            color="deep-purple"
            icon="picture_as_pdf"
            label="Export PDF"
            @click="exportToPdf"
            :loading="pdfExporting"
          />
          <q-btn
            color="purple"
            icon="picture_as_pdf"
            label="Export Oxidize PDF"
            @click="exportToPdfOxidize"
            :loading="pdfExportingOxidize"
          />
        </div>
      </q-card-section>
    </q-card>

    <div class="row q-col-gutter-md">
      <!-- Editable List Section -->
      <div class="col-12 col-md-6">
        <q-card>
          <q-card-section>
            <div class="text-h6 q-mb-md">Edit List</div>
            <div v-if="listItems.length > 0" class="table-container">
              <q-table
                :rows="listItems"
                :columns="tableColumns"
                row-key="index"
                flat
                bordered
                dense
                :rows-per-page-options="[0]"
                hide-pagination
              >
                <template v-slot:body-cell-actions="props">
                  <q-td :props="props">
                    <q-btn
                      flat
                      dense
                      round
                      icon="edit"
                      color="primary"
                      size="sm"
                      @click="editItem(props.rowIndex)"
                    />
                    <q-btn
                      flat
                      dense
                      round
                      icon="delete"
                      color="negative"
                      size="sm"
                      @click="deleteItem(props.rowIndex)"
                      class="q-ml-xs"
                    />
                  </q-td>
                </template>
              </q-table>
            </div>
            <div v-else class="text-center q-pa-lg text-grey-6">
              <q-icon name="list" size="48px" class="q-mb-sm" />
              <div>No items yet. Click "Add Item" to get started.</div>
            </div>
          </q-card-section>
        </q-card>
      </div>

      <!-- Print Preview Section -->
      <div class="col-12 col-md-6">
        <q-card>
          <q-card-section>
            <div class="row items-center q-mb-md">
              <div class="text-h6">Print Preview</div>
              <q-space />
              <q-badge
                :color="(settings.orientation || 'portrait') === 'landscape' ? 'orange' : 'blue'"
                :label="(settings.orientation || 'portrait').toString().toUpperCase()"
                class="q-ml-md orientation-badge"
              />
              <q-badge
                color="grey-6"
                :label="settings.pageSize"
                class="q-ml-sm"
              />
            </div>
            <div 
              class="print-preview-container" 
              :class="{ 'landscape-mode': (settings.orientation || 'portrait') === 'landscape' }"
              :style="printStyles"
            >
              <div class="print-preview-content" :class="[viewMode, settings.orientation || 'portrait']" ref="previewContent">
                <div class="print-header">
                  <h1>Program Schedule</h1>
                  <div class="print-meta">
                    Generated: {{ new Date().toLocaleDateString() }}
                  </div>
                  <div class="print-intro">
                    <p>This document contains the program schedule with detailed information for each item.</p>
                  </div>
                </div>
                <div class="print-body" ref="printBody">
                  <table class="print-table">
                    <thead>
                      <tr>
                        <th class="col-time">Time</th>
                        <th class="col-theme">Theme</th>
                        <th class="col-speaker">Speaker</th>
                        <th class="col-type">Type</th>
                        <th class="col-instructions">Instructions</th>
                      </tr>
                    </thead>
                    <tbody>
                      <template v-for="(item, index) in listItems" :key="index">
                        <!-- Page break separator -->
                        <tr v-if="shouldShowPageBreak(index)" class="page-break-row">
                          <td colspan="5">
                            <div class="page-break-separator">
                              <div class="page-break-line"></div>
                              <div class="page-break-label">Page Break</div>
                              <div class="page-break-line"></div>
                            </div>
                          </td>
                        </tr>
                        <tr class="print-item-row">
                          <td class="col-time">{{ item.time || '' }}</td>
                          <td class="col-theme">
                            <span v-if="item.itemNumber" class="item-number">{{ item.itemNumber }}:</span>
                            {{ item.theme }}
                          </td>
                          <td class="col-speaker">{{ item.speaker || '' }}</td>
                          <td class="col-type">
                            <span v-if="item.type">{{ item.type }}</span>
                            <span v-if="item.duration" class="duration"> ({{ item.duration }})</span>
                          </td>
                          <td class="col-instructions">
                            <template v-if="viewMode === 'detailed' && item.instructions">
                              {{ item.instructions }}
                            </template>
                          </td>
                        </tr>
                      </template>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </q-card-section>
        </q-card>
      </div>
    </div>

    <!-- Add/Edit Item Dialog -->
    <q-dialog v-model="showAddDialog">
      <q-card style="min-width: 350px">
        <q-card-section>
          <div class="text-h6">{{ editingIndex !== null ? 'Edit' : 'Add' }} Item</div>
        </q-card-section>

        <q-card-section class="q-pt-none">
          <q-input
            v-model="currentItem.time"
            label="Time"
            outlined
            dense
            class="q-mb-md"
            hint="e.g., 9:40 AM"
          />
          <q-input
            v-model="currentItem.itemNumber"
            label="Item Number"
            outlined
            dense
            class="q-mb-md"
            hint="e.g., #1, #2 (optional)"
          />
          <q-input
            v-model="currentItem.theme"
            label="Theme *"
            outlined
            dense
            class="q-mb-md"
          />
          <q-input
            v-model="currentItem.speaker"
            label="Speaker"
            outlined
            dense
            class="q-mb-md"
            hint="e.g., CO Jovan King or TBA"
          />
          <q-input
            v-model="currentItem.type"
            label="Type"
            outlined
            dense
            class="q-mb-md"
            hint="e.g., Talk, Song, Prayer, Music"
          />
          <q-input
            v-model="currentItem.duration"
            label="Duration"
            outlined
            dense
            class="q-mb-md"
            hint="e.g., 14 minutes"
          />
          <q-input
            v-model="currentItem.instructions"
            label="Instructions"
            outlined
            dense
            type="textarea"
            rows="4"
            class="q-mb-md"
            hint="Detailed instructions for this item"
          />
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Cancel" color="primary" v-close-popup />
          <q-btn
            flat
            label="Save"
            color="primary"
            @click="saveItem"
            v-close-popup
          />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- Print Settings Dialog -->
    <q-dialog v-model="showSettingsDialog">
      <q-card style="min-width: 400px">
        <q-card-section>
          <div class="text-h6">Print Settings</div>
        </q-card-section>

        <q-card-section class="q-pt-none">
          <q-select
            v-model="settings.pageSize"
            :options="['Letter', 'A4', 'Legal']"
            label="Page Size"
            outlined
            dense
            class="q-mb-md"
          />
          <q-select
            v-model="settings.orientation"
            :options="[
              { label: 'Portrait', value: 'portrait' },
              { label: 'Landscape', value: 'landscape' }
            ]"
            option-label="label"
            option-value="value"
            emit-value
            map-options
            label="Orientation"
            outlined
            dense
            class="q-mb-md"
          />
          <div class="text-subtitle2 q-mb-sm">Margins (mm)</div>
          <div class="row q-col-gutter-sm q-mb-md">
            <div class="col-6">
              <q-input
                v-model.number="settings.margins.top"
                label="Top"
                outlined
                dense
                type="number"
              />
            </div>
            <div class="col-6">
              <q-input
                v-model.number="settings.margins.bottom"
                label="Bottom"
                outlined
                dense
                type="number"
              />
            </div>
            <div class="col-6">
              <q-input
                v-model.number="settings.margins.left"
                label="Left"
                outlined
                dense
                type="number"
              />
            </div>
            <div class="col-6">
              <q-input
                v-model.number="settings.margins.right"
                label="Right"
                outlined
                dense
                type="number"
              />
            </div>
          </div>
          <q-input
            v-model.number="settings.fontSize"
            label="Font Size (pt)"
            outlined
            dense
            type="number"
          />
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Reset" color="primary" @click="resetSettings" />
          <q-btn flat label="Close" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useQuasar } from 'quasar'
import { invoke } from '@tauri-apps/api/core'
import { usePrintSettings } from '../composables/usePrintSettings'
import html2pdf from 'html2pdf.js'
import './PrintPreviewPage.css'

const router = useRouter()
const $q = useQuasar()

interface ListItem {
  time?: string
  itemNumber?: string
  theme: string
  speaker?: string
  type?: string
  duration?: string
  instructions?: string
}

const { settings, printStyles, resetSettings: resetPrintSettings } = usePrintSettings()
const viewMode = ref<'basic' | 'detailed'>('basic')
const listItems = ref<ListItem[]>([
  { 
    time: '9:40 AM',
    itemNumber: '',
    theme: 'Music',
    speaker: 'TBA',
    type: 'Music',
    duration: '10 minutes',
    instructions: ''
  },
  { 
    time: '9:50 AM',
    itemNumber: '',
    theme: 'Song No. 1',
    speaker: '',
    type: 'Song',
    duration: '5 minutes',
    instructions: ''
  },
  { 
    time: '9:55 AM',
    itemNumber: '',
    theme: 'Prayer',
    speaker: 'CO Jovan King',
    type: 'Prayer',
    duration: '5 minutes',
    instructions: ''
  },
  { 
    time: '10:00 AM',
    itemNumber: '#1',
    theme: '"Hear What the Spirit Says"—How?',
    speaker: 'TBA',
    type: 'Talk',
    duration: '14 minutes',
    instructions: 'You do not need to read or comment on every cited text or discuss every subpoint. After answering the review question, end your talk with a motivating conclusion.'
  },
  { 
    time: '10:15 AM',
    itemNumber: '#2',
    theme: '"You . . . Have Not Grown Weary"',
    speaker: 'TBA',
    type: 'Talk',
    duration: '24 minutes',
    instructions: 'Jesus\' messages to seven first-century congregations in Asia Minor. Focus on Ephesus and cultivating love.'
  }
])

const showAddDialog = ref(false)
const showSettingsDialog = ref(false)
const editingIndex = ref<number | null>(null)
const pdfExporting = ref(false)
const pdfExportingOxidize = ref(false)
const previewContent = ref<HTMLElement | null>(null)
const printBody = ref<HTMLElement | null>(null)

const currentItem = ref<ListItem>({
  time: '',
  itemNumber: '',
  theme: '',
  speaker: '',
  type: '',
  duration: '',
  instructions: ''
})

// Table columns for editable list
const tableColumns = [
  { name: 'time', label: 'Time', field: 'time', align: 'left' as const, style: 'width: 80px' },
  { name: 'itemNumber', label: '#', field: 'itemNumber', align: 'center' as const, style: 'width: 50px' },
  { name: 'theme', label: 'Theme', field: 'theme', align: 'left' as const, style: 'min-width: 120px' },
  { name: 'speaker', label: 'Speaker', field: 'speaker', align: 'left' as const, style: 'width: 100px' },
  { name: 'type', label: 'Type', field: 'type', align: 'left' as const, style: 'width: 80px' },
  { name: 'duration', label: 'Duration', field: 'duration', align: 'left' as const, style: 'width: 90px' },
  { name: 'instructions', label: 'Instructions', field: 'instructions', align: 'left' as const, style: 'min-width: 150px; max-width: 200px' },
  { name: 'actions', label: '', field: '', align: 'center' as const, style: 'width: 90px' }
]

// Calculate page height in pixels for page break detection
const pageHeightPx = computed(() => {
  // Get page height from CSS variable and convert to pixels
  // Approximate conversion: 1in = 96px, 1mm = 3.779px
  const pageHeight = settings.value.orientation === 'landscape' 
    ? (settings.value.pageSize === 'A4' ? '210mm' : settings.value.pageSize === 'Legal' ? '8.5in' : '11in')
    : (settings.value.pageSize === 'A4' ? '297mm' : settings.value.pageSize === 'Legal' ? '14in' : '11in')
  
  if (pageHeight.includes('mm')) {
    return parseFloat(pageHeight) * 3.779
  } else if (pageHeight.includes('in')) {
    return parseFloat(pageHeight) * 96
  }
  return 11 * 96 // Default to Letter portrait
})

// Calculate available content height (page height - margins - header)
const availableContentHeight = computed(() => {
  const topMargin = settings.value.margins.top * 3.779 // mm to px
  const bottomMargin = settings.value.margins.bottom * 3.779
  const headerHeight = 120 // Approximate header height in px (includes intro text)
  const tableHeaderHeight = 40 // Table header row height
  const available = pageHeightPx.value - topMargin - bottomMargin - headerHeight - tableHeaderHeight
  return Math.max(available, 200) // Ensure minimum height
})

// Calculate height for a specific item
const calculateItemHeight = (item: ListItem): number => {
  const baseRowHeight = 35 // Base row height for table row (increased for better accuracy)
  const cellPadding = 12 // Padding in cells
  
  // Estimate height based on instructions (longest content)
  // In landscape, columns are narrower, so text wraps more
  const isLandscape = settings.value.orientation === 'landscape'
  const charsPerLine = isLandscape ? 50 : 70 // Fewer chars per line in landscape (narrower column)
  
  let instructionsHeight = 0
  if (viewMode.value === 'detailed' && item?.instructions) {
    // Estimate based on character count
    // Line height is 1.6, so actual height per line is ~19px
    const charCount = item.instructions.length
    const estimatedLines = Math.ceil(charCount / charsPerLine)
    instructionsHeight = Math.max(estimatedLines * 19, 45) // Minimum 45px for cell
  } else {
    instructionsHeight = 45 // Default cell height
  }
  
  // Theme can also wrap, estimate its height
  const themeCharsPerLine = isLandscape ? 35 : 50
  let themeHeight = 25
  if (item?.theme) {
    const themeLines = Math.ceil(item.theme.length / themeCharsPerLine)
    themeHeight = Math.max(themeLines * 19, 25)
  }
  
  // Return the maximum height needed (instructions column is usually tallest)
  return Math.max(baseRowHeight + instructionsHeight + cellPadding, baseRowHeight + themeHeight + cellPadding)
}

// Determine if we should show a page break before an item
const shouldShowPageBreak = (itemIndex: number): boolean => {
  if (itemIndex === 0) return false // Never show before first item
  if (availableContentHeight.value <= 0) return false // Safety check
  
  // Calculate cumulative height by summing actual heights of all previous items
  let cumulativeHeight = 0
  for (let i = 0; i < itemIndex; i++) {
    cumulativeHeight += calculateItemHeight(listItems.value[i])
  }
  
  // Calculate which page the previous items ended on
  const previousPage = Math.floor(cumulativeHeight / availableContentHeight.value)
  
  // Calculate which page this item will start on (add this item's height)
  const currentItemHeight = calculateItemHeight(listItems.value[itemIndex])
  const newCumulativeHeight = cumulativeHeight + currentItemHeight
  const currentPage = Math.floor(newCumulativeHeight / availableContentHeight.value)
  
  // Show page break if we've crossed a page boundary
  const shouldShow = currentPage > previousPage
  
  // Debug logging (can be removed later)
  if (shouldShow) {
    console.log('Page break at item', itemIndex, {
      cumulativeHeight,
      currentItemHeight,
      availableContentHeight: availableContentHeight.value,
      previousPage,
      currentPage,
      orientation: settings.value.orientation
    })
  }
  
  return shouldShow
}

const goBack = () => {
  router.back()
}

const editItem = (index: number) => {
  editingIndex.value = index
  currentItem.value = { ...listItems.value[index] }
  showAddDialog.value = true
}

const deleteItem = (index: number) => {
  listItems.value.splice(index, 1)
}

const saveItem = () => {
  if (!currentItem.value.theme.trim()) {
    $q.notify({
      type: 'negative',
      message: 'Theme is required',
      position: 'top'
    })
    return
  }

  if (editingIndex.value !== null) {
    listItems.value[editingIndex.value] = { ...currentItem.value }
    editingIndex.value = null
  } else {
    listItems.value.push({ ...currentItem.value })
  }

  currentItem.value = { 
    time: '',
    itemNumber: '',
    theme: '',
    speaker: '',
    type: '',
    duration: '',
    instructions: ''
  }
}

const handlePrint = () => {
  window.print()
}

const exportToPdf = async () => {
  pdfExporting.value = true
  try {
    // Get the HTML content of the print preview
    if (!previewContent.value) {
      throw new Error('Print preview element not found')
    }

    // Use the preview content element directly (it's already visible and rendered)
    const elementToCapture = previewContent.value

    // Configure html2pdf options
    const opt = {
      margin: [
        settings.value.margins.top,
        settings.value.margins.right,
        settings.value.margins.bottom,
        settings.value.margins.left
      ] as [number, number, number, number],
      filename: 'PrintList.pdf',
      image: { type: 'jpeg' as const, quality: 0.98 },
      html2canvas: { 
        scale: 2,
        useCORS: true,
        letterRendering: true,
        logging: false,
        backgroundColor: '#ffffff'
      },
      jsPDF: { 
        unit: 'mm', 
        format: settings.value.pageSize.toLowerCase(),
        orientation: (settings.value.orientation === 'landscape' ? 'landscape' : 'portrait') as 'portrait' | 'landscape'
      }
    }

    // Generate PDF using html2pdf.js
    // Use 'arraybuffer' output type for more reliable conversion
    const pdfArrayBuffer = await html2pdf().set(opt).from(elementToCapture).outputPdf('arraybuffer') as ArrayBuffer
    
    if (!pdfArrayBuffer || pdfArrayBuffer.byteLength === 0) {
      throw new Error('PDF generation returned empty result')
    }
    
    console.log('PDF generated, size:', pdfArrayBuffer.byteLength, 'bytes')
    
    // Convert ArrayBuffer to base64 using chunked approach for large arrays
    const uint8Array = new Uint8Array(pdfArrayBuffer)
    const chunkSize = 0x8000 // 32KB chunks
    let binaryString = ''
    
    for (let i = 0; i < uint8Array.length; i += chunkSize) {
      const chunk = uint8Array.subarray(i, i + chunkSize)
      binaryString += String.fromCharCode.apply(null, Array.from(chunk))
    }
    
    const pdfBase64 = btoa(binaryString)
    
    if (!pdfBase64 || pdfBase64.length === 0) {
      throw new Error('Failed to convert PDF to base64')
    }
    
    console.log('PDF converted to base64, length:', pdfBase64.length)

    // Call Rust command to write PDF bytes to file
    const filePath = await invoke<string>('generate_pdf_from_web_content', {
      pdfBase64: pdfBase64
    })

    $q.notify({
      type: 'positive',
      message: 'PDF exported successfully!',
      caption: `Saved to: ${filePath}`,
      position: 'top'
    })
  } catch (error) {
    console.error('PDF export failed:', error)
    $q.notify({
      type: 'negative',
      message: 'Failed to export PDF',
      caption: error instanceof Error ? error.message : String(error),
      position: 'top'
    })
  } finally {
    pdfExporting.value = false
  }
}

const exportToPdfOxidize = async () => {
  pdfExportingOxidize.value = true
  try {
    if (listItems.value.length === 0) {
      throw new Error('No items to export')
    }

    // Prepare list items data for Rust
    const itemsData = listItems.value.map(item => {
      const result: any = {
        theme: item.theme || ''
      }
      if (item.time) result.time = item.time
      if (item.itemNumber) result.item_number = item.itemNumber
      if (item.speaker) result.speaker = item.speaker
      if (item.type) result.type = item.type
      if (item.duration) result.duration = item.duration
      if (item.instructions) result.instructions = item.instructions
      return result
    })

    console.log('Sending list items to Rust for oxidize-pdf generation:', itemsData.length, 'items')
    console.log('Sample item:', JSON.stringify(itemsData[0]))

    // Call Rust command to generate PDF using oxidize-pdf
    const filePath = await invoke<string>('generate_pdf_oxidize', {
      request: {
        items: itemsData,
        settings: {
          pageSize: settings.value.pageSize,
          orientation: settings.value.orientation,
          margins: settings.value.margins,
          fontSize: settings.value.fontSize,
          viewMode: settings.value.viewMode
        }
      }
    })

    $q.notify({
      type: 'positive',
      message: 'PDF exported successfully using oxidize-pdf!',
      caption: `Saved to: ${filePath}`,
      position: 'top'
    })
  } catch (error) {
    console.error('Oxidize PDF export failed:', error)
    $q.notify({
      type: 'negative',
      message: 'Failed to export PDF using oxidize-pdf',
      caption: error instanceof Error ? error.message : String(error),
      position: 'top'
    })
  } finally {
    pdfExportingOxidize.value = false
  }
}

const resetSettings = () => {
  resetPrintSettings()
  $q.notify({
    type: 'info',
    message: 'Settings reset to defaults',
    position: 'top'
  })
}
</script>

