<template>
  <div>
    <!-- Desktop: Left Sidebar Navigation -->
    <q-drawer
      v-model="leftDrawerOpen"
      :width="280"
      :breakpoint="1024"
      bordered
      class="bg-grey-1"
      v-if="$q.screen.gt.sm"
    >
      <q-scroll-area class="fit">
        <div class="q-pa-md">
          <div class="text-h6 text-primary q-mb-md">
            <q-icon name="settings_input_component" class="q-mr-sm" />
            Circuit Assistant
          </div>
          
          <q-list>
            <q-item
              v-for="item in menuItems"
              :key="item.name"
              clickable
              v-ripple
              :active="currentRoute === item.route"
              active-class="bg-primary text-white"
              @click="navigateTo(item.route)"
              class="q-mb-xs"
            >
              <q-item-section avatar>
                <q-icon :name="item.icon" />
              </q-item-section>
              <q-item-section>
                <q-item-label>{{ item.label }}</q-item-label>
              </q-item-section>
            </q-item>
          </q-list>
        </div>
      </q-scroll-area>
    </q-drawer>

    <!-- Mobile/Tablet: Bottom Tab Navigation -->
    <q-footer
      v-if="$q.screen.lt.md"
      class="bg-white text-primary"
      bordered
    >
      <q-tabs
        v-model="activeTab"
        class="text-grey-7"
        active-color="primary"
        indicator-color="primary"
        align="justify"
        narrow-indicator
      >
        <q-tab
          v-for="item in menuItems"
          :key="item.name"
          :name="item.name"
          :icon="item.icon"
          :label="item.label"
          @click="navigateTo(item.route)"
        />
      </q-tabs>
    </q-footer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()

const leftDrawerOpen = ref(true)

const menuItems = [
  {
    name: 'calendar',
    label: 'Calendar',
    icon: 'event',
    route: '/'
  },
  {
    name: 'prototypes',
    label: 'Prototypes',
    icon: 'science',
    route: '/prototypes'
  },
  {
    name: 'settings',
    label: 'Settings',
    icon: 'settings',
    route: '/settings'
  }
]

const currentRoute = computed(() => route.path)
const activeTab = computed({
  get: () => {
    const currentItem = menuItems.find(item => item.route === route.path)
    return currentItem?.name || 'calendar'
  },
  set: (value) => {
    const item = menuItems.find(item => item.name === value)
    if (item) {
      navigateTo(item.route)
    }
  }
})

const navigateTo = (route: string) => {
  router.push(route)
}
</script>
