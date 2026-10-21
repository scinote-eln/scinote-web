<template>
  <div>
    <InputField
      :label="i18n.t('libraries.manange_modal_column.number_type.decimals_label')"
      v-model="decimals"
      isNumber
      data-e2e="e2e-IF-invItems-manageColumns-decimals"
    />
  </div>
</template>

<script>
/* global GLOBAL_CONSTANTS */
import InputField from '../../../../shared/input_field.vue';

export default {
  name: 'NumberColumnType',
  components: { InputField },
  props: {
    column: { type: Object, default: null }
  },
  data() {
    return {
      maxDecimals: GLOBAL_CONSTANTS.REPOSITORY_NUMBER_TYPE_MAX_DECIMALS,
      decimals: String(this.column?.cellRendererParams?.metadata?.decimals ?? GLOBAL_CONSTANTS.REPOSITORY_NUMBER_TYPE_DEFAULT_DECIMALS)
    };
  },
  methods: {
    valid() {
      const value = parseInt(this.decimals, 10);
      return !Number.isNaN(value) && value >= 0 && value <= this.maxDecimals;
    },
    payload() {
      return { metadata: { decimals: parseInt(this.decimals, 10) } };
    }
  }
};
</script>
