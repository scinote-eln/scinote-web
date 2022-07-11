<template>
  <div class="step-text-container" :class="{ 'edit': inEditMode }" @keyup.enter="enableEditMode($event)" tabindex="0">
    <div v-if="reorderElementUrl" class="element-grip" @click="$emit('reorder')">
      <i class="fas fa-grip-vertical"></i>
    </div>
    <div class="buttons-container">
      <button v-if="element.attributes.orderable.urls.update_url" class="btn icon-btn btn-light" tabindex="-1" @click="enableEditMode($event)">
        <i class="fas fa-pen"></i>
      </button>
      <button v-if="element.attributes.orderable.urls.delete_url" class="btn icon-btn btn-light" @click="showDeleteModal" tabindex="-1">
        <i class="fas fa-trash"></i>
      </button>
    </div>
    <Tinymce
      v-if="element.attributes.orderable.urls.update_url"
      :value="element.attributes.orderable.text"
      :value_html="element.attributes.orderable.text_view"
      :placeholder="i18n.t('protocols.steps.text.placeholder')"
      :updateUrl="element.attributes.orderable.urls.update_url"
      :objectType="'StepText'"
      :objectId="element.attributes.orderable.id"
      :fieldName="'step_text[text]'"
      :lastUpdated="element.attributes.orderable.updated_at"
      @update="update"
      @editingDisabled="disableEditMode"
      @editingEnabled="enableEditMode"
    />
    <div v-else v-html="element.attributes.orderable.text_view"></div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement($event)" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from 'vue/protocol/mixins/components/delete.js'
  import deleteElementModal from 'vue/protocol/modals/delete_element.vue'
  import Tinymce from 'vue/shared/tinymce.vue'

  export default {
    name: 'StepText',
    components: { deleteElementModal, Tinymce },
    mixins: [DeleteMixin],
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
      }
    },
    data() {
      return {
        inEditMode: false,
      }
    },
    mounted() {
      if (this.isNew) {
        this.enableEditMode()
      }
    },
    methods: {
      enableEditMode() {
        if (!this.element.attributes.orderable.urls.update_url) return
        if (this.inEditMode == true) return
        this.inEditMode = true
      },
      disableEditMode() {
        this.inEditMode = false
      },
      update(data) {
        this.element.attributes.orderable.text_view = data.data.attributes.text_view
        this.element.attributes.orderable.text = data.data.attributes.text
        this.element.attributes.orderable.name = data.data.attributes.name
        this.element.attributes.orderable.updated_at = data.data.attributes.updated_at
        this.$emit('update', this.element, true)
      }
    }
  }
</script>
