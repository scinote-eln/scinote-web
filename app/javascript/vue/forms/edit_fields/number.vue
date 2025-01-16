<template>
  <div class="flex flex-col gap-4">
    <div>
      <label class="sci-label">{{ i18n.t('forms.show.unit_label') }}</label>
      <div class="sci-input-container-v2" :class="{'error': !unitValid}" :data-error="unitFieldError">
        <input type="text"
              class="sci-input"
              v-model="editField.attributes.data.unit"
              @change="updateField"
              :placeholder="i18n.t('forms.show.unit_placeholder')" />
      </div>
    </div>
    <hr class="my-4 w-full">
    <div class="bg-sn-super-light-grey rounded p-4">
      <div class="flex items-center gap-4">
        <h5>{{ i18n.t('forms.show.validations.response_validation.title') }}</h5>
        <span class="sci-toggle-checkbox-container">
          <input type="checkbox"
                 class="sci-toggle-checkbox"
                 @change="updateField"
                 v-model="responseValidation.enabled" />
          <span class="sci-toggle-checkbox-label"></span>
        </span>
      </div>
      <div v-if="responseValidation.enabled" class="grid grid-cols-3 gap-2">
        <div>
          <SelectDropdown
            class="bg-white"
            :disabled="!responseValidationEnabled"
            :options="responseValidationTypes"
            :value="responseValidation.type" />
        </div>
        <div class="sci-input-container-v2" :class="{ 'error': !responseValidationIsValid }" >
          <input type="number" class="sci-input !bg-white"
                 :disabled="!responseValidationEnabled"
                 @change="updateField"
                 :placeholder="i18n.t('forms.show.validations.response_validation.min_placeholder')"
                 v-model="responseValidation.min" />
        </div>
        <div class="sci-input-container-v2" :class="{ 'error': !responseValidationIsValid }">
          <input type="number" class="sci-input !bg-white"
                 :disabled="!responseValidationEnabled"
                 @change="updateField"
                 :placeholder="i18n.t('forms.show.validations.response_validation.max_placeholder')"
                 v-model="responseValidation.max" />
        </div>
        <div class="col-span-3 sci-input-container-v2" :class="{'error': !validationMessageValid}" :data-error="validationMessageError">
          <input type="text" class="sci-input !bg-white"
                 :disabled="!responseValidationEnabled"
                 @change="updateField"
                 :placeholder="i18n.t('forms.show.validations.response_validation.message_placeholder')"
                 v-model="responseValidation.message" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
/* global GLOBAL_CONSTANTS */
import fieldMixin from './field_mixin';
import SelectDropdown from '../../shared/select_dropdown.vue';

export default {
  name: 'NumberField',
  mixins: [fieldMixin],
  components: {
    SelectDropdown
  },
  created() {
    if (!this.responseValidation) {
      this.editField.attributes.data.validations.response_validation = {};
    }

    if (!this.responseValidation.type) {
      this.responseValidation.type = 'between';
    }
  },
  computed: {
    responseValidation() {
      return this.editField.attributes.data.validations.response_validation;
    },
    responseValidationEnabled() {
      return this.responseValidation.enabled;
    },
    responseValidationTypes() {
      return [['between', 'Between']];
    },
    responseValidationIsValid() {
      return (this.responseValidation.min < this.responseValidation.max) || !this.responseValidationEnabled;
    },
    validField() {
      return this.responseValidationIsValid && this.unitValid && this.validationMessageValid;
    },
    unitValid() {
      return !this.editField.attributes.data.unit || this.editField.attributes.data.unit.length <= GLOBAL_CONSTANTS.NAME_MAX_LENGTH;
    },
    unitFieldError() {
      if (this.editField.attributes.data.unit && this.editField.attributes.data.unit.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH) {
        return this.i18n.t('forms.show.field_too_long_error', { limit: GLOBAL_CONSTANTS.NAME_MAX_LENGTH });
      }

      return '';
    },
    validationMessageValid() {
      return !this.responseValidationEnabled || !this.responseValidation.message || this.responseValidation.message.length <= GLOBAL_CONSTANTS.NAME_MAX_LENGTH;
    },
    validationMessageError() {
      if (!this.validationMessageValid) {
        return this.i18n.t('forms.show.field_too_long_error', { limit: GLOBAL_CONSTANTS.NAME_MAX_LENGTH });
      }

      return '';
    }
  },
  methods: {
    updateField() {
      if (!this.validField) {
        return;
      }

      this.$emit('updateField');
    }
  }
};
</script>
