<template>
  <div v-if="params.data.stock">
    <div v-if="canManage" class="relative">
      <span class="cursor-pointer text-sn-blue" @click="openStockModal">
        <span v-if="params.data.stock.value.stock_formatted" class="truncate">
          {{ params.data.stock.value.stock_formatted }}
        </span>
        <span v-else>{{ i18n.t('libraries.manange_modal_column.stock_type.add_stock') }}</span>
      </span>
    </div>
    <div v-else class="flex items-center gap-1">
      <i v-if="params.data.stock.stock_status && params.data.stock.stock_status !== 'normal'"
        :class="{
          'text-sn-alert-passion': params.data.stock.stock_status === 'empty',
          'text-sn-alert-brittlebush': params.data.stock.stock_status === 'low'
        }"
        class="sn-icon sn-icon-alert-warning shrink-0"></i>
      <span v-if="params.data.stock.value.stock_formatted" class="truncate">
        {{ params.data.stock.value.stock_formatted }}
      </span>
      <span v-else class="text-sn-grey-500">{{ i18n.t('libraries.manange_modal_column.stock_type.no_item_stock') }}</span>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    params: {
      type: Object,
      required: true
    }
  },
  computed: {
    canManage() {
      return this.params?.data?.permissions?.manage || false;
    }
  },
  methods: {
    openStockModal() {
      this.params.dtComponent.$emit('openStockModal', this.params.data);
    }
  }
};
</script>
