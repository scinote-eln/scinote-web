<template>
  <div class="step-checklist-container">
    <div class="step-element-header" :class="{ 'editing-name': editingName }">
      <div class="step-element-grip">
        <i class="fas fa-grip-vertical"></i>
      </div>
      <div class="step-element-name">
        <InlineEdit
          :value="element.attributes.orderable.name"
          :characterLimit="255"
          :placeholder="''"
          :allowBlank="false"
          :autofocus="editingName"
          :attributeName="`${i18n.t('Checklist')} ${i18n.t('name')}`"
          @editingEnabled="enableNameEdit"
          @editingDisabled="disableNameEdit"
          @update="updateName"
        />
      </div>
      <div class="step-element-controls">
        <button class="btn icon-btn btn-light" @click="enableNameEdit">
          <i class="fas fa-pen"></i>
        </button>
        <button class="btn icon-btn btn-light" @click="showDeleteModal">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <deleteComponentModal v-if="confirmingDelete" @confirm="deleteComponent" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from 'vue/protocol/mixins/components/delete.js'
  import deleteComponentModal from 'vue/protocol/modals/delete_component.vue'
  import InlineEdit from 'vue/shared/inline_edit.vue'

  export default {
    name: 'Checklist',
    components: { deleteComponentModal, InlineEdit },
    mixins: [DeleteMixin],
    props: {
      element: {
        type: Object,
        required: true
      }
    },
    data() {
      return {
        editingName: false
      }
    },
    methods: {
      enableNameEdit() {
        this.editingName = true;
      },
      disableNameEdit() {
        this.editingName = false;
      },
      updateName(name) {
        this.element.attributes.orderable.name = name;
        this.update();
      },
      update() {
        this.$emit('update', this.element)
      }
    }
  }
</script>
