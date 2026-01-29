<template>
  <span :class="color">{{params.value}}</span>
</template>

<script>
export default {
  props: {
    params: {
      type: Object,
      required: true
    }
  },
  computed: {
    color() {
      const { import_status: importStatus } = this.params.data;

      if (importStatus === 'created' || importStatus === 'updated') {
        return 'text-sn-alert-green';
      } else if (importStatus === 'duplicated' || importStatus === 'invalid') {
        return 'text-sn-alert-passion';
      }
    }
  }
}
</script>
