<template>
  <div class="label-templates-show">
    <div class="header">
      <div v-if="labelTemplate.id" class="title-row">
        <img :src="labelTemplate.attributes.icon_url" class="label-template-icon"/>
        <InlineEdit
          v-if="canManage"
          :value="labelTemplate.attributes.name"
          :characterLimit="255"
          :characterMinLimit="2"
          :allowBlank="false"
          :attributeName="i18n.t('label_templates.show.name_error_prefix')"
          :placeholder="i18n.t('label_templates.show.name_placeholder')"
          :autofocus="editingName"
          :editOnload="newLabel"
          @editingEnabled="editingName = true"
          @editingDisabled="editingName = false"
          @update="updateName"
        />
        <template v-else>
          {{ labelTemplate.attributes.name }}
        </template>
      </div>
    </div>
    <div v-if="labelTemplate.id && notFluics" class="template-descripiton">
      <div class="title">
        {{ i18n.t('label_templates.show.description_title') }}
      </div>
      <div class="description">
        <InlineEdit
          v-if="canManage"
          :value="labelTemplate.attributes.description"
          :characterLimit="255"
          :allowBlank="true"
          :attributeName="i18n.t('label_templates.show.description_error_prefix')"
          :placeholder="i18n.t('label_templates.show.description_placeholder')"
          :autofocus="editingDescription"
          @editingEnabled="editingDescription = true"
          @editingDisabled="editingDescription = false"
          @update="updateDescription"
        />
        <template v-else>
          {{ labelTemplate.attributes.description || i18n.t('label_templates.show.description_empty') }}
        </template>
      </div>
    </div>
    <div v-if="labelTemplate.id" class="label-template-container">
      <div class="label-edit-container" v-if="notFluics">
        <div class="label-edit-header">
          <div class="title">
            {{ i18n.t('label_templates.show.content_title', { format: labelTemplate.attributes.language_type.toUpperCase() }) }}
          </div>
          <InsertFieldDropdown
            v-if="editingContent"
            :labelTemplate="labelTemplate"
            @insertTag="insertTag"
          />
        </div>
        <template v-if="editingContent">
          <div class="label-textarea-container" :class="{'error': hasError }">
            <textarea
              ref="contentInput"
              v-model="newContent"
              class="label-textarea"
              @blur="saveCursorPosition"
            ></textarea>
            <div class="error-message">
              {{ codeErrorMessage }}
            </div>
          </div>
          <div class="button-container">
            <div class="btn btn-secondary refresh-preview" @click="generatePreview(true)">
              <i class="fas fa-sync"></i>
              {{ i18n.t('label_templates.show.buttons.refresh') }}
            </div>
            <div class="btn btn-secondary" @mousedown="disableContentEdit">
              {{ i18n.t('general.cancel') }}
            </div>
            <div class="btn btn-primary save-template" :disabled="hasError && previewValid" @click="generatePreview(false)">
              <i class="fas fa-save"></i>
              {{ i18n.t('label_templates.show.buttons.save') }}
            </div>
          </div>
        </template>
        <div v-else-if="canManage" class="label-view-container" :title="i18n.t('label_templates.show.view_content_tooltip')" @click="enableContentEdit">
          {{ labelTemplate.attributes.content}}
          <i class="sn-icon sn-icon-edit"></i>
        </div>
        <div v-else class="label-view-container read-only" :title="i18n.t('label_templates.show.view_content_tooltip')">
          {{ labelTemplate.attributes.content}}
        </div>
      </div>
      <div class="label-preview-container">
        <LabelPreview
          :zpl='previewContent'
          :template="labelTemplate"
          :previewUrl="previewUrl"
          @preview:valid="updateContent"
          @preview:invalid="invalidPreview"
          @height:update="setNewHeight"
          @width:update="setNewWidth"
          @density:update="setNewDensity"
          @unit:update="setNewUnit"
        />
      </div>
    </div>
  </div>
</template>

<script>

import InlineEdit from '../shared/inline_edit.vue';
import InsertFieldDropdown from './insert_field_dropdown.vue';
import LabelPreview from './components/label_preview.vue';

