<template>
  <div class="content__form-container pr-8" :data-e2e="`e2e-CO-${dataE2e}-stepForm${element.id}`">
    <div class="sci-divider my-6" v-if="!inRepository"></div>
    <div class="flex items-center gap-4">
      <MenuDropdown
        class="ml-auto"
        :listItems="this.actionMenu"
        :btnClasses="'btn btn-light icon-btn btn-sm'"
        :position="'right'"
        :btnIcon="'sn-icon sn-icon-more-hori'"
        :dataE2e="`e2e-DD-${dataE2e}-stepText${element.id}-options`"
        @move="showMoveModal"
        @delete="showDeleteModal"
      ></MenuDropdown>
    </div>
    <div class="max-w-[800px] w-full rounded bg-sn-super-light-grey p-6 flex flex-col gap-4">
      <div class="flex items-center">
        <h3 class="my-1">{{ form.name }}</h3>
        <template v-if="!this.formResponse.in_repository">
          <div v-if="this.formResponse.status == 'submitted'" class="ml-auto text-right text-xs text-sn-grey-700">
            {{ i18n.t('forms.response.submitted_on') }} {{ this.formResponse.submitted_at }}<br>
            {{ i18n.t('forms.response.by') }} {{ this.formResponse.submitted_by_full_name }}
          </div>
          <div v-else class="ml-auto text-right text-xs text-sn-grey-700">
            {{ i18n.t('forms.response.not_submitted') }}
          </div>
        </template>
      </div>
      <Field v-for="field in formFields" :disabled="formDisabled" ref="formFields" :key="field.id" :field="field"
                                         :formResponse="formResponse" @save="saveValue" @validChanged="checkValidFormFields" />
      <div>
        <button v-if="this.formResponse.urls.submit" class="btn btn-primary" :disabled="!validResponse || !isValid" @click="submitForm">
          {{ i18n.t('forms.response.submit') }}
        </button>
        <button v-else-if="this.formResponse.urls.reset" class="btn btn-secondary" @click="resetForm">
          {{ i18n.t('general.edit')}}
        </button>
      </div>
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement($event)" @close="closeDeleteModal"/>
    <moveElementModal v-if="movingElement"
                      :parent_type="element.attributes.orderable.parent_type"
                      :targets_url="element.attributes.orderable.urls.move_targets_url"
                      @confirm="moveElement($event)" @cancel="closeMoveModal"/>
  </div>
</template>

<script>
/* global I18n */

import DeleteMixin from './mixins/delete.js';
import MoveMixin from './mixins/move.js';
import deleteElementModal from './modal/delete.vue';
import moveElementModal from './modal/move.vue';
import MenuDropdown from '../menu_dropdown.vue';
import Field from '../../forms/field.vue';
import axios from '../../../packs/custom_axios.js';

export default {
  name: 'TextContent',
  components: {
    deleteElementModal,
    moveElementModal,
    MenuDropdown,
    Field
  },
  mixins: [DeleteMixin, MoveMixin],
  props: {
    element: {
      type: Object,
      required: true
    },
    inRepository: {
      type: Boolean,
      required: true
    },
    reorderElementUrl: {
      type: String
    },
    dataE2e: {
      type: String,
      default: ''
    }
  },
  data() {
    return {
      form: this.element.attributes.orderable.form,
      formResponse: this.element.attributes.orderable,
      formFieldValues: this.element.attributes.orderable.form_field_values,
      deleteUrl: this.element.attributes.orderable.urls.delete_url,
      moveUrl: this.element.attributes.orderable.urls.move_url,
      isValid: false
    };
  },
  mounted() {
    this.checkValidFormFields();
  },
  computed: {
    formDisabled() {
      return !this.formResponse.urls.submit;
    },
    validResponse() {
      return this.formFields.every((field) => {
        if (field.attributes.required) {
          return field.field_value?.value
            || field.field_value?.selection
            || field.field_value?.datetime
            || field.field_value?.datetime_to
            || field.field_value?.not_applicable;
        }
        return true;
      });
    },
    formFields() {
      return this.element.attributes.orderable.form_fields.map((field) => ({
        id: field.id,
        attributes: field,
        field_value: this.formFieldValues.find((value) => value.form_field_id === field.id)
      }));
    },
    actionMenu() {
      const menu = [];
      if (this.element.attributes.orderable.urls.move_targets_url) {
        menu.push({
          text: I18n.t('general.move'),
          emit: 'move',
          data_e2e: `e2e-BT-${this.dataE2e}-stepText${this.element.id}-options-move`
        });
      }
      if (this.element.attributes.orderable.urls.delete_url) {
        menu.push({
          text: I18n.t('general.delete'),
          emit: 'delete',
          data_e2e: `e2e-BT-${this.dataE2e}-stepText${this.element.id}-options-delete`
        });
      }
      return menu;
    }
  },
  methods: {
    saveValue(formFieldId, value, markAsNa) {
      axios.post(this.formResponse.urls.add_value, {
        form_field_value: {
          form_field_id: formFieldId,
          value,
          not_applicable: markAsNa
        }
      }).then((response) => {
        if (this.formFieldValues.find((formFieldValue) => formFieldValue.form_field_id === formFieldId)) {
          this.formFieldValues = this.formFieldValues.map((formFieldValue) => {
            if (formFieldValue.form_field_id === formFieldId) {
              return response.data.data.attributes;
            }
            return formFieldValue;
          });
        } else {
          this.formFieldValues.push(response.data.data.attributes);
        }
      });
    },
    submitForm() {
      axios.post(this.formResponse.urls.submit).then((response) => {
        const { attributes } = response.data.data;
        this.formResponse = attributes.orderable;
        this.deleteUrl = attributes.orderable.urls.delete_url;
        this.moveUrl = attributes.orderable.urls.move_url;
      });
    },
    resetForm() {
      axios.post(this.formResponse.urls.reset).then((response) => {
        const { attributes } = response.data.data;
        this.formResponse = attributes.orderable;
        this.deleteUrl = attributes.orderable.urls.delete_url;
        this.moveUrl = attributes.orderable.urls.move_url;
      });
    },
    checkValidFormFields() {
      if (this.$refs.formFields) {
        this.isValid = this.$refs.formFields.every((field) => field.isValid == null || field.isValid);
      }
    }
  }
};
</script>
