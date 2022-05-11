<template>
  <div class="step-checklist-container">
    <div class="step-element-header" :class="{ 'editing-name': editingName }">
      <div class="step-element-grip">
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
          @editingEnabled="enableNameEdit"
          @editingDisabled="disableNameEdit"
          @update="updateName"
        />
      </div>
      <div class="step-element-controls">
        <button class="btn icon-btn btn-light" @click="enableNameEdit">
          <i class="fas fa-pen"></i>
        </button>
        <button class="btn icon-btn btn-light" @click="showDeleteModal">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <div v-if="!pastingMultiline" class="step-checklist-items">
      <ChecklistItem
        v-for="checklistItem in checklistItems"
        :key="checklistItem.attributes.id"
        :checklistItem="checklistItem"
        @update="saveItem"
        @removeItem="removeItem"
        @component:delete="removeItem"
        @multilinePaste="handleMultilinePaste"
      />
      <div class="btn btn-light step-checklist-add-item" @click="addItem">
        <i class="fas fa-plus"></i>
        {{ i18n.t('protocols.steps.insert.checklist_item') }}
      </div>
    </div>
    <deleteComponentModal v-if="confirmingDelete" @confirm="deleteComponent" @cancel="closeDeleteModal"/>
  </div>
</template>

 <script>
  import DeleteMixin from 'vue/protocol/mixins/components/delete.js'
  import deleteComponentModal from 'vue/protocol/modals/delete_component.vue'
  import InlineEdit from 'vue/shared/inline_edit.vue'
  import ChecklistItem from 'vue/protocol/step_components/checklistItem.vue'

  export default {
    name: 'Checklist',
    components: { deleteComponentModal, InlineEdit, ChecklistItem },
    mixins: [DeleteMixin],
    props: {
      element: {
        type: Object,
        required: true
      }
    },
    data() {
      return {
        editingName: false,
        linesToPaste: 0
      }
    },
    computed: {
      checklistItems() {
        return this.element.attributes.orderable.checklist_items.map((item, index) => {
          return { attributes: {...item, position: index + 1 } }
        });
      },
      pastingMultiline() {
        return this.linesToPaste > 0;
      }
    },
    methods: {
      enableNameEdit() {
        this.editingName = true;
      },
      disableNameEdit() {
        this.editingName = false;
      },
      updateName(name) {
        this.element.attributes.orderable.name = name;
        this.update();
      },
      update() {
        this.$emit('update', this.element)
      },
      postItem(item, callback) {
        $.post(this.element.attributes.orderable.urls.create_item_url, item).success((result) => {
          this.element.attributes.orderable.checklist_items.splice(
            result.data.attributes.position - 1,
            1,
            { id: result.data.id, ...result.data.attributes }
          );

          callback();
        }).error(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        });
      },
      saveItem(item) {
        if (item.attributes.id) {
          this.element.attributes.orderable.checklist_items.splice(
            item.attributes.position - 1, 1, item.attributes
          );
          $.ajax({
            url: item.attributes.urls.update_url,
            type: 'PATCH',
            data: item,
            error: () => HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger')
          });
        } else {
          this.postItem(item, this.addItem);
        }
      },
      addItem() {
        this.element.attributes.orderable.checklist_items.push(
          {
            text: '',
            checked: false,
            position: this.element.attributes.orderable.checklist_items.length + 1
          }
        );
      },
      removeItem(item) {
        this.element.attributes.orderable.checklist_items.splice(item.attributes.position - 1, 1);
      },
      handleMultilinePaste(data) {
        this.linesToPaste = data.length;
        let nextPosition = this.element.attributes.orderable.checklist_items.length;

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
