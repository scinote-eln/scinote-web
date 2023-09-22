<template>
  <div id="repository-checklist-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5">
      {{ colName }}
    </div>
    <div v-if="allChecklistItems">
      <div v-if="isEditing"
        class="text-sn-dark-grey font-inter text-sm font-normal leading-5 grid grid-rows-2 grid-cols-2 overflow-auto h-12">
        <div v-for="(checklistItem, index) in allChecklistItems" :key="index">
          <div class="sci-checkbox-container">
            <input type="checkbox" class="sci-checkbox" :value="checklistItem.value" v-model="selectedChecklistItems" />
            <span class="sci-checkbox-label"></span>
          </div>
          {{ checklistItem.label }}
        </div>
      </div>
      <div v-else
        class="text-sn-dark-grey font-inter text-sm font-normal leading-5 h-fit overflow-auto grid auto-rows-auto grid-cols-3">
        <div v-for="(checklistItem, index) in allChecklistItems" :key="index">
          <div id="checklist-item" class="min-w-max">
            {{ `${checklistItem.label} |` }}
          </div>
        </div>
      </div>
    </div>
    <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ i18n.t('repositories.item_card.repository_checklist_value.no_checklist') }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'RepositoryChecklistValue',
  data() {
    return {
      isEditing: false,
      id: null,
      allChecklistItems: [],
      selectedChecklistItems: []
    }
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Array
  },
  created() {
    this.allChecklistItems = this.colVal
  }
}
</script>
