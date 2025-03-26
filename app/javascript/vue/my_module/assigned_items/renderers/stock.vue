<template>
  <div class="flex items-center gap-1">
    <i v-if="params.data.stock.stock_status && params.data.stock.stock_status !== 'normal'"
       :class="{
         'text-sn-alert-passion': params.data.stock.stock_status === 'empty',
         'text-sn-alert-brittlebush': params.data.stock.stock_status === 'low'
       }"
       class="sn-icon sn-icon-alert-warning shrink-0"></i>
    <span v-if="params.data.stock.value" class="truncate">
      {{ params.data.stock.value.stock_formatted }}
    </span>
    <span v-else class="text-sn-grey-500">{{ i18n.t('libraries.manange_modal_column.stock_type.no_item_stock') }}</span>
  </div>
</template>

<script>
export default {
  props: {
    params: {
      type: Object,
      required: true
    }
  }
};
</script>
