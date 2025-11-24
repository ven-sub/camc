<template>
  <q-page class="q-pa-md">
    <!-- Header -->
    <div class="row items-center q-mb-lg">
      <div class="col">
        <div class="text-h4 q-mb-sm">Model CRUD</div>
        <div class="text-body1 text-grey-6">
          Create, edit, and delete model instances
        </div>
      </div>
      <div class="col-auto" v-if="selectedModel">
        <q-btn
          color="primary"
          icon="add"
          label="Create"
          @click="openCreateDialog"
        />
      </div>
    </div>

    <!-- Model Selector (if no model selected) -->
    <q-card v-if="!selectedModel" class="q-mb-md">
      <q-card-section>
        <div class="text-h6 q-mb-md">Select a Model</div>
        <div class="text-caption text-grey-7 q-mb-md">
          Choose a model to manage its data
        </div>
        <div v-if="loadingModels" class="text-center q-pa-lg">
          <q-spinner color="primary" size="3em" />
          <div class="q-mt-md text-grey-6">Loading models...</div>
        </div>
        <div v-else class="row q-gutter-md">
          <q-card
            v-for="model in availableModels"
            :key="model.name"
            class="col-12 col-sm-6 col-md-4 col-lg-3 cursor-pointer"
            @click="selectModel(model)"
            :class="{ 'bg-primary text-white': selectedModel?.name === model.name }"
          >
            <q-card-section>
              <div class="text-h6">{{ model.displayName }}</div>
              <div class="text-caption">{{ model.fieldCount }} fields</div>
            </q-card-section>
          </q-card>
        </div>
      </q-card-section>
    </q-card>

    <!-- Selected Model Data View -->
    <div v-if="selectedModel">
      <!-- Model Info Bar -->
      <q-banner class="bg-primary text-white q-mb-md">
        <template v-slot:avatar>
          <q-icon name="database" />
        </template>
        <div class="row items-center justify-between full-width">
          <div>
            <div class="text-h6">{{ selectedModel.displayName }}</div>
            <div class="text-caption">{{ modelData.data.length }} items</div>
          </div>
          <q-btn
            flat
            icon="close"
            label="Change Model"
            @click="changeModel"
          />
        </div>
      </q-banner>

      <!-- Search and Filter -->
      <q-card class="q-mb-md">
        <q-card-section>
          <q-input
            v-model="searchText"
            placeholder="Search..."
            outlined
            dense
            clearable
          >
            <template v-slot:prepend>
              <q-icon name="search" />
            </template>
          </q-input>
        </q-card-section>
      </q-card>

      <!-- Data Table -->
      <q-card>
        <q-card-section>
          <div v-if="modelData.loading.value" class="text-center q-pa-lg">
            <q-spinner color="primary" size="3em" />
            <div class="q-mt-md text-grey-6">Loading data...</div>
          </div>
          <div v-else-if="filteredData.length === 0" class="text-center q-pa-xl">
            <q-icon name="inbox" size="64px" color="grey-5" class="q-mb-md" />
            <div class="text-h6 text-grey-6 q-mb-md">No Data</div>
            <div class="text-body2 text-grey-7 q-mb-lg">
              {{ searchText ? 'No items match your search' : 'No items yet. Create your first item!' }}
            </div>
            <q-btn
              v-if="!searchText"
              color="primary"
              icon="add"
              label="Create First Item"
              @click="openCreateDialog"
            />
          </div>
          <q-table
            v-else
            :rows="filteredData"
            :columns="tableColumns"
            row-key="__index"
            :pagination="{ rowsPerPage: 20 }"
            :loading="modelData.loading.value"
            flat
            bordered
          >
            <template v-slot:body-cell-actions="props">
              <q-td :props="props">
                <q-btn
                  icon="edit"
                  color="primary"
                  flat
                  dense
                  round
                  @click="openEditDialog(props.row.__index)"
                />
                <q-btn
                  icon="delete"
                  color="negative"
                  flat
                  dense
                  round
                  @click="confirmDelete(props.row.__index)"
                />
              </q-td>
            </template>
          </q-table>
        </q-card-section>
      </q-card>
    </div>

    <!-- Create/Edit Dialog -->
    <q-dialog v-model="showFormDialog" persistent>
      <q-card style="min-width: 600px; max-width: 90vw">
        <q-card-section>
          <div class="text-h6">{{ editingIndex !== null ? 'Edit' : 'Create' }} {{ selectedModel?.displayName }}</div>
        </q-card-section>

        <q-card-section class="q-pt-none" style="max-height: 70vh; overflow-y: auto">
          <div v-if="!selectedModel || !formModel" class="text-center q-pa-lg">
            <q-spinner color="primary" size="3em" />
            <div class="q-mt-md text-grey-6">Loading form...</div>
          </div>
          <DynamicForm
            v-else
            :key="`form-${editingIndex ?? 'new'}`"
            :model="formModel"
            :template="selectedModel.template"
            @update:model="handleFormUpdate"
          />
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Cancel" color="primary" @click="closeFormDialog" />
          <q-btn
            flat
            label="Save"
            color="primary"
            @click="saveItem"
            :loading="modelData.loading.value"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- Delete Confirmation Dialog -->
    <q-dialog v-model="showDeleteDialog">
      <q-card>
        <q-card-section>
          <div class="text-h6">Delete Item?</div>
        </q-card-section>

        <q-card-section class="q-pt-none">
          Are you sure you want to delete this item? This action cannot be undone.
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Cancel" color="primary" v-close-popup />
          <q-btn
            flat
            label="Delete"
            color="negative"
            @click="deleteItem"
            :loading="modelData.loading.value"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useQuasar } from 'quasar'
