import { createRouter, createWebHistory } from 'vue-router'
import CalendarPage from '../pages/CalendarPage.vue'

const routes = [
  {
    path: '/',
    name: 'Calendar',
    component: CalendarPage
  },
  {
    path: '/prototypes',
    name: 'Prototypes',
    component: () => import('../pages/PrototypesPage.vue')
  },
  {
    path: '/settings',
    name: 'Settings',
    component: () => import('../pages/SettingsPage.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