export default {
  name: 'LabelTemplateContainer',
  props: {
    labelTemplateUrl: String,
    labelTemplatesUrl: String,
    previewUrl: String,
    newLabel: Boolean
  },
  data() {
    return {
      labelTemplate: {
        attributes: {}
      },
      editingName: false,
      editingDescription: false,
      editingContent: false,
      newContent: '',
      newLabelWidth: null,
      newLabelHeight: null,
      newLabelDensity: null,
      newLabelUnit: null,
      previewContent: '',
      previewValid: false,
      skipSave: false,
      codeErrorMessage: '',
      cursorPos: 0
    };
  },
  watch: {
    newContent() {
      this.showErrors();
    },
    previewValid() {
      this.showErrors();
    }
  },
  computed: {
    hasError() {
      return this.codeErrorMessage.length > 0;
    },
    canManage() {
      return this.labelTemplate.attributes.urls.update && this.notFluics;
    },
    notFluics() {
      return this.labelTemplate.attributes.type !== 'FluicsLabelTemplate';
    }
  },
  components: { InlineEdit, InsertFieldDropdown, LabelPreview },
  created() {
    $.get(this.labelTemplateUrl, (result) => {
      this.labelTemplate = result.data;
      this.newContent = this.labelTemplate.attributes.content;
      this.previewContent = this.labelTemplate.attributes.content;
      this.newLabelWidth = this.labelTemplate.attributes.width_mm;
      this.newLabelHeight = this.labelTemplate.attributes.height_mm;
      this.newLabelDensity = this.labelTemplate.attributes.density;
      this.newLabelUnit = this.labelTemplate.attributes.unit;
    });
  },
  methods: {
    setNewHeight(val) {
      this.newLabelHeight = val;
    },
    setNewWidth(val) {
      this.newLabelWidth = val;
    },
    setNewDensity(val) {
      this.newLabelDensity = val;
    },
    setNewUnit(val) {
      this.newLabelUnit = val;
    },
    enableContentEdit() {
      this.editingContent = true;
      this.$nextTick(() => {
        this.$refs.contentInput.focus();
        const { contentInput } = this.$refs;
        const contentLength = contentInput.value.length;
        contentInput.setSelectionRange(contentLength, contentLength);
      });
    },
    disableContentEdit() {
      this.editingContent = false;
      this.newContent = this.labelTemplate.attributes.content;
      this.previewContent = this.labelTemplate.attributes.content;
    },
    updateName(newName) {
      $.ajax({
        url: this.labelTemplate.attributes.urls.update,
        type: 'PATCH',
        data: { label_template: { name: newName } },
        success: (result) => {
          this.labelTemplate.attributes.name = result.data.attributes.name;
        }
      });
    },
    updateDescription(newDescription) {
      $.ajax({
        url: this.labelTemplate.attributes.urls.update,
        type: 'PATCH',
        data: { label_template: { description: newDescription } },
        success: (result) => {
          this.labelTemplate.attributes.description = result.data.attributes.description;
        }
      });
    },
    updateContent() {
      this.previewValid = true;

      this.saveLabelDimensions();

      if (!this.editingContent) return;

      if (this.skipSave) {
        this.skipSave = false;
        return;
      }

      this.$nextTick(() => {
        if (this.hasError) return;

        $.ajax({
          url: this.labelTemplate.attributes.urls.update,
          type: 'PATCH',
          data: {
            label_template: {
              content: this.newContent
            }
          },
          success: (result) => {
            this.labelTemplate.attributes.content = result.data.attributes.content;
            this.editingContent = false;
          }
        });
      });
    },
    saveLabelDimensions() {
      if (this.newLabelWidth == this.labelTemplate.attributes.width_mm
            && this.newLabelHeight == this.labelTemplate.attributes.height_mm
            && this.newLabelDensity == this.labelTemplate.attributes.density
            && this.newLabelUnit == this.labelTemplate.attributes.unit) {
        return;
      }

      $.ajax({
        url: this.labelTemplate.attributes.urls.update,
        type: 'PATCH',
        data: {
          label_template: {
            width_mm: this.newLabelWidth,
            height_mm: this.newLabelHeight,
            density: this.newLabelDensity,
            unit: this.newLabelUnit
          }
        },
        success: (result) => {
          this.labelTemplate.attributes.width_mm = result.data.attributes.width_mm;
          this.labelTemplate.attributes.height_mm = result.data.attributes.height_mm;
          this.labelTemplate.attributes.density = result.data.attributes.density;
          this.labelTemplate.attributes.unit = result.data.attributes.unit;
        }
      });
    },
    generatePreview(skipSave = false) {
      this.skipSave = skipSave;
      if (!skipSave && this.previewContent === this.newContent && this.previewValid) {
        this.updateContent();
      } else {
        this.previewContent = this.newContent;
      }
    },
    invalidPreview() {
      this.previewValid = false;
      this.skipSave = false;
    },
    saveCursorPosition() {
      this.cursorPos = $(this.$refs.contentInput).prop('selectionStart');
    },
    insertTag(tag) {
      this.enableContentEdit();
      const textBefore = this.newContent.substring(0, this.cursorPos);
      const textAfter = this.newContent.substring(this.cursorPos, this.newContent.length);
      this.newContent = textBefore + tag + textAfter;
      this.cursorPos += tag.length;

      this.$nextTick(() => {
        $(this.$refs.contentInput).prop('selectionStart', this.cursorPos);
        $(this.$refs.contentInput).prop('selectionEnd', this.cursorPos);
      });
    },
    showErrors() {
      if (this.editingContent) {
        if (this.newContent.length === 0) {
          this.codeErrorMessage = this.i18n.t('label_templates.show.code_errors.empty');
        } else if (this.newContent.length > 10000) {
          this.codeErrorMessage = this.i18n.t('label_templates.show.code_errors.too_long');
        } else if (!this.previewValid) {
          this.codeErrorMessage = this.i18n.t('label_templates.show.code_errors.invalid');
        } else {
          this.codeErrorMessage = '';
        }
      } else {
        this.codeErrorMessage = '';
      }
    }
  }
};
</script>
