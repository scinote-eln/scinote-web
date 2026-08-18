<template>
  <div v-if="canManage" class="relative">
    <input
      ref="input"
      v-model="newValue"
      type="text"
      :placeholder="i18n.t('repositories.table.number.enter_number')"
      @keydown.enter="saveValue"
      @keydown.esc="cancelEdit"
      @blur="saveValue"
      @input="validateFormat"
      class="sci-table-input-v2 align-right !border-transparent !bg-transparent placeholder:text-sn-grey"
    />
  </div>
  <div v-else class="align-right">
    {{ this.newValue }}
  </div>
</template>

<script>
export default {
  name: 'NumberValue',
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
    };
  },
  computed: {
    canManage() {
      return this.params?.data?.permissions?.manage || false;
    }
  },
  methods: {
    validateFormat() {
      const decimals = this.params?.colDef?.cellRendererParams?.metadata?.decimals || 0;
      const regexp = decimals === 0 ? /[^-0-9]/g : /[^-0-9.]/g;
      const decimalsRegex = new RegExp(`^-?\\d*(\\.\\d{0,${decimals}})?`);
      let value = this.newValue;
      value = value.replace(regexp, '');
      value = value.match(decimalsRegex)[0];
      this.newValue = value;
    },
    saveValue() {
      if (this.newValue !== this.params?.value?.value) {
        this.params.dtComponent.$emit(
          'updateCell',
          this.params.data,
          this.params.colDef,
          this.newValue
        );
      }
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
