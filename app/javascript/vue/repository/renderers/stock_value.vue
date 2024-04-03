<template>
  <div v-if="params.value">
    {{ params.value.value?.stock_formatted }}
  </div>
</template>

<script>
export default {
  name: 'StockValue',
  props: {
    params: {
      required: true
    }
  }
};
</script>
