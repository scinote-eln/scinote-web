<template>
  <i v-if="params.data.default" class="sn-icon sn-icon-approval"></i>
  <span v-else></span>
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
