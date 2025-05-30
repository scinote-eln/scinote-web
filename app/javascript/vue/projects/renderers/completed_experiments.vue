<template>
  <CounterRenderer
    v-if="!params.data.folder"
    :params="params"
    totalField="total_experiments"
    completedField="completed_experiments"
    label="projects.index.card.completed_experiments"
  />
</template>

<script>
import CounterRenderer from '../../shared/datatable/renderers/counter.vue';

export default {
  name: 'CompletedExperimentsRenderer',
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
