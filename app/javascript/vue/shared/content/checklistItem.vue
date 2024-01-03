<template>
  <div class="content__checklist-item pl-10 ml-[-2.325rem]">
    <div class="checklist-item-header flex rounded items-center relative w-full group/checklist-item-header" :class="{ 'locked': locked || editingText, 'editing-name': editingText }">
      <div v-if="reorderChecklistItemUrl"
        class="absolute h-6 cursor-grab justify-center left-[-2.325rem] top-0.5 px-2 tw-hidden text-sn-grey element-grip step-element-grip--draggable"
        :class="{ 'group-hover/checklist-item-header:flex': (!locked && !editingText && draggable) }"
      >
        <i class="sn-icon sn-icon-drag"></i>
      </div>
      <div class="flex items-start gap-2 grow" :class="{ 'done': checklistItem.attributes.checked }">
        <div v-if="!inRepository" class="sci-checkbox-container my-1.5 border-0 border-y border-transparent border-solid" :class="{ 'disabled': !toggleUrl }"  :style="toggleUrl && 'pointer-events: initial'">
          <input ref="checkbox"
                 type="checkbox"
                 class="sci-checkbox"
                 :disabled="checklistItem.attributes.isNew"
                 :checked="checklistItem.attributes.checked" @change="toggleChecked($event)" />
          <span class="sci-checkbox-label" >
          </span>
        </div>
        <div v-else class="h-1 w-1 bg-sn-black rounded-full mt-auto mb-auto"></div>
        <div class="pr-24 relative flex items-start max-w-[90ch]"
             :class="{
              'pointer-events-none': !checklistItem.attributes.isNew && !updateUrl,
              'flex-grow': editingText,
             }">
          <InlineEdit
            :class="{ 'pointer-events-none': reordering }"
            :value="checklistItem.attributes.text"
            :sa_value="checklistItem.attributes.sa_text"
            :characterLimit="10000"
            :placeholder="'Add a checklist item...'"
            :allowBlank="true"
            :singleLine="false"
            :autofocus="editingText"
            :attributeName="`${i18n.t('ChecklistItem')} ${i18n.t('name')}`"
            :editOnload="checklistItem.attributes.isNew"
            :smartAnnotation="true"
            @editingEnabled="enableTextEdit"
            @editingDisabled="disableTextEdit"
            @update="updateText"
            @delete="removeItem()"
            @keypress="keyPressHandler"
            @blur="onBlurHandler"
          />
          <span v-if="!editingText && (!checklistItem.attributes.urls || deleteUrl)" class="absolute right-0 top-0.5 leading-6 tw-hidden group-hover/checklist-item-header:inline-block !text-sn-blue cursor-pointer" @click="showDeleteModal" tabindex="0">
            <i class="sn-icon sn-icon-delete"></i>
          </span>
        </div>
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
      },
      reordering: {
        type: Boolean,
        required: true
      }
    },
    data() {
      return {
        editingText: false,
        deleting: false
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
          if (this.deleting) return

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
      onBlurHandler() {
        this.$nextTick(() => {
          this.editingText = false;
        });
      },
      updateText(text, withKey) {
        if (text.length === 0) {
          this.disableTextEdit();
        } else {
          this.checklistItem.attributes.text = text;
          this.update(withKey);
        }
      },
      removeItem() {
        this.deleting = true;
        if (this.deleteUrl) {
          this.deleteElement();
        } else {
          this.$emit('removeItem', this.checklistItem.attributes.position);
        }
      },
      update(withKey) {
        this.$emit('update', this.checklistItem, withKey);
      },
      keyPressHandler(e) {
        if (e.key === 'Enter' && e.shiftKey) {
          this.checklistItem.attributes.with_paragraphs = true;
        }
      },
    }
  }
</script>
