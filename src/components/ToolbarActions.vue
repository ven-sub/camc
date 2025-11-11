<template>
  <div class="row items-center q-gutter-xs">
    <q-btn
      flat
      round
      dense
      icon="storage"
      @click="testDatabaseConnection"
    >
      <q-tooltip>Test Database Connection</q-tooltip>
    </q-btn>
    <q-btn
      flat
      round
      dense
      icon="dark_mode"
      @click="toggleDarkMode"
    />
  </div>
</template>

<script setup lang="ts">
import { Dark, useQuasar } from 'quasar'
import { invoke } from '@tauri-apps/api/core'
import { getErrorMessage } from '../utils/errors'

const $q = useQuasar()

const toggleDarkMode = () => {
  Dark.toggle()
}

const testDatabaseConnection = async () => {
  try {
    const result = await invoke<string>('test_db_connection')
    $q.notify({
      type: 'positive',
      message: result,
      position: 'top'
    })
  } catch (error) {
    console.error('Database connection test failed:', error)
    $q.notify({
      type: 'negative',
      message: 'Database connection failed',
      caption: getErrorMessage(error),
      position: 'top'
    })
  }
}
</script>

