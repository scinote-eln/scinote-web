<template>
  <div id="repository-stock-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 relative">
      <span>{{ colName }}</span>
      <a style="text-decoration: none;" class="absolute right-0 text-sn-science-blue visited:text-sn-science-blue hover:text-sn-science-blue
               font-inter text-sm font-normal cursor-pointer export-consumption-button"
        v-if="permissions?.can_export_repository_stock === true" :data-rows="JSON.stringify([repositoryRowId])"
        :data-object-id="repositoryId">
        {{ i18n.t('repositories.item_card.stock_export') }}
      </a>
    </div>
    <div v-if="colVal?.stock_formatted" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ colVal?.stock_formatted }}
    </div>
    <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ i18n.t('repositories.item_card.repository_stock_value.no_stock') }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'RepositoryStockValue',
  data() {
    return {
      stock_formatted: null,
      stock_amount: null,
      low_stock_threshold: null
    }
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object,
    repositoryId: Number,
    repositoryRowId: null,
    permissions: null
  },
  created() {
    this.stock_formatted = this?.colVal?.stock_formatted
    this.stock_amount = this?.colVal?.stock_amount
    this.low_stock_threshold = this?.colVal?.low_stock_threshold
  }
}
</script>
