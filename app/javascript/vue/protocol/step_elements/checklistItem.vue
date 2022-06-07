<template>
  <div class="step-checklist-item">
    <div class="step-element-header" :class="{ 'locked': locked || editingText, 'editing-name': editingText }">
      <div v-if="reorderChecklistItemUrl" class="step-element-grip">
        <i class="fas fa-grip-vertical"></i>
      </div>
      <div class="step-element-name" :class="{ 'done': checklistItem.attributes.checked }">
        <div class="sci-checkbox-container" :class="{ 'disabled': !updateUrl || inRepository}">
          <input ref="checkbox"
                 type="checkbox"
                 class="sci-checkbox"
                 :checked="checklistItem.attributes.checked" @change="toggleChecked($event)" />
          <span class="sci-checkbox-label" >
          </span>
        </div>
        <div class="step-checklist-text">
          <InlineEdit
            v-if="!checklistItem.attributes.urls || updateUrl"
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
            @delete="checklistItem.attributes.id ? deleteElement() : removeItem()"
            @multilinePaste="(data) => { $emit('multilinePaste', data) && removeItem() }"
          />
          <span v-else>
            {{ checklistItem.attributes.text }}
          </span>
        </div>
      </div>
      <div class="step-element-controls">
        <button v-if="!checklistItem.attributes.urls || updateUrl" class="btn icon-btn btn-light" @click="enableTextEdit">
          <i class="fas fa-pen"></i>
        </button>
        <button v-if="!checklistItem.attributes.urls || deleteUrl" class="btn icon-btn btn-light" @click="showDeleteModal">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from 'vue/protocol/mixins/components/delete.js'
  import deleteElementModal from 'vue/protocol/modals/delete_element.vue'
  import InlineEdit from 'vue/shared/inline_edit.vue'

  export default {
    name: 'Checklist',
    components: { deleteElementModal, InlineEdit },
    mixins: [DeleteMixin],
    props: {
      checklistItem: {
        type: Object,
        required: true
      },
      locked: {
        type: Boolean,
        default: false
      },
      inRepository: {
        type: Boolean,
        required: true
      },
      reorderChecklistItemUrl: {
        type: String
      }
    },
    data() {
      return {
        editingText: false
      }
    },
    computed: {
      element() { // remap and alias to work with delete mixin
        return({
          attributes: {
            orderable: this.checklistItem.attributes,
            position: this.checklistItem.attributes.position
         }
        });
      },
      updateUrl() {
        if (!this.checklistItem.attributes.urls) return

        return this.checklistItem.attributes.urls.update_url;
      },
      deleteUrl() {
        if (!this.checklistItem.attributes.urls) return

        return this.checklistItem.attributes.urls.delete_url;
      }
    },
    methods: {
      enableTextEdit() {
        this.editingText = true;
        this.$emit('editStart');
      },
      disableTextEdit() {
        this.editingText = false;
        this.$emit('editEnd');
      },
      toggleChecked(e) {
        if (!this.updateUrl) return
        this.checklistItem.attributes.checked = this.$refs.checkbox.checked;
        this.update();
      },
      updateText(text) {
        if (text.length === 0) {
          this.disableTextEdit();
          this.deleteElement();
        } else {
          this.checklistItem.attributes.text = text;
          this.update();
        }
      },
      removeItem() {
        this.$emit('removeItem', this.checklistItem.attributes.position);
      },
      update() {
        this.$emit('update', this.checklistItem);
      }
    }
  }
</script>
