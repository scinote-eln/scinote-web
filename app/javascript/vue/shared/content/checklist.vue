<template>
  <div class="content__checklist-container pr-8" :data-e2e="`e2e-CO-${dataE2e}-checklist${element.id}`">
    <div class="sci-divider my-6" v-if="!inRepository"></div>
    <div :class="{'!bg-sn-background-brittlebush p-4': element.attributes.orderable.archived}">
      <div class="checklist-header flex rounded gap-2 mb-1 items-center relative w-full group/checklist-header"
        :class="{ 'editing-name': editingName, 'locked': !element.attributes.orderable.urls.update_url }">
        <div class="grow-1 text-ellipsis whitespace-nowrap my-1 font-bold" :class="{ 'grow': !element.attributes.orderable.archived }">
          <InlineEdit
            :class="{ 'pointer-events-none': !element.attributes.orderable.urls.update_url }"
            :value="element.attributes.orderable.name"
            :sa_value="element.attributes.orderable.sa_name"
            :characterLimit="10000"
            :placeholder="i18n.t('protocols.steps.checklist.placeholder')"
            :allowBlank="false"
            :autofocus="editingName"
            :smartAnnotation="true"
            :attributeName="`${i18n.t('Checklist')} ${i18n.t('name')}`"
            :dataE2e="`${dataE2e}-checklist${element.id}`"
            @editingEnabled="editingName = true"
            @editingDisabled="editingName = false"
            @update="updateName"
          />
        </div>
        <template v-if="element.attributes.orderable.archived">
          <div class="sci-tag bg-sn-alert-brittlebush pointer-events-none text-sn-black">
            {{ i18n.t('my_modules.results.archived') }}
            <span class="sn-icon sn-icon-archived"></span>
          </div>
          <span class="text-xs ">
            {{ i18n.t('protocols.steps.timestamp_archived', {
              date: element.attributes.orderable.archived_on,
              user: element.attributes.orderable.archived_by
            }) }}
          </span>
        </template>
        <LockedTag v-if="element.attributes.orderable.locked" />
        <div class="ml-auto flex items gap-4">
          <button
            v-if="this.element.attributes.orderable.urls.restore_url"
            :class="['btn icon-btn btn-light', `e2e-BT-${this.e2eClass}-checklist-options-restore`]"
            @click="confirmingRestore = true"
            :title="i18n.t('general.restore')"
            :data-e2e="`e2e-BT-${this.dataE2e}-checklist${this.element.id}-options-restore`"
          >
            <i class="sn-icon sn-icon-restore"></i>
          </button>
          <button
            v-if="this.element.attributes.orderable.archived && this.element.attributes.orderable.urls.delete_url"
            :class="['btn icon-btn btn-light', `e2e-BT-${this.e2eClass}-checklist-options-delete`]"
            @click="showDeleteModal"
            :title="i18n.t('general.delete')"
            :data-e2e="`e2e-BT-${this.dataE2e}-checklist${this.element.id}-options-delete`"
          >
            <i class="sn-icon sn-icon-delete"></i>
          </button>
          <button v-if="this.element.attributes.orderable.locked" class="btn btn-light icon-btn !pointer-events-auto" :data-sn-tooltip="i18n.t('protocols.action_disabled')" disabled>
            <i class="sn-icon sn-icon-more-hori"></i>
          </button>
          <MenuDropdown v-else
            class="ml-auto"
            :listItems="this.actionMenu"
            :btnClasses="'btn btn-light icon-btn  btn-sm'"
            :position="'right'"
            :btnIcon="'sn-icon sn-icon-more-hori'"
            :dataE2e="`e2e-DD-${dataE2e}-checklist${element.id}-options`"
            @edit="editingName = true"
            @duplicate="duplicateElement"
            @move="showMoveModal"
            @delete="showDeleteModal"
            @archive="archiveElement"
          ></MenuDropdown>
        </div>
      </div>
      <div v-if="element.attributes.orderable.urls.create_item_url || checklistItems.length > 0" :class="{ 'pointer-events-none': locked }">
        <Draggable
          v-model="checklistItems"
          :ghostClass="'checklist-item-ghost'"
          :dragClass="'checklist-item-drag'"
          :chosenClass="'checklist-item-chosen'"
          :forceFallback="true"
          :handle="'.element-grip'"
          item-key="id"
          :disabled="editingItem || checklistItems.length < 2 || !element.attributes.orderable.urls.reorder_url"
          @start="startReorder"
          @end="endReorder"
        >
          <template #item="{element}">
            <ChecklistItem
              :checklistItem="element"
              :locked="locked"
              :reordering="reordering"
              :reorderChecklistItemUrl="this.element.attributes.orderable.urls.reorder_url"
              :inRepository="inRepository"
              :draggable="checklistItems.length > 1"
              :data-e2e="`${dataE2e}-checklistItem${element.id}`"
              :class="{
                'select-none': reordering
              }"
              @editStart="editingItem = true"
              @editEnd="editingItem = false"
              @update="saveItem"
              @toggle="saveItemChecked"
              @removeItem="removeItem"
              @component:delete="removeItem"
            />
          </template>
        </Draggable>
        <div v-if="element.attributes.orderable.urls.create_item_url && !addingNewItem"
            class="flex items-center gap-1 text-sn-blue cursor-pointer mb-2 mt-1 "
            tabindex="0"
            :data-e2e="`e2e-BT-${dataE2e}-checklist${element.id}-addNew`"
            @keyup.enter="addItem(checklistItems[checklistItems.length - 1]?.id)"
            @click="addItem(checklistItems[checklistItems.length - 1]?.id)">
          <i class="sn-icon sn-icon-new-task w-6 text-center inline-block"></i>
          {{ i18n.t('protocols.steps.insert.checklist_item') }}
        </div>
      </div>
      <div v-else class="text-sn-grey ml-12">
        {{ i18n.t("protocols.steps.checklist.empty_checklist") }}
      </div>
    </div>
    <deleteElementModal v-if="confirmingDelete" :inRepository="inRepository" @confirm="deleteElement" @close="closeDeleteModal"/>
    <RestoreModal v-if="confirmingRestore"
                  :parentType="element.attributes.orderable.parent_type"
                  :element="'checklist'"
                  @confirm="restoreElement"
                  @close="confirmingRestore = false"/>
    <moveElementModal v-if="movingElement"
                      :parent_type="element.attributes.orderable.parent_type"
                      :targets_url="element.attributes.orderable.urls.move_targets_url"
                      @confirm="moveElement($event)" @cancel="closeMoveModal"/>
  </div>
