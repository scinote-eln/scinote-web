<template>
  <div v-if="params.value">
    {{ params.value.value.file_name }}
  </div>
</template>

<script>
export default {
  name: 'AssetValue',
  props: {
    params: {
      required: true
    }
  }
};
</script>
