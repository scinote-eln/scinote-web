<template>
  <div class="content__checklist-container pr-8" >
    <div class="sci-divider my-6" v-if="!inRepository"></div>
    <div class="checklist-header flex rounded mb-1 items-center relative w-full group/checklist-header" :class="{ 'editing-name': editingName, 'locked': !element.attributes.orderable.urls.update_url }">
      <div class="grow-1 text-ellipsis whitespace-nowrap grow my-1 font-bold">
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
          @editingEnabled="editingName = true"
          @editingDisabled="editingName = false"
          @update="updateName"
        />
      </div>
      <MenuDropdown
        class="ml-auto"
        :listItems="this.actionMenu"
        :btnClasses="'btn btn-light icon-btn  btn-sm'"
        :position="'right'"
        :btnIcon="'sn-icon sn-icon-more-hori'"
        @edit="editingName = true"
        @duplicate="duplicateElement"
        @move="showMoveModal"
        @delete="showDeleteModal"
      ></MenuDropdown>
    </div>
    <div v-if="element.attributes.orderable.urls.create_item_url || orderedChecklistItems.length > 0" :class="{ 'pointer-events-none': locked }">
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
           @keyup.enter="addItem(orderedChecklistItems.length + 1)"
           @click="addItem(orderedChecklistItems.length + 1)">
        <i class="sn-icon sn-icon-new-task w-6 text-center inline-block"></i>
        {{ i18n.t('protocols.steps.insert.checklist_item') }}
      </div>
    </div>
    <div v-else class="text-sn-grey ml-12">
      {{ i18n.t("protocols.steps.checklist.empty_checklist") }}
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement" @cancel="closeDeleteModal"/>
    <moveElementModal v-if="movingElement"
                      :parent_type="element.attributes.orderable.parent_type"
                      :targets_url="element.attributes.orderable.urls.move_targets_url"
                      @confirm="moveElement($event)" @cancel="closeMoveModal"/>
  </div>
</template>

<script>
import Draggable from 'vuedraggable';
import DeleteMixin from './mixins/delete.js';
import MoveMixin from './mixins/move.js';
import DuplicateMixin from './mixins/duplicate.js';
import deleteElementModal from './modal/delete.vue';
import InlineEdit from '../inline_edit.vue';
import ChecklistItem from './checklistItem.vue';
import moveElementModal from './modal/move.vue';
import MenuDropdown from '../menu_dropdown.vue';

export default {
  name: 'Checklist',
  components: {
    deleteElementModal, InlineEdit, ChecklistItem, Draggable, moveElementModal, MenuDropdown
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
      checklistItems: [],
      editingName: false,
      reordering: false,
      editingItem: false
    };
  },
  created() {
    if (this.isNew) {
      this.addItem(1);
    } else {
      this.loadChecklistItems();
    }
  },
  watch: {
    element() {
      this.loadChecklistItems();
    }
  },
  computed: {
    orderedChecklistItems() {
      return this.checklistItems.sort((a, b) => a.attributes.position - b.attributes.position || b.id - a.id)
        .map((item, index) => {
          item.attributes.position = index + 1;
          return item;
        });
    },
    locked() {
      return this.editingName || !this.element.attributes.orderable.urls.update_url;
    },
    addingNewItem() {
      return this.checklistItems.find((item) => item.attributes.isNew);
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
    update() {
      this.$emit('update', this.element, false);
    },
    loadChecklistItems(insertAfter) {
      $.get(this.element.attributes.orderable.urls.checklist_items_url, (result) => {
        this.checklistItems = result.data;
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
      item.attributes.position = item.attributes.position - 1;
      $.post(this.element.attributes.orderable.urls.create_item_url, item).done((result) => {
        this.loadChecklistItems(result.data[result.data.length - 1].attributes.position);
      }).fail((e) => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });

      // Fake element during loading
      item.id = `new${Math.floor(Math.random() * 1000000000)}`;
      this.checklistItems.push(item);
    },
    saveItem(item, key) {
      if (item.id > 0) {
        const insertAfter = key === 'Enter' ? item.attributes.position : null;
        $.ajax({
          url: item.attributes.urls.update_url,
          type: 'PATCH',
          data: item,
          success: () => {
            this.loadChecklistItems(insertAfter);
          },
          error: (xhr) => setFlashErrors(xhr.responseJSON.errors)
        });
      } else {
        this.postItem(item, key);
      }
    },
    saveItemChecked(item) {
      $.ajax({
        url: item.attributes.urls.toggle_url,
        type: 'PATCH',
        data: { attributes: { checked: item.attributes.checked } },
        success: (result) => {
          this.checklistItems.find(
            (i) => i.id === item.id
          ).attributes.checked = result.data.attributes.checked;
        },
        error: () => HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger')
      });
    },
    addItem(insertAfter) {
      this.checklistItems.push(
        {
          attributes: {
            text: '',
            checked: false,
            position: insertAfter,
            isNew: true
          }
        }
      );
      this.checklistItems = this.orderedChecklistItems;
    },
    removeItem(position) {
      this.checklistItems = this.orderedChecklistItems.filter((item) => item.attributes.position !== position);
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
        const position = this.orderedChecklistItems[event.newIndex]?.attributes.position;
        const id = this.checklistItems[event.oldIndex]?.id;
        this.checklistItems[event.oldIndex].attributes.position = position + (event.newIndex > event.oldIndex ? 1 : -1);
        this.saveItemOrder(id, position);
      }
    },
    saveItemOrder(id, position) {
      $.ajax({
        type: 'POST',
        url: this.element.attributes.orderable.urls.reorder_url,
        data: JSON.stringify({ attributes: { id, position } }),
        contentType: 'application/json',
        dataType: 'json',
        error: (xhr) => this.setFlashErrors(xhr.responseJSON.errors),
        success: () => this.loadChecklistItems()
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
