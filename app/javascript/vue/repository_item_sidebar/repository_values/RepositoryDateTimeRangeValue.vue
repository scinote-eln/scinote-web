<template>
  <div id="repository-date-time-range-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5">
      {{ colName }}
    </div>
    <div v-if="start_time?.formatted && end_time?.formatted"
      class="text-sn-dark-grey font-inter text-sm font-normal leading-5 flex">
      <div>{{ start_time?.formatted }} - {{ end_time.formatted }}</div>
    </div>
    <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ i18n.t('repositories.item_card.repository_date_time_range_value.no_date_time_range') }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'RepositoryDateTimeRangeValue',
  data() {
    return {
      start_time: null,
      end_time: null
    }
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object
  },
  created() {
    this.start_time = this.colVal.start_time
    this.end_time = this.colVal.end_time
  }
}
</script>
