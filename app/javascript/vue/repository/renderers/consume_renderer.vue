<template>
  <div v-if="data" class="flex items-center gap-1">
    <span v-if="!data.stock_present && data.value && data.value.consumed_stock !== null">
      {{ data.value.consumed_stock_formatted }}
    </span>
    <span v-else-if="!data.stock_present"> - </span>
    <span v-else-if="!data.consumption_permitted && data.value && !data.value.consumed_stock" class="text-sn-grey-500">
      {{ i18n.t('libraries.manange_modal_column.stock_type.stock_consumption_locked') }}
    </span>
    <span v-else-if="!data.consumption_permitted">
      {{ data.value.consumed_stock_formatted }}
    </span>
    <span v-else-if="!data.value.consumed_stock"
          class="text-sn-grey-700 cursor-pointer"
          @click="params.dtComponent.$emit('openConsumeModal', this.params.data)"
    >
      <i class="sn-icon sn-icon-test-tube"></i>
      {{ i18n.t('libraries.manange_modal_column.stock_type.add_stock_consumption') }}
    </span>
    <span v-else class="cursor-pointer text-sn-blue" @click="params.dtComponent.$emit('openConsumeModal', this.params.data)">
      {{ data.value.consumed_stock_formatted }}
    </span>
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
    data() {
      return this.params.data.consumed_stock;
    }
  }
};
</script>
