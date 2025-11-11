import { ref } from 'vue'
import { useQuasar } from 'quasar'
import { invoke } from '@tauri-apps/api/core'
import { getErrorMessage } from '../utils/errors'

interface ExportOptions {
  commandName: string
  successMessage: string
  mobileCaption?: string
  desktopCaption?: string
}

/**
 * Composable for handling file export operations
 * Provides a consistent pattern for exporting files with loading states and notifications
 */
export function useFileExport(options: ExportOptions) {
  const $q = useQuasar()
  const loading = ref(false)
  const filePath = ref('')

  const execute = async (isMobile: boolean) => {
    loading.value = true
    filePath.value = ''

    try {
      const path = await invoke<string>(options.commandName)
      filePath.value = path

      $q.notify({
        type: 'positive',
        message: options.successMessage,
        caption: isMobile 
          ? options.mobileCaption 
          : options.desktopCaption,
        position: 'top'
      })
    } catch (error) {
      console.error(`${options.commandName} failed:`, error)
      $q.notify({
        type: 'negative',
        message: `Failed to ${options.commandName.replace(/_/g, ' ')}`,
        caption: getErrorMessage(error),
        position: 'top'
      })
    } finally {
      loading.value = false
    }
  }

  return {
    loading,
    filePath,
    execute
  }
}

