<template>
  <div class="content__checklist-container" >
    <div class="checklist-header flex rounded pl-8 mb-1 items-center relative w-full group/checklist-header" :class="{ 'editing-name': editingName, 'locked': !element.attributes.orderable.urls.update_url }">
      <div v-if="reorderElementUrl"
          class="absolute items-center h-full justify-center left-0 p-2 tw-hidden text-sn-grey"
          :class="{ 'group-hover/checklist-header:flex': !locked }"
           @click="$emit('reorder')">
        <i class="sn-icon sn-icon-sort"></i>
      </div>
      <div class="grow-1 text-ellipsis whitespace-nowrap grow my-1 font-bold">
        <InlineEdit
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
      <div class="tw-hidden group-hover/checklist-header:flex items-center gap-2 ml-auto">
        <button v-if="element.attributes.orderable.urls.update_url" class="btn icon-btn btn-light btn-sm" @click="editingName = true" tabindex="0">
          <i class="sn-icon sn-icon-edit"></i>
        </button>
        <button v-if="element.attributes.orderable.urls.duplicate_url" class="btn icon-btn btn-light btn-sm" tabindex="0" @click="duplicateElement">
          <i class="sn-icon sn-icon-duplicate"></i>
        </button>
        <button v-if="element.attributes.orderable.urls.move_targets_url" class="btn btn-light btn-sm" tabindex="0" @click="showMoveModal">
          Move
        </button>
        <button v-if="element.attributes.orderable.urls.delete_url" class="btn icon-btn btn-light btn-sm" @click="showDeleteModal" tabindex="0">
          <i class="sn-icon sn-icon-delete"></i>
        </button>
      </div>
    </div>
    <div v-if="element.attributes.orderable.urls.create_item_url || orderedChecklistItems.length > 0">
      <Draggable
        v-model="checklistItems"
        :ghostClass="'checklist-item-ghost border-blue border-solid'"
        :dragClass="'checklist-item-drag'"
        :chosenClass="'checklist-item-chosen'"
        :forceFallback="true"
        :handle="'.element-grip'"
        :disabled="editingItem || checklistItems.length < 2 || !element.attributes.orderable.urls.reorder_url"
        @start="startReorder"
        @end="endReorder"
      >
        <ChecklistItem
          v-for="checklistItem in orderedChecklistItems"
          :key="checklistItem.attributes.id"
          :checklistItem="checklistItem"
          :locked="locked"
          :reorderChecklistItemUrl="element.attributes.orderable.urls.reorder_url"
          :inRepository="inRepository"
          :draggable="checklistItems.length > 1"
          @editStart="editingItem = true"
          @editEnd="editingItem = false"
          @update="saveItem"
          @toggle="saveItemChecked"
          @removeItem="removeItem"
          @component:delete="removeItem"
          @multilinePaste="handleMultilinePaste"
        />
      </Draggable>
      <div v-if="element.attributes.orderable.urls.create_item_url"
           class="ml-7 btn btn-light btn-sm px-2"
           tabindex="0"
           @keyup.enter="addItem"
           @click="addItem">
        <i class="sn-icon sn-icon-new-task w-6 text-center"></i>
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
  import DeleteMixin from './mixins/delete.js'
  import MoveMixin from './mixins/move.js'
  import DuplicateMixin from './mixins/duplicate.js'
  import deleteElementModal from './modal/delete.vue'
  import InlineEdit from '../inline_edit.vue'
  import ChecklistItem from './checklistItem.vue'
  import Draggable from 'vuedraggable'
  import moveElementModal from './modal/move.vue'

  export default {
    name: 'Checklist',
    components: { deleteElementModal, InlineEdit, ChecklistItem, Draggable, moveElementModal },
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
        linesToPaste: 0,
        editingName: false,
        reordering: false,
        editingItem: false
      }
    },
    created() {
      this.initChecklistItems();

      if (this.isNew) {
        this.addItem();
      }
    },
    watch: {
      element() {
        this.initChecklistItems();
      }
    },
    computed: {
      orderedChecklistItems() {
        return this.checklistItems.map((item, index) => {
          return { attributes: {...item.attributes, position: index } }
        });
      },
      pastingMultiline() {
        return this.linesToPaste > 0;
      },
      locked() {
        return this.reordering || this.editingName || !this.element.attributes.orderable.urls.update_url
      }
    },
    methods: {
      initChecklistItems() {
        this.checklistItems = this.element.attributes.orderable.checklist_items.map((item, index) => {
          return { attributes: {...item, position: index } }
        });
      },
      updateName(name) {
        this.element.attributes.orderable.name = name;
        this.editingName = false;
        this.update(false);
      },
      update(skipRequest = true) {
        this.element.attributes.orderable.checklist_items =
          this.checklistItems.map((i) => i.attributes);

        this.$emit('update', this.element, skipRequest);
      },
      postItem(item, callback) {
        console.log(this.element.attributes.orderable.urls.create_item_url)
        $.post(this.element.attributes.orderable.urls.create_item_url, item).done((result) => {
          this.checklistItems.splice(
            result.data.attributes.position,
            1,
            { attributes: { ...result.data.attributes, id: result.data.id } }
          );

          if(callback) callback();
        }).fail((e) => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        });

        this.update();
      },
      saveItem(item) {
        if (item.attributes.id) {
          $.ajax({
            url: item.attributes.urls.update_url,
            type: 'PATCH',
            data: item,
            success: (result) => {
              let updatedItem = this.checklistItems[item.attributes.position]
              updatedItem.attributes = result.data.attributes
              updatedItem.attributes.id = item.attributes.id
              this.$set(this.checklistItems, item.attributes.position, updatedItem)
            },
            error: (xhr) => setFlashErrors(xhr.responseJSON.errors)
          });
        } else {
          // create item, then append next one
          this.postItem(item, this.addItem);
        }
        this.update(true);
      },
      saveItemChecked(item) {
        $.ajax({
          url: item.attributes.urls.toggle_url,
          type: 'PATCH',
          data: { attributes: { checked: item.attributes.checked } },
          success: (result) => {
            let updatedItem = this.checklistItems[item.attributes.position]
            updatedItem.attributes = result.data.attributes
            updatedItem.attributes.id = item.attributes.id
            this.$set(this.checklistItems, item.attributes.position, updatedItem)
          },
          error: () => HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger')
        });
      },
      addItem() {
        this.checklistItems.push(
          {
            attributes: {
              text: '',
              checked: false,
              position: this.checklistItems.length,
              isNew: true
            }
          }
        );
      },
      removeItem(position) {
        this.checklistItems.splice(position, 1);
        this.update();
      },
      startReorder() {
        this.reordering = true;
      },
      endReorder(event) {
        this.reordering = false;
        if(
          Number.isInteger(event.newIndex)
          && Number.isInteger(event.newIndex)
          && event.newIndex !== event.oldIndex
        ){
          const { id, position } = this.orderedChecklistItems[event.newIndex]?.attributes
          this.saveItemOrder(id, position);
        }
      },
      saveItemOrder(id, position) {
        $.ajax({
          type: "POST",
          url: this.element.attributes.orderable.urls.reorder_url,
          data: JSON.stringify({ attributes: { id, position } }),
          contentType: "application/json",
          dataType: "json",
          error: (xhr) => this.setFlashErrors(xhr.responseJSON.errors),
          success: () => this.update()
        });
      },
      handleMultilinePaste(data) {
        this.linesToPaste = data.length;
        let nextPosition = this.checklistItems.length - 1;

        // we need to post items to API in the right order, to avoid positions breaking
        let synchronousPost = (index) => {
          if(index === data.length) return;

          let item = {
            attributes: {
              text: data[index],
              checked: false,
              position: nextPosition + index
            }
          };

          this.linesToPaste -= 1;
          this.postItem(item, () => synchronousPost(index + 1));
        };

        synchronousPost(0);
      },
      setFlashErrors(errors) {
        for(const key in errors){
          HelperModule.flashAlertMsg(
            this.i18n.t(`activerecord.errors.models.checklist_item.attributes.${key}`),
            'danger'
          )
        }
      }
    }
  }
</script>