<template>
  <div :class="`step-text-container ${inEditMode ? 'edit' : ''}`">
    <div class="action-container" @click="enableEditMode">
      <div class="element-grip">
        <i class="fas fa-grip-vertical"></i>
      </div>
      <div class="buttons-container">
        <button class="btn icon-btn btn-light">
          <i class="fas fa-pen"></i>
        </button>
        <button class="btn icon-btn btn-light" @click="showDeleteModal">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <Tinymce
      :inEditMode="inEditMode"
      :value="element.attributes.orderable.text"
      :value_html="element.attributes.orderable.text_view"
      :placeholder="'Enter step text'"
      :updateUrl="element.attributes.orderable.urls.update_url"
      :objectType="'StepText'"
      :objectId="element.attributes.orderable.id"
      :fieldName="'step_text[text]'"
      :lastUpdated="element.attributes.orderable.updated_at"
      @update="update"
      @editingDisabled="disableEditMode"
    />
    <deleteComponentModal v-if="confirmingDelete" @confirm="deleteComponent(event)" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from 'vue/protocol/mixins/components/delete.js'
  import deleteComponentModal from 'vue/protocol/modals/delete_component.vue'
  import Tinymce from 'vue/shared/tinymce.vue'

  export default {
    name: 'StepText',
    components: { deleteComponentModal, Tinymce },
    mixins: [DeleteMixin],
    props: {
      element: {
        type: Object,
        required: true
      }
    },
    data() {
      return {
        inEditMode: false,
      }
    },
    methods: {
      enableEditMode() {
        this.inEditMode = true
      },
      disableEditMode() {
        this.inEditMode = false
      },
      update(data) {
        this.element.attributes.orderable.text_view = data.data.attributes.text_view
        this.element.attributes.orderable.text = data.data.attributes.text
        this.element.attributes.orderable.udpated_at = data.data.attributes.udpated_at
        this.$emit('update', this.element, true)
      }
    }
  }
</script>
