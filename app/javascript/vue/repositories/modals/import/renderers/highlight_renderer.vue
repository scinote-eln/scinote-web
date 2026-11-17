<template>
  <span v-if="mandatoryMissing" class="text-sn-alert-passion">
    {{ i18n.t('repositories.import_records.steps.step3.mandatory_column') }}
  </span>
  <span v-else-if="cellError" class="text-sn-alert-passion" :data-sn-tooltip="cellError.message">
    {{ errorContent }}
  </span>
  <span v-else :class="{ 'text-sn-alert-green': changed }">{{ params.value }}</span>
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
    columnKey() {
      return this.params.colDef.cellRendererParams?.columnKey;
    },
    mandatoryMissing() {
      return (this.params.data.import_mandatory_missing || []).includes(this.columnKey);
    },
    cellError() {
      return (this.params.data.import_cell_errors || {})[this.columnKey];
    },
    errorContent() {
      return this.cellError.value || this.params.value || this.cellError.message;
    },
    changed() {
      const hasValue = this.params.value !== null && this.params.value !== undefined && this.params.value !== '';
      return hasValue && (this.params.data.import_changed_columns || []).includes(this.columnKey);
    }
  }
};
</script>
