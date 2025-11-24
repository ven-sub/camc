<template>
  <div class="dynamic-form">
    <div v-for="(field, key) in formFields" :key="key" class="q-mb-md">
      <!-- String field -->
      <q-input
        v-if="field.type === 'string'"
        v-model="formData[key]"
        :label="field.label"
        outlined
        dense
        :hint="field.hint"
      />

      <!-- Number field -->
      <q-input
        v-else-if="field.type === 'number'"
        v-model.number="formData[key]"
        type="number"
        :label="field.label"
        outlined
        dense
        :hint="field.hint"
      />

      <!-- Boolean field -->
      <q-toggle
        v-else-if="field.type === 'boolean'"
        v-model="formData[key]"
        :label="field.label"
      />

      <!-- Nullable field (text input) -->
      <q-input
        v-else-if="field.type === 'null'"
        v-model="formData[key]"
        :label="field.label"
        outlined
        dense
        :hint="field.hint || 'Optional'"
        clearable
      />

      <!-- Array field -->
      <q-expansion-item
        v-else-if="field.type === 'array'"
        :label="field.label"
        icon="list"
        class="q-mb-sm"
      >
        <div class="q-pa-md">
          <div
            v-for="(item, index) in (formData[key] as any[])"
            :key="index"
            class="row items-center q-mb-sm q-gutter-sm"
          >
            <div class="col">
              <q-input
                v-if="field.arrayType === 'string'"
                v-model="formData[key][index]"
                :label="`${field.label} Item ${index + 1}`"
                outlined
                dense
              />
              <q-input
                v-else-if="field.arrayType === 'number'"
                v-model.number="formData[key][index]"
                type="number"
                :label="`${field.label} Item ${index + 1}`"
                outlined
                dense
              />
              <div v-else-if="field.arrayType === 'object'" class="q-pa-sm bg-grey-2 rounded-borders">
                <DynamicForm
                  :model="formData[key][index]"
                  :template="field.arrayTemplate"
                  @update:model="(val) => { formData[key][index] = val }"
                />
              </div>
            </div>
            <q-btn
              icon="delete"
              color="negative"
              flat
              dense
              round
              @click="removeArrayItem(key, index)"
            />
          </div>
          <q-btn
            icon="add"
            color="primary"
            flat
            dense
            :label="`Add ${field.label} Item`"
            @click="addArrayItem(key, field.arrayType, field.arrayTemplate)"
          />
        </div>
      </q-expansion-item>

      <!-- Nested object field -->
      <q-expansion-item
        v-else-if="field.type === 'object'"
        :label="field.label"
        icon="folder"
        class="q-mb-sm"
      >
        <div class="q-pa-md">
          <DynamicForm
            :model="formData[key]"
            :template="field.objectTemplate"
            @update:model="(val) => { formData[key] = val }"
          />
        </div>
      </q-expansion-item>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, computed, onMounted, nextTick } from 'vue'

interface FormField {
  type: 'string' | 'number' | 'boolean' | 'null' | 'array' | 'object'
  label: string
  hint?: string
  arrayType?: 'string' | 'number' | 'object'
  arrayTemplate?: any
  objectTemplate?: any
}

interface Props {
  model: Record<string, any>
  template: Record<string, any>
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:model': [value: Record<string, any>]
}>()

const formData = ref<Record<string, any>>({})

// Convert camelCase to Title Case
function camelToTitle(str: string): string {
  return str
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, (str) => str.toUpperCase())
    .trim()
}

// Infer field type from value
function inferFieldType(value: any): FormField['type'] {
  if (value === null) return 'null'
  if (Array.isArray(value)) return 'array'
  if (typeof value === 'object') return 'object'
  return typeof value as 'string' | 'number' | 'boolean'
}

// Get array item type
function getArrayType(arr: any[]): 'string' | 'number' | 'object' {
  if (arr.length === 0) return 'string' // Default to string for empty arrays
  const firstItem = arr[0]
  if (typeof firstItem === 'string') return 'string'
  if (typeof firstItem === 'number') return 'number'
  if (typeof firstItem === 'object' && firstItem !== null) return 'object'
  return 'string'
}

// Generate form fields from template
const formFields = computed<Record<string, FormField>>(() => {
  const fields: Record<string, FormField> = {}

  for (const [key, defaultValue] of Object.entries(props.template)) {
    const type = inferFieldType(defaultValue)
    const label = camelToTitle(key)

    const field: FormField = {
      type,
      label
    }

    if (type === 'array') {
      const arr = defaultValue as any[]
      field.arrayType = getArrayType(arr)
      if (field.arrayType === 'object' && arr.length > 0) {
        field.arrayTemplate = arr[0]
      }
    } else if (type === 'object') {
      field.objectTemplate = defaultValue
    }

    if (type === 'null') {
      field.hint = 'Optional'
    }

    fields[key] = field
  }

  return fields
})

// Track if we're currently initializing to prevent emit loops
const isInitializing = ref(false)
const lastModelRef = ref<any>(null)

// Initialize form data from model
function initializeFormData() {
  isInitializing.value = true
  
  try {
    // Start with template defaults
    const templateCopy = JSON.parse(JSON.stringify(props.template))
    
    // Override with model values if provided
    if (props.model && Object.keys(props.model).length > 0) {
      for (const key in props.model) {
        if (key in templateCopy) {
          templateCopy[key] = props.model[key]
        }
      }
    }
    
    formData.value = templateCopy
    lastModelRef.value = props.model
  } finally {
    // Reset flag after Vue has processed the update
    nextTick(() => {
      isInitializing.value = false
    })
  }
}

// Initialize on mount
onMounted(() => {
  initializeFormData()
})

// Watch for model reference changes (not deep changes to avoid loops)
watch(() => props.model, (newModel) => {
  // Only re-initialize if the model reference actually changed
  if (newModel !== lastModelRef.value && !isInitializing.value) {
    initializeFormData()
  }
}, { deep: false })

// Watch formData and emit updates (but not during initialization)
watch(formData, (newVal) => {
  if (!isInitializing.value) {
    emit('update:model', JSON.parse(JSON.stringify(newVal)))
  }
}, { deep: true })

// Array manipulation
function addArrayItem(key: string, arrayType: string, template?: any) {
  if (!Array.isArray(formData.value[key])) {
    formData.value[key] = []
  }

  let newItem: any
  if (arrayType === 'string') {
    newItem = ''
  } else if (arrayType === 'number') {
    newItem = 0
  } else if (arrayType === 'object' && template) {
    newItem = JSON.parse(JSON.stringify(template))
  } else {
    newItem = null
  }

  formData.value[key].push(newItem)
}

function removeArrayItem(key: string, index: number) {
  if (Array.isArray(formData.value[key])) {
    formData.value[key].splice(index, 1)
  }
}
</script>

<style scoped>
.dynamic-form {
  width: 100%;
}
</style>

