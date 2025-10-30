import { createRouter, createWebHistory } from 'vue-router'
import CalendarPage from '../pages/CalendarPage.vue'

const routes = [
  {
    path: '/',
    name: 'Calendar',
    component: CalendarPage
  },
  {
    path: '/congregations',
    name: 'Congregations',
    component: () => import('../pages/CongregationsPage.vue')
  },
  {
    path: '/reports',
    name: 'Reports',
    component: () => import('../pages/ReportsPage.vue')
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
