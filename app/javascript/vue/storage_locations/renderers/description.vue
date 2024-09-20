<template>
  <div v-html="params.data.sa_description"></div>
</template>

<script>
export default {
  name: 'DescriptionRenderer',
  props: {
    params: {
      type: Object,
      required: true
    }
  }
};
</script>
