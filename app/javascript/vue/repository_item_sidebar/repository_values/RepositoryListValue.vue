<template>
  <div id="repository-list-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 truncate" :title="colName">
      {{ colName }}
    </div>
    <div v-if="text" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ text }}
    </div>
    <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ i18n.t('repositories.item_card.repository_list_value.no_list') }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'RepositoryListValue',
  data() {
    return {
      id: null,
      text: null
    }
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object
  },
  created() {
    if (!this.colVal) return

    this.id = this.colVal.id
    this.text = this.colVal.text
  }
}
</script>
