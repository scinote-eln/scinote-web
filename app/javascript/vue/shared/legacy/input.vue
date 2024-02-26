<template>
  <div class="relative" :class="fieldClass">
    <label v-if="showLabel" :class="labelClass" :for="id">{{ label }}</label>
    <div :class="inputClass">
      <input ref="input"
        :type="type"
        :id="id"
        :name="name"
        :value="inputValue"
        :class="`${error ? 'error' : ''}`"
        :placeholder="placeholder"
        :required="required"
        @input="updateValue"
      />
      <div
        class="mt-2 text-sn-delete-red whitespace-nowrap truncate text-xs font-normal absolute bottom-[-1rem] w-full"
        :title="error"
        :class="{ visible: error, invisible: !error}"
      >
        {{ error }}
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Input',
  props: {
    id: { type: String, required: false },
    fieldClass: { type: String, default: '' },
    inputClass: { type: String, default: '' },
    labelClass: { type: String, default: '' },
    type: { type: String, default: 'text' },
    name: { type: String, required: true },
    value: { type: [String, Number], required: false },
    decimals: { type: [Number, String], default: 0 },
    placeholder: { type: String, default: '' },
    required: { type: Boolean, default: false },
    showLabel: { type: Boolean, default: false },
    label: { type: String, required: false },
    autoFocus: { type: Boolean, default: false },
    error: { type: String, required: false }
  },
  computed: {
    inputValue() {
      if (this.type === 'text') return this.value;

      return isNaN(this.value) ? '' : this.value;
    }
  },
  methods: {
    updateValue($event) {
      switch (this.type) {
        case 'text':
          this.$emit('update', $event.target.value);
          break;
        case 'number':
          const newValue = this.formatDecimalValue($event.target.value);
          this.$refs.input.value = newValue;
          if (!isNaN(newValue)) this.$emit('update', newValue);
          break;
        default:
          break;
      }
    },
    formatDecimalValue(value) {
      const decimalValue = value.replace(/[^-0-9.]/g, '');
      if (this.decimals === '0') {
        return decimalValue.split('.')[0];
      }
      return decimalValue.match(new RegExp(`^-?\\d*(\\.\\d{0,${this.decimals}})?`))[0];
    }
  }
};
</script>
