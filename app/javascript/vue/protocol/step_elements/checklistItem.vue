<template>
  <div class="step-checklist-item" :class="{ 'step-element--locked': !checklistItem.attributes.isNew && !(updateUrl || toggleUrl) }">
    <div class="step-element-header" :class="{ 'locked': locked || editingText, 'editing-name': editingText }">
      <div v-if="reorderChecklistItemUrl" class="step-element-grip step-element-grip--draggable" :class="{ 'step-element-grip--disabled': !draggable }">
        <i class="fas fa-grip-vertical"></i>
      </div>
      <div v-else class="step-element-grip-placeholder"></div>
      <div class="step-element-name" :class="{ 'done': checklistItem.attributes.checked }">
        <div v-if="!inRepository" class="sci-checkbox-container" :class="{ 'disabled': !toggleUrl }">
          <input ref="checkbox"
                 type="checkbox"
                 class="sci-checkbox"
                 :disabled="checklistItem.attributes.isNew"
                 :checked="checklistItem.attributes.checked" @change="toggleChecked($event)" />
          <span class="sci-checkbox-label" >
          </span>
        </div>
        <div v-else class="sci-checkbox-view-mode"></div>
        <div class="step-checklist-text" :class="{ 'step-element--locked': !checklistItem.attributes.isNew && !updateUrl }">
          <InlineEdit
            :value="checklistItem.attributes.text"
            :sa_value="checklistItem.attributes.sa_text"
            :characterLimit="10000"
            :placeholder="'Add a checklist item...'"
            :allowBlank="true"
            :autofocus="editingText"
            :attributeName="`${i18n.t('ChecklistItem')} ${i18n.t('name')}`"
            :multilinePaste="true"
            :editOnload="checklistItem.attributes.isNew"
            :smartAnnotation="true"
            :saveOnEnter="false"
            :allowNewLine="true"
            @editingEnabled="enableTextEdit"
            @editingDisabled="disableTextEdit"
            @update="updateText"
            @delete="removeItem()"
            @multilinePaste="(data) => { $emit('multilinePaste', data) && removeItem() }"
          />
        </div>
      </div>
      <div class="step-element-controls">
        <button v-if="!checklistItem.attributes.urls || updateUrl" class="btn icon-btn btn-light" @click="enableTextEdit" tabindex="0">
          <i class="fas fa-pen"></i>
        </button>
        <button v-if="!checklistItem.attributes.urls || deleteUrl" class="btn icon-btn btn-light" @click="deleteElement" tabindex="0">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
  </div>
</template>

 <script>
  import DeleteMixin from 'vue/protocol/mixins/components/delete.js'
  import InlineEdit from 'vue/shared/inline_edit.vue'

  export default {
    name: 'ChecklistItem',
    components: { InlineEdit },
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
      draggable: {
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
      toggleUrl() {
        if (!this.checklistItem.attributes.urls) return

        return this.checklistItem.attributes.urls.toggle_url;
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
        if (this.checklistItem.attributes.isNew) {
          this.removeItem();
          this.$emit('editEnd');
          this.editingText = false;
          return;
        }
        this.editingText = false;
        this.$emit('editEnd');
      },
      toggleChecked(e) {
        if (!this.toggleUrl) return
        this.checklistItem.attributes.checked = this.$refs.checkbox.checked;
        this.$emit('toggle', this.checklistItem);
      },
      updateText(text) {
        if (text.length === 0) {
          this.disableTextEdit();
          this.removeItem();
        } else {
          this.checklistItem.attributes.text = text;
          this.update();
        }
      },
      removeItem() {
        if (this.deleteUrl) {
          this.deleteElement();
        } else {
          this.$emit('removeItem', this.checklistItem.attributes.position);
        }
      },
      update() {
        this.$emit('update', this.checklistItem);
      }
    }
  }
</script>
