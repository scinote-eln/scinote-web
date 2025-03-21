<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center gap-4">
      <div class="flex items-center grow flex-wrap gap-4 ">
        <h3 class="flex items-center gap-2 m-0 mr-auto">
          <i class="sn-icon rounded text-sn-blue bg-sn-super-light-blue p-1" :class="icon"></i>
          {{ i18n.t(`forms.show.blocks.${editField.attributes.type}`) }}
        </h3>
        <div class="flex items-center gap-3">
          <div class="flex items-center gap-2">
            <span class="sci-toggle-checkbox-container">
              <input type="checkbox"
                    class="sci-toggle-checkbox"
                    data-e2e="e2e-TG-forms-builder-required"
                    @change="updateField"
                    v-model="editField.attributes.required" />
              <span class="sci-toggle-checkbox-label"></span>
            </span>
            <span>{{ i18n.t('forms.show.required_label') }}</span>
          </div>
        </div>
      </div>
      <div>
        <GeneralDropdown  position="right">
          <template v-slot:field>
            <button class="btn btn-secondary icon-btn">
              <i class="sn-icon sn-icon-more-hori"></i>
            </button>
          </template>
          <template v-slot:flyout>
            <div @click="duplicateField" class="py-2.5 px-3 hover:bg-sn-super-light-grey cursor-pointer ">
              {{ i18n.t('forms.show.duplicate') }}
            </div>
            <div @click="deleteField" class="py-2.5 px-3 hover:bg-sn-super-light-grey cursor-pointer text-sn-delete-red">
              {{ i18n.t('forms.show.delete') }}
            </div>
          </template>
        </GeneralDropdown>
      </div>
    </div>
    <hr class="my-4 w-full">
    <div class="flex flex-col gap-4 max-w-[768px]">
      <div>
        <label class="sci-label">{{ i18n.t('forms.show.title_label') }}</label>
        <div class="sci-input-container-v2" :class="{ 'error': !nameValid }" :data-error="nameFieldError"  >
          <input type="text" class="sci-input" v-model="editField.attributes.name" @change="updateField" :placeholder="i18n.t('forms.show.title_placeholder')" />
        </div>
      </div>
      <div>
        <label class="sci-label">{{ i18n.t('forms.show.description_label') }}</label>
        <div class="sci-input-container-v2 h-24" :class="{ 'error': !descriptionValid }" :data-error="descriptionFieldError"  >
          <textarea ref="description"
                    class="sci-input"
                    v-model="editField.attributes.description"
                    @blur="updateField"
                    :placeholder="i18n.t('forms.show.description_placeholder')" />
        </div>
      </div>
      <component :is="this.editField.attributes.type" :field="editField" @updateField="updateField()" @syncField="syncField" />
      <div class="bg-sn-super-light-grey rounded p-4">
        <div class="flex items-center gap-4">
          <h5>{{ i18n.t('forms.show.mark_as_na') }}</h5>
          <span class="sci-toggle-checkbox-container">
            <input type="checkbox"
                  class="sci-toggle-checkbox"
                  data-e2e="e2e-TG-forms-builder-notApplicable"
                 @change="updateField"
                  v-model="editField.attributes.allow_not_applicable" />
            <span class="sci-toggle-checkbox-label"></span>
          </span>
        </div>
        <div>{{ i18n.t('forms.show.mark_as_na_explanation') }}</div>
      </div>
    </div>
  </div>
</template>

<script>

/* global GLOBAL_CONSTANTS SmartAnnotation */

import GeneralDropdown from '../shared/general_dropdown.vue';
import DatetimeField from './edit_fields/datetime.vue';
import NumberField from './edit_fields/number.vue';
import SingleChoiceField from './edit_fields/single_choice.vue';
import TextField from './edit_fields/text.vue';
import MultipleChoiceField from './edit_fields/multiple_choice.vue';

export default {
  name: 'EditField',
  props: {
    field: Object,
    icon: String
  },
  components: {
    GeneralDropdown,
    DatetimeField,
    NumberField,
    SingleChoiceField,
    TextField,
    MultipleChoiceField
  },
  data() {
    return {
      editField: { ...this.field }
    };
  },
  created() {
    if (!this.editField.attributes.data.validations) {
      this.editField.attributes.data.validations = {};
    }

    if (!this.editField.attributes.description) {
      this.editField.attributes.description = '';
    }
  },
  mounted() {
    SmartAnnotation.init($(this.$refs.description), false);
  },
  computed: {
    validField() {
      return this.nameValid && this.descriptionValid;
    },
    nameValid() {
      return this.editField.attributes.name.length > 0 && this.editField.attributes.name.length <= GLOBAL_CONSTANTS.NAME_MAX_LENGTH;
    },
    descriptionValid() {
      return this.editField.attributes.description.length <= GLOBAL_CONSTANTS.TEXT_MAX_LENGTH;
    },
    nameFieldError() {
      if (this.editField.attributes.name.length === 0) {
        return this.i18n.t('forms.show.title_empty_error');
      }

      if (this.editField.attributes.name.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH) {
        return this.i18n.t('forms.show.title_too_long_error', { limit: GLOBAL_CONSTANTS.NAME_MAX_LENGTH });
      }

      return '';
    },
    descriptionFieldError() {
      if (this.editField.attributes.description.length > GLOBAL_CONSTANTS.TEXT_MAX_LENGTH) {
        return this.i18n.t('forms.show.description_too_long_error', { limit: GLOBAL_CONSTANTS.TEXT_MAX_LENGTH });
      }

      return '';
    }
  },
  methods: {
    updateField() {
      if (!this.validField) {
        return;
      }
      this.editField.attributes.description = this.$refs.description.value; // SmartAnnotation does not update the model

      this.$emit('update', this.editField);
    },
    deleteField() {
      this.$emit('delete', this.editField);
    },
    duplicateField() {
      this.$emit('duplicate', this.editField);
    },
    syncField(field) {
      this.editField = field;
    }
  }
};
</script>
