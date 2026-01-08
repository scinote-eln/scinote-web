<template>
  <div v-if="params.value">
    <DateTimeShared :params="params" />
  </div>
</template>

<script>
import DateTimeShared from './shared/date_time.vue';
export default {
  name: 'DateRangeValue',
  props: {
    params: {
      required: true
    }
  },
  components: {
    DateTimeShared
  }
};
</script>
