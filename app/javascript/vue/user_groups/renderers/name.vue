<template>
  <a :href="params.data.urls.show" :title="params.data.name">
    {{ params.data.name }}
  </a>
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
