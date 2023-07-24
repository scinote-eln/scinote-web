<template>
  <div class="content__checklist-item">
    <div class="checklist-item-header flex rounded pl-10 mb-1 items-center relative w-full group/checklist-item-header" :class="{ 'locked': locked || editingText, 'editing-name': editingText }">
      <div v-if="reorderChecklistItemUrl"
        class="absolute items-center h-full cursor-grab justify-center left-0 p-2 tw-hidden text-sn-grey element-grip step-element-grip--draggable"
        :class="{ 'group-hover/checklist-item-header:flex': (!locked && !editingText && draggable) }"
      >
        <i class="sn-icon sn-icon-drag"></i>
      </div>
      <div class="flex items-start gap-2 grow" :class="{ 'done': checklistItem.attributes.checked }">
        <div v-if="!inRepository" class="sci-checkbox-container my-2.5 w-6" :class="{ 'disabled': !toggleUrl }">
          <input ref="checkbox"
                 type="checkbox"
                 class="sci-checkbox"
                 :disabled="checklistItem.attributes.isNew"
                 :checked="checklistItem.attributes.checked" @change="toggleChecked($event)" />
          <span class="sci-checkbox-label" >
          </span>
        </div>
        <div v-else class="w-6"></div>
        <div class="whitespace-nowrap text-ellipsis overflow-hidden grow" :class="{ 'pointer-events-none': !checklistItem.attributes.isNew && !updateUrl }">
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
      <div class="items-center gap-2 tw-hidden group-hover/checklist-item-header:flex">
        <button v-if="!checklistItem.attributes.urls || updateUrl" class="btn icon-btn btn-light  btn-sm" @click="enableTextEdit" tabindex="0">
          <i class="sn-icon sn-icon-edit"></i>
        </button>
        <button v-if="!checklistItem.attributes.urls || deleteUrl" class="btn icon-btn btn-light  btn-sm" @click="showDeleteModal" tabindex="0">
          <i class="sn-icon sn-icon-delete"></i>
        </button>
      </div>
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from './mixins/delete.js'
  import InlineEdit from '../inline_edit.vue'
  import deleteElementModal from './modal/delete.vue'

  export default {
    name: 'ChecklistItem',
    components: { InlineEdit, deleteElementModal },
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
