<template>
  <div class="sci-input-container-v2 h-24 mb-1" :class="{'error': !validValue}" :data-error="valueFieldError">
    <textarea
      class="sci-input"
      :value="value"
      ref="input"
      :disabled="fieldDisabled"
      @change="saveValue"
      :placeholder="fieldDisabled ? '' : i18n.t('forms.fields.add_text')"></textarea>
  </div>
</template>

<script>
/* global GLOBAL_CONSTANTS */

import fieldMixin from './field_mixin';

export default {
  name: 'TextField',
  mixins: [fieldMixin],
  data() {
    return {
      value: this.field.field_value?.value
    };
  },
  methods: {
    saveValue(event) {
      this.value = event.target.value;
      if (this.validValue) {
        this.$emit('save', this.value);
      }
    }
  },
  computed: {
    validValue() {
      if (!this.value) {
        return true;
      }
      return this.value.length <= GLOBAL_CONSTANTS.TEXT_MAX_LENGTH;
    },
    valueFieldError() {
      if (this.value && this.value.length > GLOBAL_CONSTANTS.TEXT_MAX_LENGTH) {
        return this.i18n.t('forms.show.field_too_long_error', { limit: GLOBAL_CONSTANTS.TEXT_MAX_LENGTH });
      }
      return '';
    }
  }
};
</script>