</template>

<script>

/* global HelperModule I18n */

import Draggable from 'vuedraggable';
import DeleteMixin from './mixins/delete.js';
import MoveMixin from './mixins/move.js';
import DuplicateMixin from './mixins/duplicate.js';
import deleteElementModal from './modal/delete.vue';
import InlineEdit from '../inline_edit.vue';
import ChecklistItem from './checklistItem.vue';
import moveElementModal from './modal/move.vue';
import MenuDropdown from '../menu_dropdown.vue';
import ArchiveMixin from './mixins/archive.js';
import RestoreModal from './modal/restore_element.vue';
import axios from '../../../packs/custom_axios.js';
import tooltipMixin from '../../mixins/tooltipMixin.js';
import LockedTag from '../snippets/locked_tag.vue';

export default {
  name: 'Checklist',
  components: {
    deleteElementModal, InlineEdit, ChecklistItem, Draggable, moveElementModal, MenuDropdown, RestoreModal, LockedTag
  },
  mixins: [DeleteMixin, DuplicateMixin, MoveMixin, ArchiveMixin, tooltipMixin],
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
    },
    dataE2e: {
      type: String,
      default: ''
    },
    e2eClass: {
      type: String,
      default: ''
    }
  },
  data() {
    return {
      checklistItems: [],
      editingName: false,
      reordering: false,
      editingItem: false,
      confirmingRestore: false
    };
  },
  created() {
    if (this.isNew) {
      this.addItem();
    } else {
      this.checklistItems = this.element.attributes.orderable.checklist_items.map((item) => ({
        id: item.id,
        attributes: {
          ...item,
        }
      }));
    }
  },
  watch: {
    element() {
      this.loadChecklistItems();
    }
  },
  computed: {
    locked() {
      return this.editingName || !this.element.attributes.orderable.urls.update_url || this.element.attributes.orderable.archived;
    },
    addingNewItem() {
      return this.checklistItems.find((item) => item.attributes.isNew);
    },
    actionMenu() {
      const menu = [];
      if (this.element.attributes.orderable.urls.update_url) {
        menu.push({
          text: I18n.t('general.edit'),
          emit: 'edit',
          data_e2e: `e2e-BT-${this.dataE2e}-checklist${this.element.id}-options-edit`,
          e2e_class: `e2e-BT-${this.e2eClass}-checklist-options-edit`
        });
      }
      if (this.element.attributes.orderable.urls.duplicate_url) {
        menu.push({
          text: I18n.t('general.duplicate'),
          emit: 'duplicate',
          data_e2e: `e2e-BT-${this.dataE2e}-checklist${this.element.id}-options-duplicate`,
          e2e_class: `e2e-BT-${this.e2eClass}-checklist-options-duplicate`
        });
      }
      if (this.element.attributes.orderable.urls.move_targets_url) {
        menu.push({
          text: I18n.t('general.move'),
          emit: 'move',
          data_e2e: `e2e-BT-${this.dataE2e}-checklist${this.element.id}-options-move`,
          e2e_class: `e2e-BT-${this.e2eClass}-checklist-options-move`
        });
      }
      if (!this.element.attributes.orderable.archived && this.element.attributes.orderable.urls.delete_url) {
        menu.push({
          text: I18n.t('general.delete'),
          emit: 'delete',
          data_e2e: `e2e-BT-${this.dataE2e}-checklist${this.element.id}-options-delete`,
          e2e_class: `e2e-BT-${this.e2eClass}-checklist-options-delete`
        });
      }

      if (this.element.attributes.orderable.urls.archive_url) {
        menu.push({
          text: I18n.t('general.archive'),
          emit: 'archive',
          data_e2e: `e2e-BT-${this.dataE2e}-checklist${this.element.id}-options-archive`,
          e2e_class: `e2e-BT-${this.e2eClass}-checklist-options-archive`
        });
      }
      return menu;
    }
  },
  methods: {
    update() {
      this.$emit('update', this.element, false);
    },
    updatedChecklistItem() {
      this.$emit('update', this.element, true);
    },
    loadChecklistItems(insertAfter) {
      axios.get(this.element.attributes.orderable.urls.checklist_items_url).then((response) => {
        this.checklistItems = response.data.data;
        if (insertAfter) {
          this.addItem(insertAfter);
        }
      });
    },
    updateName(name) {
      this.element.attributes.orderable.name = name;
      this.editingName = false;
      this.update();
    },
    postItem(item) {
      const position = this.checklistItems.findIndex((i) => i.id === item.id);
      let afterId = null;
      if (position > 0) {
        afterId = this.checklistItems[position - 1].id;
      }
      axios.post(this.element.attributes.orderable.urls.create_item_url, {
        attributes: item.attributes,
        after_id: afterId
      }).then((result) => {
        this.loadChecklistItems(result.data.data[result.data.data.length - 1].id);
        this.updatedChecklistItem();
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    saveItem(item, key) {
      if (item.id > 0) {
        const insertAfter = key === 'Enter' ? item.id : null;
        axios.patch(item.attributes.urls.update_url, item).then(() => {
          this.loadChecklistItems(insertAfter);
          this.updatedChecklistItem();
        }).catch((error) => this.setFlashErrors(error.response.data.errors));
      } else {
        this.postItem(item, key);
      }
    },
    saveItemChecked(item) {
      axios.patch(item.attributes.urls.toggle_url, { attributes: { checked: item.attributes.checked } }).then((response) => {
        this.checklistItems.find(
          (i) => i.id === item.id
        ).attributes.checked = response.data.data.attributes.checked;
      }).catch((e) => HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger'));
    },
    addItem(insertAfter) {
      const afterIndex = this.checklistItems.findIndex((i) => i.id === insertAfter);
      this.checklistItems.splice(
        afterIndex + 1,
        0,
        {
          id: `new${Math.floor(Math.random() * 1000000000)}`,
          attributes: {
            text: '',
            checked: false,
            isNew: true,
            with_paragraphs: false
          }
        }
      );
    },
    removeItem(id) {
      this.checklistItems = this.checklistItems.filter((item) => item.id !== id);
      this.updatedChecklistItem();
    },
    startReorder() {
      this.reordering = true;
    },
    endReorder(event) {
      this.reordering = false;
      if (
        Number.isInteger(event.newIndex)
          && Number.isInteger(event.oldIndex)
          && event.newIndex !== event.oldIndex
      ) {
        let afterId = null;
        if (event.newIndex > 0) {
          if (event.newIndex > event.oldIndex) {
            afterId = this.checklistItems[event.newIndex - 1].id;
          } else {
            afterId = this.checklistItems[event.newIndex + 1].id;
          }
        }
        const id = this.checklistItems[event.newIndex]?.id;
        this.saveItemOrder(id, afterId);
      }
    },
    saveItemOrder(id, afterId) {
      axios.post(this.element.attributes.orderable.urls.reorder_url, {
        id,
        after_id: afterId
      }).then(() => {
        this.loadChecklistItems();
        this.updatedChecklistItem();
      }).catch((e) => {
        this.setFlashErrors(e.response.errors);
      });
    },
    setFlashErrors(errors) {
      for (const key in errors) {
        HelperModule.flashAlertMsg(
          this.i18n.t(`activerecord.errors.models.checklist_item.attributes.${key}`),
          'danger'
        );
      }
    }
  }
};
</script>
