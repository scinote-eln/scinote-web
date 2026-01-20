<template>
  <div v-if="params.value">
    {{ params.value.value }}
  </div>
</template>

<script>
export default {
  name: 'NumberValue',
  props: {
    params: {
      required: true
    }
  }
};
</script>
