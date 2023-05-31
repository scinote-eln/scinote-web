<template>
  <div class="step-text-container" :class="{ 'edit': inEditMode, 'step-element--locked': !element.attributes.orderable.urls.update_url }" @keyup.enter="enableEditMode($event)" tabindex="0">
    <div v-if="reorderElementUrl" class="step-element-grip" @click="$emit('reorder')">
      <i class="fas fas-rotated-90 fa-exchange-alt"></i>
    </div>
    <div v-else class="step-element-grip-placeholder"></div>
    <div class="buttons-container">
      <button v-if="element.attributes.orderable.urls.update_url" class="btn icon-btn btn-light" tabindex="0" @click="enableEditMode($event)">
        <i class="fas fa-pen"></i>
      </button>
      <button v-if="element.attributes.orderable.urls.duplicate_url" class="btn icon-btn btn-light" tabindex="0" @click="duplicateElement">
        <i class="fas fa-clone"></i>
      </button>
      <button v-if="element.attributes.orderable.urls.delete_url" class="btn icon-btn btn-light" @click="showDeleteModal" tabindex="0">
        <i class="fas fa-trash"></i>
      </button>
    </div>
    <Tinymce
      v-if="element.attributes.orderable.urls.update_url"
      :value="element.attributes.orderable.text"
      :value_html="element.attributes.orderable.text_view"
      :placeholder="element.attributes.orderable.placeholder"
      :inEditMode="inEditMode || isNew"
      :updateUrl="element.attributes.orderable.urls.update_url"
      :objectType="'StepText'"
      :objectId="element.attributes.orderable.id"
      :fieldName="'step_text[text]'"
      :lastUpdated="element.attributes.orderable.updated_at"
      :assignableMyModuleId="assignableMyModuleId"
      :characterLimit="1000000"
      @update="update"
      @editingDisabled="disableEditMode"
      @editingEnabled="enableEditMode"
    />
    <div class="view-text-element" v-else-if="element.attributes.orderable.text_view" v-html="element.attributes.orderable.text_view"></div>
    <div v-else class="empty-text-element">
      {{ i18n.t("protocols.steps.text.empty_text") }}
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement($event)" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from '../mixins/components/delete.js'
  import DuplicateMixin from '../mixins/components/duplicate.js'
  import deleteElementModal from '../modals/delete_element.vue'
  import Tinymce from '../../shared/tinymce.vue'

  export default {
    name: 'StepText',
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
