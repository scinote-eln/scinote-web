<template>
  <div class="sci-input-container-v2 mb-2" :class="{'error': !isValidValue}" :data-error="errorMessage">
    <input type="number" v-model="value" class="sci-input" :disabled="fieldDisabled" @change="saveValue"
      :placeholder="fieldDisabled ? '' : i18n.t('forms.fields.add_number')"></input>
  </div>
</template>

<script>
import fieldMixin from './field_mixin';

export default {
  name: 'NumberField',
  mixins: [fieldMixin],
  data() {
    return {
      value: this.field.field_value?.value
    };
  },
  computed: {
    isValidValue() {
      const { validations } = this.field.attributes.data;

      if (!validations || !validations.response_validation) {
        return true;
      }

      if (validations.response_validation.type === 'between' && validations.response_validation.enabled && this.value) {
        return this.value >= validations.response_validation.min
         && this.value <= validations.response_validation.max;
      }

      return true;
    },
    errorMessage() {
      const { validations } = this.field.attributes.data;

      if (!validations || !validations.response_validation) {
        return '';
      }

      if (validations.response_validation) {
        return validations.response_validation.message;
      }

      return '';
    }
  },
  methods: {
    saveValue() {
      if (this.isValidValue) {
        this.$emit('save', this.value);
      }
    }
  }
};
</script>
