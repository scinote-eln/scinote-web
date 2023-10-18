<template>
  <div id="repository-date-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 truncate">
      {{ colName }}
    </div>
    <div v-if="formatted" class="text-sn-dark-grey font-inter text-sm font-normal leading-5 flex">
      <div>{{ formatted }}</div>
    </div>
    <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ i18n.t('repositories.item_card.repository_date_value.no_date') }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'RepositoryDateValue',
  data() {
    return {
      formatted: null,
      datetime: null
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

    this.formatted = this.colVal.formatted
    this.datetime = this.colVal.datetime
  }
}
</script>
