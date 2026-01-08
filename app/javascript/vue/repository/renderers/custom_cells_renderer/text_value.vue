<template>
  <div v-if="params.value">
    {{ this.params.value.value.view }}
  </div>
</template>

<script>
export default {
  name: 'TextValue',
  props: {
    params: {
      required: true
    }
  }
};
</script>
