<template>
  <div id="repository-status-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5">
      {{ colName }}
    </div>
    <div v-if="status && icon" class="text-sn-dark-grey font-inter text-sm font-normal leading-5 ">
      <i class="text-lg">{{ icon }}</i>
      {{ status }}
    </div>
    <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ i18n.t('repositories.item_card.repository_status_value.no_status') }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'RepositoryStatusValue',
  data() {
    return {
      id: null,
      icon: null,
      status: null
    }
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object
  },
  created() {
    this.id = this.colVal.id
    this.icon = this.colVal.icon
    this.status = this.colVal.status
  }
}
</script>
