import { ref } from 'vue'
import { useQuasar } from 'quasar'
import { invoke } from '@tauri-apps/api/core'
import { getErrorMessage } from '../utils/errors'
import type { Ref } from 'vue'

export interface ModelDataItem {
  [key: string]: any
}

/**
 * Composable for handling model data CRUD operations
 * Provides functions to load, create, update, and delete model instances
 */
export function useModelData() {
  const $q = useQuasar()
  const loading = ref(false)
  const data = ref<ModelDataItem[]>([])

  /**
   * Load all instances of a model from the data file
   */
  const loadModelData = async (modelName: string): Promise<void> => {
    loading.value = true
    try {
      const result = await invoke<ModelDataItem[]>('read_model_data', {
        modelName
      })
      data.value = result
    } catch (error) {
      console.error('Failed to load model data:', error)
      $q.notify({
        type: 'negative',
        message: 'Failed to load data',
        caption: getErrorMessage(error),
        position: 'top'
      })
      data.value = []
    } finally {
      loading.value = false
    }
  }

  /**
   * Create a new instance and add it to the data array
   */
  const createItem = async (modelName: string, item: ModelDataItem): Promise<boolean> => {
    loading.value = true
    try {
      const newData = [...data.value, item]
      await invoke<string>('write_model_data', {
        modelName,
        data: newData
      })
      data.value = newData
      $q.notify({
        type: 'positive',
        message: 'Item created successfully',
        position: 'top'
      })
      return true
    } catch (error) {
      console.error('Failed to create item:', error)
      $q.notify({
        type: 'negative',
        message: 'Failed to create item',
        caption: getErrorMessage(error),
        position: 'top'
      })
      return false
    } finally {
      loading.value = false
    }
  }

  /**
   * Update an existing instance at the given index
   */
  const updateItem = async (modelName: string, index: number, item: ModelDataItem): Promise<boolean> => {
    loading.value = true
    try {
      if (index < 0 || index >= data.value.length) {
        throw new Error('Invalid index')
      }
      const newData = [...data.value]
      newData[index] = item
      await invoke<string>('write_model_data', {
        modelName,
        data: newData
      })
      data.value = newData
      $q.notify({
        type: 'positive',
        message: 'Item updated successfully',
        position: 'top'
      })
      return true
    } catch (error) {
      console.error('Failed to update item:', error)
      $q.notify({
        type: 'negative',
        message: 'Failed to update item',
        caption: getErrorMessage(error),
        position: 'top'
      })
      return false
    } finally {
      loading.value = false
    }
  }

  /**
   * Delete an instance at the given index
   */
  const deleteItem = async (modelName: string, index: number): Promise<boolean> => {
    loading.value = true
    try {
      if (index < 0 || index >= data.value.length) {
        throw new Error('Invalid index')
      }
      const newData = data.value.filter((_, i) => i !== index)
      await invoke<string>('write_model_data', {
        modelName,
        data: newData
      })
      data.value = newData
      $q.notify({
        type: 'positive',
        message: 'Item deleted successfully',
        position: 'top'
      })
      return true
    } catch (error) {
      console.error('Failed to delete item:', error)
      $q.notify({
        type: 'negative',
        message: 'Failed to delete item',
        caption: getErrorMessage(error),
        position: 'top'
      })
      return false
    } finally {
      loading.value = false
    }
  }

  /**
   * Reset the data array
   */
  const reset = () => {
    data.value = []
  }

  return {
    loading: loading as Ref<boolean>,
    data: data as Ref<ModelDataItem[]>,
    loadModelData,
    createItem,
    updateItem,
    deleteItem,
    reset
  }
}



