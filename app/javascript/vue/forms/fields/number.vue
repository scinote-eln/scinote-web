<template>
  <div class="w-full">
    <InputField
      v-model="value"
      :disabled="fieldDisabled"
      @change="saveValue"
      :placeholder="fieldDisabled ? '' : i18n.t('forms.fields.add_number')"
      :warning="!isValidValue"
      :warningMessage="warningMessage"
      :isNumber="true"
    ></InputField>
  </div>
</template>

<script>
import fieldMixin from './field_mixin';
import InputField from '../../shared/input_field.vue';

export default {
  name: 'NumberField',
  mixins: [fieldMixin],
  components: {
    InputField
  },
  data() {
    return {
      value: this.field.field_value?.value
    };
  },
  watch: {
    marked_as_na() {
      if (this.marked_as_na) {
        this.value = null;
      }
    }
  },
  computed: {
    // This method is used for user defined validation and we do not disable submit button
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
    warningMessage() {
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
      this.$emit('save', this.value);
    }
  }
};
</script>
