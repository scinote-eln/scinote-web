<template>
  <div class="content__text-container pr-8">
    <div class="sci-divider my-6" v-if="!inRepository"></div>
    <div class="text-header h-9 flex rounded mb-1 items-center relative w-full group/text-header" :class="{ 'editing-name': editingName, 'locked': !element.attributes.orderable.urls.update_url }">
      <div v-if="element.attributes.orderable.urls.update_url || element.attributes.orderable.name"
           class="grow-1 text-ellipsis whitespace-nowrap grow my-1 font-bold"
           :class="{'pointer-events-none': !element.attributes.orderable.urls.update_url}"
           >
        <InlineEdit
          :value="element.attributes.orderable.name"
          :characterLimit="255"
          :placeholder="i18n.t('protocols.steps.text.text_name')"
          :allowBlank="true"
          :autofocus="editingName"
          :attributeName="`${i18n.t('Text')} ${i18n.t('name')}`"
          @editingEnabled="enableNameEdit"
          @editingDisabled="disableNameEdit"
          @update="updateName"
        />
      </div>
      <MenuDropdown
        class="ml-auto"
        :listItems="this.actionMenu"
        :btnClasses="'btn btn-light icon-btn btn-sm'"
        :position="'right'"
        :btnIcon="'sn-icon sn-icon-more-hori'"
        @edit="enableNameEdit"
        @duplicate="duplicateElement"
        @move="showMoveModal"
        @delete="showDeleteModal"
      ></MenuDropdown>
    </div>
    <div class="flex rounded min-h-[2.25rem] mb-4 relative group/text_container content__text-body" :class="{ 'edit': inEditMode, 'component__element--locked': !element.attributes.orderable.urls.update_url }" @keyup.enter="enableEditMode($event)" tabindex="0">
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
        @update="updateText"
        @editingDisabled="disableEditMode"
        @editingEnabled="enableEditMode"
      />
      <div class="view-text-element" v-else-if="element.attributes.orderable.text_view" v-html="wrappedTables"></div>
      <div v-else class="text-sn-grey">
        {{ i18n.t("protocols.steps.text.empty_text") }}
      </div>
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement($event)" @cancel="closeDeleteModal"/>
    <moveElementModal v-if="movingElement"
                      :parent_type="element.attributes.orderable.parent_type"
                      :targets_url="element.attributes.orderable.urls.move_targets_url"
                      @confirm="moveElement($event)" @cancel="closeMoveModal"/>
  </div>
</template>

<script>
import DeleteMixin from './mixins/delete.js';
import MoveMixin from './mixins/move.js';
import DuplicateMixin from './mixins/duplicate.js';
import deleteElementModal from './modal/delete.vue';
import moveElementModal from './modal/move.vue';
import InlineEdit from '../inline_edit.vue';
import Tinymce from '../tinymce.vue';
import MenuDropdown from '../menu_dropdown.vue';

export default {
  name: 'TextContent',
  components: {
    deleteElementModal, Tinymce, moveElementModal, InlineEdit, MenuDropdown
  },
  mixins: [DeleteMixin, DuplicateMixin, MoveMixin],
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
      editingName: false
    };
  },
  mounted() {
    if (this.isNew) {
      this.enableEditMode();
    }
    this.$nextTick(() => {
      const textElements = document.querySelectorAll('.view-text-element');
      if (textElements.length > 0) {
        textElements.forEach((textElement) => {
          this.highlightText(textElement);
        });
      }
    });
  },
  computed: {
    wrappedTables() {
      return window.wrapTables(this.element.attributes.orderable.text_view);
    },
    actionMenu() {
      const menu = [];
      if (this.element.attributes.orderable.urls.update_url) {
        menu.push({
          text: I18n.t('general.edit'),
          emit: 'edit'
        });
      }
      if (this.element.attributes.orderable.urls.duplicate_url) {
        menu.push({
          text: I18n.t('general.duplicate'),
          emit: 'duplicate'
        });
      }
      if (this.element.attributes.orderable.urls.move_targets_url) {
        menu.push({
          text: I18n.t('general.move'),
          emit: 'move'
        });
      }
      if (this.element.attributes.orderable.urls.delete_url) {
        menu.push({
          text: I18n.t('general.delete'),
          emit: 'delete'
        });
      }
      return menu;
    }
  },
  methods: {
    enableEditMode() {
      if (!this.element.attributes.orderable.urls.update_url) return;
      if (this.inEditMode) return;
      this.inEditMode = true;
    },
    disableEditMode() {
      this.inEditMode = false;
    },
    enableNameEdit() {
      this.editingName = true;
    },
    disableNameEdit() {
      this.editingName = false;
    },
    updateName(name) {
      this.element.attributes.orderable.name = name;
      $.ajax({
        url: this.element.attributes.orderable.urls.update_url,
        method: 'PUT',
        data: { text_component: { name } }
      });
      this.$emit('update', this.element, true);
    },
    updateText(data) {
      this.element.attributes.orderable.text_view = data.attributes.text_view;
      this.element.attributes.orderable.text = data.attributes.text;
      this.element.attributes.orderable.name = data.attributes.name;
      this.element.attributes.orderable.updated_at = data.attributes.updated_at;
      this.$emit('update', this.element, true);
    },
    highlightText(textElToHighlight) {
      Prism.highlightAllUnder(textElToHighlight);
    }
  }
};
</script>
