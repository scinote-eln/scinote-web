<template>
  <div class="relative w-full">
    <label v-if="label" class="sci-label" :class="{ 'error': !!inputError }" :for="id">{{ label }}</label>
    <div class="sci-input-container-v2" :class="{ 'error': !!inputError }" :data-error-text="inputError">
      <input ref="input"
        lang="en-US"
        type="text"
        :id="id"
        :name="name"
        :value="value"
        :class="{ 'error': !!inputError }"
        :placeholder="placeholder"
        inputmode="numeric"
        :min="min"
        :max="max"
        :step="1/Math.pow(10, decimals)"
        :inputmode="(type === 'number') && 'numeric'"
        :pattern="pattern"
        @input="updateValue"
      />
    </div>
  </div>
</template>

<script>

export default {
  name: 'Input',
  props: {
    id: { type: String, required: false },
    type: { type: String, default: 'text' },
    name: { type: String, required: true },
    value: { type: [String, Number], required: false },
    decimals: { type: [Number, String], default: 0 },
    placeholder: { type: String, default: '' },
    required: { type: Boolean, default: false },
    label: { type: String, required: false },
    error: { type: String, required: false },
    min: { type: String },
    max: { type: String },
    blockInvalidInput: { type: Boolean, default: true }
  },
  data() {
    return {
      inputError: false,
      lastValue: this.value || ''
    };
  },
  watch: {
    value() {
      this.lastValue = this.value;
    }
  },
  computed: {
    pattern() {
      if (this.type === 'number' && this.decimals) {
        return `[0-9]+([\\.][0-9]{0,${this.decimals}})?`;
      } else if (this.type === 'number') {
        return '[0-9]+';
      }

      return null;
    }
  },
  methods: {
    updateValue($event) {
      this.checkInputError($event);
      this.$emit('update', $event.target.value);
    },
    checkInputError() {
      const isValid = this.$refs.input.checkValidity();

      if (isValid) {
        this.lastValue = this.$refs.input.value;
      } else if (this.blockInvalidInput) {
        this.$refs.input.value = this.lastValue;
        return;
      }

      this.inputError = this.error || (!isValid && this.i18n.t('input.errors.invalid_value'));
    }
  }
};
</script>
