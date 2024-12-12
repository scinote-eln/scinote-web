<template>
   <div v-if="form" class="content-pane flexible with-grey-background">
    <div class="content-header flex items-center mb-4">
      <div class="title-row">
        <h1>
          <InlineEdit
            v-if="canManage"
            :value="form.attributes.name"
            :characterLimit="255"
            attributeName="name"
            :characterMinLimit="2"
            :allowBlank="false"
            @editingEnabled="editingName = true"
            @editingDisabled="editingName = false"
            @update="updateName"
          />
          <template v-else>
            {{ form.attributes.name }}
          </template>
        </h1>
      </div>
      <div class="flex items-center gap-4 ml-auto">
        <button class="btn btn-secondary">
          <i class="sn-icon sn-icon-visibility-show"></i>
          {{ i18n.t('forms.show.test_form') }}
        </button>
        <button class="btn btn-primary">
          {{ i18n.t('forms.show.publish') }}
        </button>
      </div>
    </div>
    <div class="content-body">
      <div class="bg-white rounded-xl grid grid-cols-[360px_auto] min-h-[calc(100vh_-_200px)]">
        <div class="p-6 border-transparent border-r-sn-sleepy-grey border-solid border-r">
          <h3 class="mb-3">{{  i18n.t('forms.show.build_form') }}</h3>
          <div class="mb-3 flex flex-col gap-3">
            <div v-for="(field) in fields"
                 @click="activeField = field"
                 :key="field.id"
                 class="font-bold p-3 rounded-lg flex items-center gap-2 border-sn-grey-100 cursor-pointer border"
                 :class="{ '!border-sn-blue bg-sn-super-light-blue': activeField.id === field.id }"
            >
              <i class="sn-icon rounded text-sn-blue bg-sn-super-light-blue p-1" :class="fieldIcon[field.attributes.data.type]"></i>
              {{ field.attributes.name }}
            </div>
          </div>
          <GeneralDropdown>
            <template v-slot:field>
              <button class="btn btn-secondary w-full">
                <i class="sn-icon sn-icon-new-task"></i>
                {{ i18n.t('forms.show.add_block') }}
              </button>
            </template>
            <template v-slot:flyout>
              <div v-for="e in newFields" :key="e.type" @click="addField(e.type)" class="py-2.5 px-3 hover:bg-sn-super-light-grey cursor-pointer flex items-center gap-2">
                <i class="sn-icon rounded text-sn-blue bg-sn-super-light-blue p-1" :class="fieldIcon[e.type]"></i>
                {{ e.name }}
              </div>
            </template>
          </GeneralDropdown>
        </div>
        <div class="p-6">
          <EditField
            :key="activeField.id"
            v-if="activeField.id"
            :field="activeField"
            :icon="fieldIcon[activeField.attributes.data.type]"
            @update="updateField"
            @delete="deleteField"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import InlineEdit from '../shared/inline_edit.vue';
import axios from '../../packs/custom_axios.js';
import GeneralDropdown from '../shared/general_dropdown.vue';
import EditField from './edit_field.vue';

export default {
  name: 'ShowForm',
  props: {
    formUrl: String
  },
  components: {
    InlineEdit,
    GeneralDropdown,
    EditField
  },
  computed: {
    canManage() {
      return true;
    },
    newFields() {
      return [
        { name: this.i18n.t('forms.show.blocks.TextField'), type: 'TextField' },
        { name: this.i18n.t('forms.show.blocks.NumberField'), type: 'NumberField' },
        { name: this.i18n.t('forms.show.blocks.SingleChoiceField'), type: 'SingleChoiceField' },
        { name: this.i18n.t('forms.show.blocks.MultipleChoiceField'), type: 'MultipleChoiceField' },
        { name: this.i18n.t('forms.show.blocks.DatetimeField'), type: 'DatetimeField' }
      ];
    },
    fieldIcon() {
      return {
        TextField: 'sn-icon-result-text',
        NumberField: 'sn-icon-value',
        SingleChoiceField: 'sn-icon-choice-single',
        MultipleChoiceField: 'sn-icon-choice-multiple',
        DatetimeField: 'sn-icon-created'
      };
    }
  },
  created() {
    this.loadForm();
  },
  data() {
    return {
      form: null,
      fields: [],
      activeField: {}
    };
  },
  methods: {
    loadForm() {
      axios.get(this.formUrl).then((response) => {
        this.form = response.data.data;
        this.fields = response.data.included || [];
        if (this.fields.length > 0) {
          [this.activeField] = this.fields;
        }
      });
    },
    addField(type) {
      axios.post(this.form.attributes.urls.create_field, {
        form_field: {
          name: this.i18n.t(`forms.show.blocks.${type}`),
          data: {
            type
          }
        }
      }).then((response) => {
        this.fields.push(response.data.data);
        if (this.fields.length === 1) {
          [this.activeField] = this.fields;
        }
      });
    },
    updateName(name) {
      axios.put(this.formUrl, {
        form: {
          name
        }
      }).then(() => {
        this.form.attributes.name = name;
      });
    },
    updateField(field) {
      const index = this.fields.findIndex((f) => f.id === field.id);
      axios.put(field.attributes.urls.show, {
        form_field: field.attributes
      }).then((response) => {
        this.fields.splice(index, 1, response.data.data);
      });
    },
    deleteField(field) {
      const index = this.fields.findIndex((f) => f.id === field.id);
      axios.delete(field.attributes.urls.show).then(() => {
        this.fields.splice(index, 1);
        if (this.fields.length > 0) {
          [this.activeField] = this.fields;
        } else {
          this.activeField = {};
        }
      });
    }
  }
};
</script>
