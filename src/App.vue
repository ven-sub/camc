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
        <ToolbarActions />
      </q-toolbar>
    </q-header>

    <!-- Mobile Header -->
    <q-header elevated v-if="$q.screen.lt.md">
      <q-toolbar>
        <q-toolbar-title>
          Circuit Assistant
        </q-toolbar-title>
        <ToolbarActions />
      </q-toolbar>
    </q-header>

    <!-- Navigation Drawer -->
    <NavigationDrawer v-model="leftDrawerOpen" />

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import NavigationDrawer from './components/NavigationDrawer.vue'
import ToolbarActions from './components/ToolbarActions.vue'

const leftDrawerOpen = ref(true)
</script>
