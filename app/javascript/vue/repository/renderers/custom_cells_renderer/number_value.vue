<template>
  <div v-if="canManage" class="relative" :title="mandatoryErrorTitle">
    <input
      ref="input"
      v-model="newValue"
      type="text"
      :placeholder="(isFocused ? '' : i18n.t('repositories.table.number.enter_number'))"
      @keydown.enter="saveValue"
      @keydown.esc="cancelEdit"
      @keydown="handleKeydown"
      @focus="isFocused = true"
      @blur="onBlur"
      @input="validateFormat"
      class="sci-table-input-v2 placeholder:text-sn-grey"
      :class="inputClass"
    />
    <MandatoryError :show="params.inSidebar && showError" />
  </div>
  <div v-else>
    {{ this.newValue }}
  </div>
</template>

<script>
/* global GLOBAL_CONSTANTS */
import MandatoryError from './shared/mandatory_error.vue';
import mandatoryCellMixin from './mixins/mandatory_cell.js';

export default {
  name: 'NumberValue',
  mixins: [mandatoryCellMixin],
  components: {
    MandatoryError
  },
  props: {
    params: {
      required: true
    }
  },
  created() {
    this.newValue = this.params?.value?.value;
  },
  data() {
    return {
      newValue: null,
      isFocused: false,
    };
  },
  computed: {
    // 0 is a valid value; partial input such as '-' cannot be saved, so it counts as empty
    isEmpty() {
      if (this.newValue === null || this.newValue === undefined) return true;

      const value = String(this.newValue).trim();
      return value === '' || Number.isNaN(Number(value));
    },
    inputClass() {
      if (this.showError) return ['!border-sn-delete-red', this.params.inSidebar ? 'rounded px-3' : '!bg-transparent'];
      if (this.params.inSidebar) return '!border-sn-light-grey rounded px-3';

      return '!border-transparent !bg-transparent';
    },
    canManage() {
      return this.params?.data?.permissions?.manage || false;
    }
  },
  methods: {
    handleKeydown(event) {
      if (['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) {
        event.stopPropagation();
      }
    },
    validateFormat() {
      const decimals = this.params?.colDef?.cellRendererParams?.metadata?.decimals ?? GLOBAL_CONSTANTS.REPOSITORY_NUMBER_TYPE_DEFAULT_DECIMALS;
      const regexp = decimals === 0 ? /[^-0-9]/g : /[^-0-9.]/g;
      const decimalsRegex = new RegExp(`^-?\\d*(\\.\\d{0,${decimals}})?`);
      let value = this.newValue;
      value = value.replace(regexp, '');
      value = value.match(decimalsRegex)[0];
      this.newValue = value;
    },
    saveValue() {
      if (this.blockedByMandatory()) return;

      if (this.newValue !== this.params?.value?.value) {
        this.params.dtComponent.$emit(
          'updateCell',
          this.params.data,
          this.params.colDef,
          this.newValue
        );
      }
    },
    onBlur() {
      this.isFocused = false;
      this.saveValue();
    },
    cancelEdit() {
      this.newValue = this.params?.value?.value;
      this.$nextTick(() => {
        this.$refs.input.blur();
      });
    }
  }
};
</script>
