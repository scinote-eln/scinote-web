<template>
  <div ref="textCell" v-if="params.value">
    <span v-html="linkedValue"></span>
  </div>
</template>

<script>
import autolink from '../../../shared/autolink.js';

export default {
  name: 'TextValue',
  props: {
    params: {
      required: true
    }
  },
  computed: {
    linkedValue() {
      return autolink(this.params?.value?.value?.edit || '');
    }
  },
  mounted() {
    this.$nextTick(this.renderSmartAnnotations);
  },
  methods: {
    renderSmartAnnotations() {
      if (!this.$refs.textCell) return;

      const tableRoot = this.params.eGridCell?.closest('.ag-root-wrapper, .ag-root');
      const bodyViewport = tableRoot?.querySelector('.ag-body-viewport, .ag-center-cols-viewport');
      window.renderElementSmartAnnotations(this.$refs.textCell, 'span', [bodyViewport, window].filter(Boolean));
    }
  }
};
</script>
