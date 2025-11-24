import { ref, computed } from 'vue'

export interface Margins {
  top: number
  bottom: number
  left: number
  right: number
}

export interface PrintSettings {
  pageSize: string // "Letter", "A4", "Legal"
  orientation: 'portrait' | 'landscape'
  margins: Margins
  fontSize: number
  viewMode: 'basic' | 'detailed'
}

const defaultSettings: PrintSettings = {
  pageSize: 'Letter',
  orientation: 'portrait',
  margins: {
    top: 20,
    bottom: 20,
    left: 20,
    right: 20
  },
  fontSize: 12,
  viewMode: 'basic'
}

export function usePrintSettings() {
  const settings = ref<PrintSettings>({ ...defaultSettings })

  // Computed CSS variables for print preview
  const printStyles = computed(() => {
    const pageSizes = {
      Letter: { width: '8.5in', height: '11in' },
      A4: { width: '210mm', height: '297mm' },
      Legal: { width: '8.5in', height: '14in' }
    }

    const size = pageSizes[settings.value.pageSize as keyof typeof pageSizes] || pageSizes.Letter
    
    // Swap dimensions for landscape
    const pageWidth = settings.value.orientation === 'landscape' ? size.height : size.width
    const pageHeight = settings.value.orientation === 'landscape' ? size.width : size.height
    
    console.log('Print styles updated:', {
      orientation: settings.value.orientation,
      pageSize: settings.value.pageSize,
      pageWidth,
      pageHeight
    })
    
    return {
      '--page-width': pageWidth,
      '--page-height': pageHeight,
      '--margin-top': `${settings.value.margins.top}mm`,
      '--margin-bottom': `${settings.value.margins.bottom}mm`,
      '--margin-left': `${settings.value.margins.left}mm`,
      '--margin-right': `${settings.value.margins.right}mm`,
      '--font-size': `${settings.value.fontSize}pt`
    }
  })

  const updateSettings = (updates: Partial<PrintSettings>) => {
    settings.value = { ...settings.value, ...updates }
  }

  const resetSettings = () => {
    settings.value = { ...defaultSettings }
  }

  return {
    settings,
    printStyles,
    updateSettings,
    resetSettings
  }
}

