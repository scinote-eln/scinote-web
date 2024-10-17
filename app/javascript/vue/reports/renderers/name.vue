<template>
  <span :title="params.data.name">
    {{ params.data.name }}
  </span>
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
