<template>
  <div class="content__text-container">
    <div class="text-header h-9 flex rounded pl-8 mb-1 items-center relative w-full group/text-header" :class="{ 'editing-name': editingName, 'locked': !element.attributes.orderable.urls.update_url }">
      <div v-if="reorderElementUrl"
          class="absolute items-center h-full justify-center left-0 p-2 tw-hidden text-sn-grey"
          :class="{ 'group-hover/text-header:flex': !inEditMode }"
          @click="$emit('reorder')">
        <i class="sn-icon sn-icon-sort"></i>
      </div>

      <div v-if="element.attributes.orderable.urls.update_url || element.attributes.orderable.name"
           class="grow-1 text-ellipsis whitespace-nowrap grow my-1 font-bold">
        <InlineEdit
          :value="element.attributes.orderable.name"
          :characterLimit="255"
          :placeholder="i18n.t('protocols.steps.text.text_name')"
          :allowBlank="true"
          :autofocus="editingName"
          :attributeName="`${i18n.t('Text')} ${i18n.t('name')}`"
          @editingEnabled="enableNameEdit"
          @editingDisabled="disableNameEdit"
          @update="updateName"
        />
      </div>
      <div class="tw-hidden group-hover/text-header:flex items-center gap-2 ml-auto" >
        <button v-if="element.attributes.orderable.urls.update_url" class="btn icon-btn btn-light" @click="enableNameEdit" tabindex="0">
          <i class="sn-icon sn-icon-edit"></i>
        </button>
        <button v-if="element.attributes.orderable.urls.duplicate_url" class="btn icon-btn btn-light" tabindex="0" @click="duplicateElement">
          <i class="sn-icon sn-icon-duplicate"></i>
        </button>
        <button v-if="element.attributes.orderable.urls.move_targets_url" class="btn btn-light btn-sm" tabindex="0" @click="showMoveModal">
          Move
        </button>
        <button v-if="element.attributes.orderable.urls.delete_url" class="btn icon-btn btn-light" @click="showDeleteModal" tabindex="0">
          <i class="sn-icon sn-icon-delete"></i>
        </button>
      </div>
    </div>
    <div class="flex rounded ml-8 pl-1 min-h-[2.25rem] mb-4 relative w-full group/text_container content__text-body" :class="{ 'edit': inEditMode, 'component__element--locked': !element.attributes.orderable.urls.update_url }" @keyup.enter="enableEditMode($event)" tabindex="0">
      <Tinymce
        v-if="element.attributes.orderable.urls.update_url"
        :value="element.attributes.orderable.text"
        :value_html="element.attributes.orderable.text_view"
        :placeholder="element.attributes.orderable.placeholder"
        :inEditMode="inEditMode || isNew"
        :updateUrl="element.attributes.orderable.urls.update_url"
        :objectType="'TextContent'"
        :objectId="element.attributes.orderable.id"
        :fieldName="'text_component[text]'"
        :lastUpdated="element.attributes.orderable.updated_at"
        :assignableMyModuleId="assignableMyModuleId"
        :characterLimit="1000000"
        @update="updateText"
        @editingDisabled="disableEditMode"
        @editingEnabled="enableEditMode"
      />
      <div class="view-text-element" v-else-if="element.attributes.orderable.text_view" v-html="element.attributes.orderable.text_view"></div>
      <div v-else class="text-sn-grey">
        {{ i18n.t("protocols.steps.text.empty_text") }}
      </div>
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement($event)" @cancel="closeDeleteModal"/>
    <moveElementModal v-if="movingElement"
                      :parent_type="element.attributes.orderable.parent_type"
                      :targets_url="element.attributes.orderable.urls.move_targets_url"
                      @confirm="moveElement($event)" @cancel="closeMoveModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from './mixins/delete.js'
  import MoveMixin from './mixins/move.js'
  import DuplicateMixin from './mixins/duplicate.js'
  import deleteElementModal from './modal/delete.vue'
  import moveElementModal from './modal/move.vue'
  import InlineEdit from '../inline_edit.vue'
  import Tinymce from '../tinymce.vue'

  export default {
    name: 'TextContent',
    components: { deleteElementModal, Tinymce, moveElementModal, InlineEdit },
    mixins: [DeleteMixin, DuplicateMixin, MoveMixin],
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
      isNew: {
        type: Boolean,
        default: false
      },
      assignableMyModuleId: {
        type: Number,
        required: false
      }
    },
    data() {
      return {
        inEditMode: false,
        editingName: false,
      }
    },
    mounted() {
      if (this.isNew) {
        this.enableEditMode();
      }
    },
    methods: {
      enableEditMode() {
        if (!this.element.attributes.orderable.urls.update_url) return
        if (this.inEditMode) return
        this.inEditMode = true
      },
      disableEditMode() {
        this.inEditMode = false
      },
      enableNameEdit() {
        this.editingName = true;
      },
      disableNameEdit() {
        this.editingName = false;
      },
      updateName(name) {
        this.element.attributes.orderable.name = name;
        $.ajax({
          url: this.element.attributes.orderable.urls.update_url,
          method: 'PUT',
          data: { text_component: {name: name} }
        })
        this.$emit('update', this.element, true)
      },
      updateText(data) {
        this.element.attributes.orderable.text_view = data.attributes.text_view
        this.element.attributes.orderable.text = data.attributes.text
        this.element.attributes.orderable.name = data.attributes.name
        this.element.attributes.orderable.updated_at = data.attributes.updated_at
        this.$emit('update', this.element, true)
      }
    }
  }
</script>