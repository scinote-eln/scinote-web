<template>
   <a class="hover:no-underline flex items-center gap-1 record-info-link"
     :title="params.data[0]"
     :href="params.data.recordInfoUrl"
  >
    <span class="truncate">
      {{ params.data[0] }}
    </span>
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
