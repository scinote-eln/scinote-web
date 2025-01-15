<template>
   <div v-if="form" class="content-pane flexible with-grey-background">
    <div class="content-header flex items-center mb-4">
      <div class="title-row">
        <h1>
          <span class="w-12" v-if="form.attributes.archived">{{ i18n.t('labels.archived') }}</span>
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
        <button v-if="preview && !this.form.attributes.published_on && this.form.attributes.can_manage_form_draft" class="btn btn-secondary"@click="preview = false">
          <i class="sn-icon sn-icon-edit"></i>
          {{ i18n.t('forms.show.edit_form') }}
        </button>
        <button v-if="!preview" class="btn btn-secondary" @click="preview = true">
          <i class="sn-icon sn-icon-visibility-show"></i>
          {{ i18n.t('forms.show.test_form') }}
        </button>
        <button v-if="form.attributes.urls.publish" class="btn btn-primary" @click="publishForm">
          {{ i18n.t('forms.show.publish') }}
        </button>
        <button v-if="form.attributes.published_on" :disabled="!form.attributes.urls.unpublish" class="btn btn-secondary" @click="unpublishForm">
          {{ i18n.t('forms.show.unpublish') }}
        </button>
      </div>
    </div>
    <div class="content-body">
      <Preview v-if="preview" :form="form" :fields="fields" />
      <div v-else class="bg-white rounded-xl grid grid-cols-[360px_auto] min-h-[calc(100vh_-_200px)]">
        <div class="p-6 border-transparent border-r-sn-sleepy-grey border-solid border-r">
          <h3 class="mb-3">{{  i18n.t('forms.show.build_form') }}</h3>
          <div class="mb-3 flex flex-col gap-3">
          <Draggable
            v-model="fields"
            class="flex flex-col gap-3"
            handle=".element-grip"
            item-key="id"
            @end="saveOrder"
          >
            <template #item="{element, index}">
              <div class="flex items-center relative group -ml-6 w-[calc(100%_+_24px)]">
                <i class="sn-icon sn-icon-drag text-sn-grey element-grip cursor-grab opacity-0 group-hover:opacity-100"></i>
                <div @click="activeField = element"
                    :key="element.id"
                    class="font-bold relative grow p-2 rounded-lg overflow-hidden flex items-center gap-2 border-sn-grey-100 cursor-pointer border"
                    :class="{ '!border-sn-blue bg-sn-super-light-blue': activeField.id === element.id }"
                >
                  <i class="sn-icon rounded text-sn-blue bg-sn-super-light-blue p-1" :class="fieldIcon[element.attributes.data.type]"></i>
                  <span class="truncate">{{ element.attributes.name }}</span>
                </div>
              </div>
            </template>
          </Draggable>
          </div>
          <GeneralDropdown ref="addFieldDropdown">
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
          <div v-if="!activeField.id"
               class="text-xl font-semibold text-sn-grey font-inter flex items-center justify-center w-full h-full">
            {{ i18n.t('forms.show.no_block') }}
          </div>
        </div>
      </div>
    </div>
    <ConfirmationModal
      :title="i18n.t('forms.publish.title')"
      :description="i18n.t('forms.publish.description_html')"
      confirmClass="btn btn-primary"
      :confirmText="i18n.t('forms.show.publish')"
      ref="publishModal">
    </ConfirmationModal>
  </div>
</template>

<script>

import Draggable from 'vuedraggable';
import InlineEdit from '../shared/inline_edit.vue';
import axios from '../../packs/custom_axios.js';
import GeneralDropdown from '../shared/general_dropdown.vue';
import EditField from './edit_field.vue';
import Preview from './preview.vue';
import ConfirmationModal from '../shared/confirmation_modal.vue';

export default {
  name: 'ShowForm',
  props: {
    formUrl: String
  },
  components: {
    InlineEdit,
    GeneralDropdown,
    EditField,
    Draggable,
    Preview,
    ConfirmationModal
  },
  computed: {
    canManage() {
      return !this.form.attributes.published_on;
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
      activeField: {},
      preview: false
    };
  },
  methods: {
    loadForm() {
      axios.get(this.formUrl).then((response) => {
        this.form = response.data.data;
        this.fields = response.data.included || [];
        this.fields = this.fields.sort((a, b) => a.attributes.position - b.attributes.position);
        if (this.fields.length > 0) {
          [this.activeField] = this.fields;
        }
        if (this.form.attributes.published_on || !this.form.attributes.urls.create_field) {
          this.preview = true;
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
        this.activeField = this.fields[this.fields.length - 1];
        this.$refs.addFieldDropdown.isOpen = false;
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
    saveOrder() {
      axios.post(this.form.attributes.urls.reorder_fields, {
        form_field_positions: this.fields.map((f, i) => ({ id: f.id, position: i }))
      });
    },
    deleteField(field) {
      const index = this.fields.findIndex((f) => f.id === field.id);
      axios.delete(field.attributes.urls.show).then(() => {
        this.fields.splice(index, 1);
        if (this.fields.length > 0) {
          this.activeField = this.fields[index - 1];
        } else {
          this.activeField = {};
        }
      });
    },
    async publishForm() {
      const ok = await this.$refs.publishModal.show();
      if (ok) {
        axios.post(this.form.attributes.urls.publish).then((response) => {
        this.form = response.data.data;
        this.preview = true;
        });
      }
    },
    unpublishForm() {
      axios.post(this.form.attributes.urls.unpublish).then((response) => {
        this.form = response.data.data;
        this.preview = false;
      });
    }
  }
};
</script>
