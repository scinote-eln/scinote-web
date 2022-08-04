<template>
<div class="content-pane flexible label-templates-show">
  <div class="content-header">
    <div id="breadcrumbsWrapper">
      <div class="breadcrumbs-container">
        <a :href="labelTemplatesUrl" class="breadcrumbs-link">Label templates</a>
        <span class="delimiter">/</span>
      </div>
    </div>
    <div v-if="labelTemplate.id" class="title-row">
      <img :src="labelTemplate.attributes.icon_url" class="label-template-icon"/>
      <InlineEdit
        :value="labelTemplate.attributes.name"
        :characterLimit="255"
        :allowBlank="false"
        :attributeName="`Label template name`"
        :autofocus="editingName"
        @editingEnabled="editingName = true"
        @editingDisabled="editingName = false"
        @update="updateName"
      />
    </div>
  </div>
  <div id="content-label-templates-show">
    <div v-if="labelTemplate.id" class="template-descripiton">
      <div class="title">
        Template description
      </div>
      <InlineEdit
        :value="labelTemplate.attributes.description"
        :characterLimit="255"
        :allowBlank="true"
        :attributeName="`Label template description`"
        :placeholder="`Enter the template description (optional)`"
        :autofocus="editingDescription"
        @editingEnabled="editingDescription = true"
        @editingDisabled="editingDescription = false"
        @update="updateDescription"
      />
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
      labelTemplatesUrl: String
    },
    data() {
      return {
        labelTemplate: {
          attributes: {}
        },
        editingName: false,
        editingDescription: false
      }
    },
    components: {InlineEdit},
    created() {
      $.get(this.labelTemplateUrl, (result) => {
        this.labelTemplate = result.data
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
    }
  }
 </script>
