<template>
  <div>
    <div v-if="isRange" class="flex items-center gap-1">
      {{ params.value.value.start_time.formatted }}
      <span> - </span>
      {{ params.value.value.end_time.formatted }}
    </div>
    <div v-else>
      {{ params.value.value.formatted }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'DateTimeShared',
  props: {
    params: {
      required: true
    }
  },
  computed: {
    isRange() {
      return this.params.value.value_type.includes('Range');
    }
  }
};
</script>
