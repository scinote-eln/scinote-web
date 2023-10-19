<template>
  <div id="repository-checklist-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5">
      {{ colName }}
    </div>
    <div v-if="checklistItems.length > 0">
      <div v-if="isEditing"
        class="text-sn-dark-grey font-inter text-sm font-normal leading-5 grid grid-rows-2 grid-cols-2 overflow-auto h-12">
        <div v-for="(checklistItem, index) in checklistItems" :key="index">
          <div class="sci-checkbox-container">
            <input type="checkbox" class="sci-checkbox" :value="checklistItem?.value" v-model="selectedChecklistItems" />
            <span class="sci-checkbox-label"></span>
          </div>
          {{ checklistItem?.label }}
        </div>
      </div>
      <div v-else
        class="text-sn-dark-grey font-inter text-sm font-normal leading-5 w-[370px] overflow-x-auto flex flex-wrap gap-1">
        <span v-for="(checklistItem, index) in checklistItems" :key="index" :id="`checklist-item-${index}`" class="flex w-fit break-words mr-1">
          {{ index + 1 === checklistItems.length ? checklistItem?.label : `${checklistItem?.label} |` }}
        </span>
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
      checklistItems: [],
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
    if (!this.colVal) return

    this.checklistItems = this.colVal
  }
}
</script>
