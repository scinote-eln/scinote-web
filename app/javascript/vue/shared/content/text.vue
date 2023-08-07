<template>
  <div class="content__text-container flex rounded pl-10 mb-4 relative w-full group/text_container" :class="{ 'edit': inEditMode, 'component__element--locked': !element.attributes.orderable.urls.update_url }" @keyup.enter="enableEditMode($event)" tabindex="0">
    <div v-if="reorderElementUrl"
         class="absolute items-center h-full justify-center left-0 p-2 tw-hidden text-sn-grey"
         :class="{ 'group-hover/text_container:flex': !inEditMode }"
         @click="$emit('reorder')"
    >
      <i class="sn-icon sn-icon-sort"></i>
    </div>
    <div v-else class="flex-none"></div>
    <div class="bg-sn-light-grey rounded absolute right-0 flex z-10 tw-hidden" :class="{ 'group-hover/text_container:flex': !inEditMode && element.attributes.orderable.urls.update_url }">
      <button v-if="element.attributes.orderable.urls.update_url" class="btn icon-btn btn-light btn-sm" tabindex="0" @click="enableEditMode($event)">
        <i class="sn-icon sn-icon-edit"></i>
      </button>
      <button v-if="element.attributes.orderable.urls.duplicate_url" class="btn icon-btn btn-light btn-sm" tabindex="0" @click="duplicateElement">
        <i class="sn-icon sn-icon-duplicate"></i>
      </button>
      <button v-if="element.attributes.orderable.urls.delete_url" class="btn icon-btn btn-light btn-sm" @click="showDeleteModal" tabindex="0">
        <i class="sn-icon sn-icon-delete"></i>
      </button>
    </div>
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
      @update="update"
      @editingDisabled="disableEditMode"
      @editingEnabled="enableEditMode"
    />
    <div class="view-text-element" v-else-if="element.attributes.orderable.text_view" v-html="element.attributes.orderable.text_view"></div>
    <div v-else class="text-sn-grey">
      {{ i18n.t("protocols.steps.text.empty_text") }}
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement($event)" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from './mixins/delete.js'
  import DuplicateMixin from './mixins/duplicate.js'
  import deleteElementModal from './modal/delete.vue'
  import Tinymce from '../tinymce.vue'

  export default {
    name: 'TextContent',
    components: { deleteElementModal, Tinymce },
    mixins: [DeleteMixin, DuplicateMixin],
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
      update(data) {
        this.element.attributes.orderable.text_view = data.attributes.text_view
        this.element.attributes.orderable.text = data.attributes.text
        this.element.attributes.orderable.name = data.attributes.name
        this.element.attributes.orderable.updated_at = data.attributes.updated_at
        this.$emit('update', this.element, true)
      }
    }
  }
</script>