import DynamicForm from '../components/DynamicForm.vue'
import { useModelData, type ModelDataItem } from '../composables/useModelData'

const $q = useQuasar()

interface ModelInfo {
  name: string
  displayName: string
  template: Record<string, any>
  fieldCount: number
}

const availableModels = ref<ModelInfo[]>([])
const selectedModel = ref<ModelInfo | null>(null)
const loadingModels = ref(false)
const searchText = ref('')
const showFormDialog = ref(false)
const showDeleteDialog = ref(false)
const editingIndex = ref<number | null>(null)
const formModel = ref<Record<string, any> | null>(null)
const deleteIndex = ref<number | null>(null)

const modelData = useModelData()

// Load all available models
async function loadModels() {
  loadingModels.value = true
  try {
    // Dynamically import all model files
    const modelModules = import.meta.glob('../models/*Object.js', { eager: true }) as Record<string, any>
    
    const models: ModelInfo[] = []
    
    for (const [path, module] of Object.entries(modelModules)) {
      // Extract model name from path: ../models/personObject.js -> personObject -> PersonObject
      const fileName = path.split('/').pop()?.replace('.js', '') || ''
      
      // Get the template object (should be exported as new{ModelName}Object)
      const templateKey = Object.keys(module).find(key => 
        key.startsWith('new') && key.includes('Object')
      )
      
      if (templateKey && module[templateKey]) {
        const template = module[templateKey]
        // Extract model name from export key: newPersonObject -> PersonObject
        const modelName = templateKey
          .replace(/^new/, '')
          .replace(/^./, (str) => str.toUpperCase())
        
        models.push({
          name: modelName,
          displayName: formatModelName(fileName),
          template,
          fieldCount: Object.keys(template).length
        })
      }
    }
    
    // Sort by display name
    models.sort((a, b) => a.displayName.localeCompare(b.displayName))
    availableModels.value = models
  } catch (error) {
    console.error('Failed to load models:', error)
    $q.notify({
      type: 'negative',
      message: 'Failed to load models',
      position: 'top'
    })
  } finally {
    loadingModels.value = false
  }
}

