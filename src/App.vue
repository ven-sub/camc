<template>
  <q-layout view="lHh Lpr lFf">
    <!-- Desktop Header -->
    <q-header elevated v-if="$q.screen.gt.sm">
      <q-toolbar>
        <q-btn
          flat
          dense
          icon="menu"
          @click="leftDrawerOpen = !leftDrawerOpen"
          aria-label="Menu"
        />
        <q-toolbar-title>
          Circuit Assistant Mobile Companion
        </q-toolbar-title>
        <q-space />
        <q-btn
          flat
          round
          dense
          icon="storage"
          @click="testDatabaseConnection"
          class="q-mr-sm"
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
      </q-toolbar>
    </q-header>

    <!-- Mobile Header -->
    <q-header elevated v-if="$q.screen.lt.md">
      <q-toolbar>
        <q-toolbar-title>
          Circuit Assistant
        </q-toolbar-title>
        <q-space />
        <q-btn
          flat
          round
          dense
          icon="storage"
          @click="testDatabaseConnection"
          class="q-mr-sm"
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
      </q-toolbar>
    </q-header>

    <!-- Navigation Drawer -->
    <NavigationDrawer />

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { Dark, useQuasar } from 'quasar'
import { invoke } from '@tauri-apps/api/core'
import NavigationDrawer from './components/NavigationDrawer.vue'

const $q = useQuasar()
const leftDrawerOpen = ref(true)

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
      position: 'top'
    })
  }
}
</script>
