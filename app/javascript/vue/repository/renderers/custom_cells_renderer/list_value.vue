<template>
  <div v-if="params.value">
    {{ this.params.value.value.text }}
  </div>
</template>

<script>
export default {
  name: 'ListValue',
  props: {
    params: {
      required: true
    }
  }
};
</script>
