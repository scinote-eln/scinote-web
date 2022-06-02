<template>
  <div class="step-checklist-container">
    <div class="step-element-header" :class="{ 'locked': locked }">
      <div class="step-element-grip" @click="$emit('reorder')">
        <i class="fas fa-grip-vertical"></i>
      </div>
      <div class="step-element-name">
        <InlineEdit
          :value="element.attributes.orderable.name"
          :characterLimit="255"
          :placeholder="''"
          :allowBlank="false"
          :autofocus="editingName"
          :attributeName="`${i18n.t('Checklist')} ${i18n.t('name')}`"
          @editingEnabled="editingName = true"
          @editingDisabled="editingname = false"
          @update="updateName"
        />
      </div>
      <div class="step-element-controls">
        <button class="btn icon-btn btn-light" @click="editingName = true">
          <i class="fas fa-pen"></i>
        </button>
        <button class="btn icon-btn btn-light" @click="showDeleteModal">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <div class="step-checklist-items">
      <Draggable
        v-model="checklistItems"
        :ghostClass="'step-checklist-item-ghost'"
        :dragClass="'step-checklist-item-drag'"
        :chosenClass="'step-checklist-item-chosen'"
        :handle="'.step-element-grip'"
        :disabled="editingItem"
        @start="startReorder"
        @end="endReorder"
      >
        <ChecklistItem
          v-for="checklistItem in orderedChecklistItems"
          :key="checklistItem.attributes.id"
          :checklistItem="checklistItem"
          :locked="locked"
          @editStart="editingItem = true"
          @editEnd="editingItem = false"
          @update="saveItem"
          @removeItem="removeItem"
          @component:delete="removeItem"
          @multilinePaste="handleMultilinePaste"
        />
      </Draggable>
      <div class="btn btn-light step-checklist-add-item" @click="addItem">
        <i class="fas fa-plus"></i>
        {{ i18n.t('protocols.steps.insert.checklist_item') }}
      </div>
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from 'vue/protocol/mixins/components/delete.js'
  import deleteElementModal from 'vue/protocol/modals/delete_element.vue'
  import InlineEdit from 'vue/shared/inline_edit.vue'
  import ChecklistItem from 'vue/protocol/step_elements/checklistItem.vue'
  import Draggable from 'vuedraggable'

  export default {
    name: 'Checklist',
    components: { deleteElementModal, InlineEdit, ChecklistItem, Draggable },
    mixins: [DeleteMixin],
    props: {
      element: {
        type: Object,
        required: true
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
      this.checklistItems = this.element.attributes.orderable.checklist_items.map((item, index) => {
        return { attributes: {...item, position: index } }
      });
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
        return this.reordering || this.editingName
      }
    },
    methods: {
      updateName(name) {
        this.element.attributes.orderable.name = name;
        this.update();
      },
      update() {
        this.$emit('update', this.element)
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
      },
      saveItem(item) {
        if (item.attributes.id) {
          this.checklistItems.splice(
            item.attributes.position, 1, item
          );
          $.ajax({
            url: item.attributes.urls.update_url,
            type: 'PATCH',
            data: item,
            error: () => HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger')
          });
        } else {
          // create item, then append next one
          this.postItem(item);
          this.addItem();
        }
      },
      addItem() {
        this.checklistItems.push(
          {
            attributes: {
              text: '',
              checked: false,
              position: this.checklistItems.length
            }
          }
        );
      },
      removeItem(position) {
        this.checklistItems.splice(position, 1);
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
          error: (() => HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger'))
        });
      },
      handleMultilinePaste(data) {
        this.linesToPaste = data.length;
        let nextPosition = this.checklistItems.length;

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
