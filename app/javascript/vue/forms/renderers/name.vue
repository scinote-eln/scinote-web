<template>
  <a v-if="params.data.urls.show"
      :href="params.data.urls.show"
      :title="params.data.name">
    {{ params.data.name }}
  </a>
  <span v-else class="text-sn-grey" :title="params.data.name">
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