// Format model name for display: personObject -> Person Object
function formatModelName(fileName: string): string {
  return fileName
    .replace(/Object$/, '')
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, (str) => str.toUpperCase())
    .trim()
}

// Select a model
async function selectModel(model: ModelInfo) {
  selectedModel.value = model
  await modelData.loadModelData(model.name)
}

// Change model
function changeModel() {
  selectedModel.value = null
  modelData.reset()
  searchText.value = ''
}

// Generate table columns from model template
const tableColumns = computed(() => {
  if (!selectedModel.value) return []
  
  const columns: any[] = []
  
  // Add first few key fields as columns (limit to 5 for readability)
  const fields = Object.keys(selectedModel.value.template).slice(0, 5)
  
  fields.forEach((field) => {
    columns.push({
      name: field,
      label: formatFieldLabel(field),
      field: field,
      align: 'left',
      sortable: true
    })
  })
  
  // Add actions column
  columns.push({
    name: 'actions',
    label: 'Actions',
    field: 'actions',
    align: 'center',
    sortable: false
  })
  
  return columns
})

// Format field label: nameFirst -> Name First
function formatFieldLabel(field: string): string {
  return field
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, (str) => str.toUpperCase())
    .trim()
}

// Filtered data based on search
const filteredData = computed(() => {
  if (!searchText.value) {
    return modelData.data.value.map((item, index) => ({
      ...item,
      __index: index
    }))
  }
  
  const search = searchText.value.toLowerCase()
  return modelData.data.value
    .map((item, index) => ({
      ...item,
      __index: index
    }))
    .filter((item) => {
      // Search in all string/number fields
      return Object.values(item).some((value) => {
        if (typeof value === 'string' || typeof value === 'number') {
          return String(value).toLowerCase().includes(search)
        }
        return false
      })
    })
})

// Open create dialog
function openCreateDialog() {
  if (!selectedModel.value) return
  
  try {
    editingIndex.value = null
    // Create a deep copy of the template
    formModel.value = JSON.parse(JSON.stringify(selectedModel.value.template))
    showFormDialog.value = true
  } catch (error) {
    console.error('Failed to open create dialog:', error)
    $q.notify({
      type: 'negative',
      message: 'Failed to open form',
      caption: 'Error initializing form data',
      position: 'top'
    })
  }
}

// Open edit dialog
function openEditDialog(index: number) {
  if (!selectedModel.value) return
  editingIndex.value = index
  formModel.value = JSON.parse(JSON.stringify(modelData.data.value[index]))
  showFormDialog.value = true
}

// Close form dialog
function closeFormDialog() {
  showFormDialog.value = false
  editingIndex.value = null
  formModel.value = null
}

// Save item
async function saveItem() {
  if (!selectedModel.value || !formModel.value) return
  
  const success = editingIndex.value !== null
    ? await modelData.updateItem(selectedModel.value.name, editingIndex.value, formModel.value)
    : await modelData.createItem(selectedModel.value.name, formModel.value)
  
  if (success) {
    closeFormDialog()
  }
}

// Confirm delete
function confirmDelete(index: number) {
  deleteIndex.value = index
  showDeleteDialog.value = true
}

// Delete item
async function deleteItem() {
  if (!selectedModel.value || deleteIndex.value === null) return
  
  const success = await modelData.deleteItem(selectedModel.value.name, deleteIndex.value)
  if (success) {
    showDeleteDialog.value = false
    deleteIndex.value = null
  }
}

// Handle form update
function handleFormUpdate(val: Record<string, any>) {
  formModel.value = val
}

// Load models on mount
onMounted(() => {
  loadModels()
})
</script>

<style scoped>
.cursor-pointer {
  cursor: pointer;
  transition: transform 0.2s;
}

.cursor-pointer:hover {
  transform: translateY(-2px);
}
</style>

