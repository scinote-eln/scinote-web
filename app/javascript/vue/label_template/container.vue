<template>
<div class="content-pane flexible label-templates-show">
  <div class="content-header">
    <div id="breadcrumbsWrapper">
      <div class="breadcrumbs-container">
        <a :href="labelTemplatesUrl" class="breadcrumbs-link">
          {{ i18n.t('label_templates.show.breadcrumb_index') }}
        </a>
        <span class="delimiter">/</span>
      </div>
    </div>
    <div v-if="labelTemplate.id" class="title-row">
      <img :src="labelTemplate.attributes.icon_url" class="label-template-icon"/>
      <InlineEdit
        :value="labelTemplate.attributes.name"
        :characterLimit="255"
        :allowBlank="false"
        :attributeName="i18n.t('label_templates.show.name_error_prefix')"
        :autofocus="editingName"
        :editOnload="newLabel"
        @editingEnabled="editingName = true"
        @editingDisabled="editingName = false"
        @update="updateName"
      />
    </div>
  </div>
  <div id="content-label-templates-show">
    <div v-if="labelTemplate.id" class="template-descripiton">
      <div class="title">
        {{ i18n.t('label_templates.show.description_title') }}
      </div>
      <InlineEdit
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
    </div>

    <div v-if="labelTemplate.id" class="label-template-container">
      <div class="label-edit-container">
        <div class="title">
          {{ i18n.t('label_templates.show.content_title', { format: labelTemplate.attributes.language_type.toUpperCase() }) }}
        </div>
        <template v-if="editingContent">
          <div class="label-textarea-container">
            <textarea
              ref="contentInput"
              v-model="newContent"
              class="label-textarea"
              @blur="updateContent"
            ></textarea>
          </div>
          <div class="button-container">
            <div class="btn btn-secondary refresh-preview">
              <i class="fas fa-sync"></i>
              {{ i18n.t('label_templates.show.buttons.refresh') }}
            </div>
            <div class="btn btn-secondary" @click="editingContent = false">
              {{ i18n.t('general.cancel') }}
            </div>
            <div class="btn btn-primary save-template" @click="updateContent">
              <i class="fas fa-save"></i>
              {{ i18n.t('label_templates.show.buttons.save') }}
            </div>
          </div>
        </template>
        <div v-else class="label-view-container" :title="i18n.t('label_templates.show.view_content_tooltip')" @click="editingContent = true">{{ labelTemplate.attributes.content}}
          <i class="fas fa-pen"></i>
        </div>
      </div>

      <div class="label-preview-container">
        <div class="title">
          {{ i18n.t('label_templates.show.preview_title') }}
        </div>
      </div>
    </div>
  </div>
</div>
</template>

 <script>

 import InlineEdit from 'vue/shared/inline_edit.vue'

  export default {
    name: 'LabelTemplateContainer',
    props: {
      labelTemplateUrl: String,
      labelTemplatesUrl: String,
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
        newContent: ''
      }
    },
    components: {InlineEdit},
    created() {
      console.log(this.newLabel)
      $.get(this.labelTemplateUrl, (result) => {
        this.labelTemplate = result.data
        this.newContent = this.labelTemplate.attributes.content
      })
    },
    methods: {
      updateName(newName) {
        $.ajax({
          url: this.labelTemplate.attributes.urls.update,
          type: 'PATCH',
          data: {label_template: {name: newName}},
          success: (result) => {
            this.labelTemplate.attributes.name = result.data.attributes.name
          }
        });
      },
      updateDescription(newDescription) {
        $.ajax({
          url: this.labelTemplate.attributes.urls.update,
          type: 'PATCH',
          data: {label_template: {description: newDescription}},
          success: (result) => {
            this.labelTemplate.attributes.description = result.data.attributes.description
          }
        });
      },
      updateContent() {
        $.ajax({
          url: this.labelTemplate.attributes.urls.update,
          type: 'PATCH',
          data: {label_template: {content: this.newContent}},
          success: (result) => {
            this.labelTemplate.attributes.content = result.data.attributes.content
            this.editingContent = false
          }
        });
      },
    }
  }
 </script>
