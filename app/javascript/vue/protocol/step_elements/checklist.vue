<template>
  <div class="step-checklist-container" >
    <div class="step-element-header" :class="{ 'editing-name': editingName, 'no-hover': !element.attributes.orderable.urls.update_url }">
      <div v-if="reorderElementUrl" class="step-element-grip" @click="$emit('reorder')">
        <i class="fas fas-rotated-90 fa-exchange-alt"></i>
      </div>
      <div v-else class="step-element-grip-placeholder"></div>
      <div class="step-element-name">
        <InlineEdit
          :class="{ 'step-element--locked': !element.attributes.orderable.urls.update_url }"
          :value="element.attributes.orderable.name"
          :sa_value="element.attributes.orderable.sa_name"
          :characterLimit="10000"
          :placeholder="''"
          :allowBlank="false"
          :autofocus="editingName"
          :smartAnnotation="true"
          :attributeName="`${i18n.t('Checklist')} ${i18n.t('name')}`"
          @editingEnabled="editingName = true"
          @editingDisabled="editingName = false"
          @update="updateName"
        />
      </div>
      <div class="step-element-controls">
        <button v-if="element.attributes.orderable.urls.update_url" class="btn icon-btn btn-light" @click="editingName = true" tabindex="0">
          <i class="fas fa-pen"></i>
        </button>
        <button v-if="element.attributes.orderable.urls.duplicate_url" class="btn icon-btn btn-light" tabindex="0" @click="duplicateElement">
          <i class="fas fa-clone"></i>
        </button>
        <button v-if="element.attributes.orderable.urls.delete_url" class="btn icon-btn btn-light" @click="showDeleteModal" tabindex="0">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <div v-if="element.attributes.orderable.urls.create_item_url || orderedChecklistItems.length > 0" class="step-checklist-items">
      <Draggable
        v-model="checklistItems"
        :ghostClass="'step-checklist-item-ghost'"
        :dragClass="'step-checklist-item-drag'"
        :chosenClass="'step-checklist-item-chosen'"
        :handle="'.step-element-grip'"
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
           class="btn btn-light step-checklist-add-item"
           tabindex="0"
           @keyup.enter="addItem"
           @click="addItem">
        <i class="fas fa-plus"></i>
        {{ i18n.t('protocols.steps.insert.checklist_item') }}
      </div>
    </div>
    <div v-else class="empty-checklist-element">
      {{ i18n.t("protocols.steps.checklist.empty_checklist") }}
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from '../mixins/components/delete.js'
  import DuplicateMixin from '../mixins/components/duplicate.js'
  import deleteElementModal from '../modals/delete_element.vue'
  import InlineEdit from '../../shared/inline_edit.vue'
  import ChecklistItem from '../step_elements/checklistItem.vue'
  import Draggable from 'vuedraggable'

  export default {
    name: 'Checklist',
    components: { deleteElementModal, InlineEdit, ChecklistItem, Draggable },
    mixins: [DeleteMixin, DuplicateMixin],
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
        $.post(this.element.attributes.orderable.urls.create_item_url, item).success((result) => {
          this.checklistItems.splice(
            result.data.attributes.position,
            1,
            { attributes: { ...result.data.attributes, id: result.data.id } }
          );

          if(callback) callback();
        }).error(() => {
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
            error: () => HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger')
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
      endReorder() {
        this.reordering = false;
        this.saveItemOrder();
      },
      saveItemOrder() {
        let checklistItemPositions =
          {
            checklist_item_positions: this.orderedChecklistItems.map(
              (i) => [i.attributes.id, i.attributes.position]
            )
          };

        $.ajax({
          type: "POST",
          url: this.element.attributes.orderable.urls.reorder_url,
          data: JSON.stringify(checklistItemPositions),
          contentType: "application/json",
          dataType: "json",
          error: (() => HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger')),
          success: (() => this.update())
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
      }
    }
  }
</script>
