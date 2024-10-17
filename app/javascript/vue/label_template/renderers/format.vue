<template>
  <span>
    <span v-html="params.data.icon_url"></span>
    <span>{{ params.data.format }}</span>
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
