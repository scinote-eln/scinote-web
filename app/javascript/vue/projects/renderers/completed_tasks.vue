<template>
  <CounterRenderer
    v-if="!params.data.folder"
    :params="params"
    totalField="total_tasks"
    completedField="completed_tasks"
    label="experiments.card.completed_value"
  />
</template>

<script>
import CounterRenderer from '../../shared/datatable/renderers/counter.vue';

export default {
  name: 'CompletedTasksRenderer',
  props: {
    params: {
      required: true
    }
  },
  components: {
    CounterRenderer
  }
};
</script>
