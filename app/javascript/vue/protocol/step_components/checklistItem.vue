<template>
  <div class="step-checklist-item">
    <div class="step-element-header" :class="{ 'editing-name': editingText }">
      <div class="step-element-grip">
        <i class="fas fa-grip-vertical"></i>
      </div>
      <div class="step-element-name" :class="{ 'done': checklistItem.attributes.checked }">
        <div class="sci-checkbox-container">
          <input ref="checkbox" type="checkbox" class="sci-checkbox" :checked="checklistItem.attributes.checked" @change="toggleChecked" />
          <span class="sci-checkbox-label">
          </span>
        </div>
        <div class="step-checklist-text">
          <InlineEdit
            :value="checklistItem.attributes.text"
            :characterLimit="10000"
            :placeholder="''"
            :allowBlank="true"
            :autofocus="editingText"
            :attributeName="`${i18n.t('ChecklistItem')} ${i18n.t('name')}`"
            :multilinePaste="true"
            @editingEnabled="enableTextEdit"
            @editingDisabled="disableTextEdit"
            @update="updateText"
            @delete="checklistItem.attributes.id ? deleteComponent() : removeItem()"
            @multilinePaste="(data) => { $emit('multilinePaste', data) && removeItem() }"
          />
        </div>
      </div>
      <div class="step-element-controls">
        <button class="btn icon-btn btn-light" @click="enableTextEdit">
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
      checklistItem: {
        type: Object,
        required: true
      }
    },
    data() {
      return {
        editingText: false
      }
    },
    computed: {
      element() { // remap and alias to work with delete mixin
        return { attributes: { orderable: this.checklistItem.attributes } }
      }
    },
    methods: {
      enableTextEdit() {
        this.editingText = true;
      },
      disableTextEdit() {
        this.editingText = false;
      },
      toggleChecked() {
        this.checklistItem.attributes.checked = this.$refs.checkbox.checked;
        this.update();
      },
      updateText(text) {
        if (text.length === 0) {
          this.disableTextEdit();
          this.deleteComponent();
        } else {
          this.checklistItem.attributes.text = text;
          this.update();
        }
      },
      removeItem() {
        this.$emit('removeItem', this.checklistItem);
      },
      update() {
        this.$emit('update', this.checklistItem);
      }
    }
  }
</script>
