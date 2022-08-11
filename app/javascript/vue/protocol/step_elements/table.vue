<template>
  <div class="step-table-container" :class="{ 'step-element--locked': locked }">
     <div class="step-element-header" :class="{ 'editing-name': editingName }">
      <div v-if="reorderElementUrl" class="step-element-grip" @click="$emit('reorder')">
        <i class="fas fas-rotated-90 fa-exchange-alt"></i>
      </div>
      <div v-else class="step-element-grip-placeholder"></div>
      <div v-if="!locked || element.attributes.orderable.name" :key="reloadHeader" class="step-element-name">
        <InlineEdit
          :value="element.attributes.orderable.name"
          :characterLimit="255"
          :placeholder="''"
          :allowBlank="false"
          :autofocus="editingName"
          :attributeName="`${i18n.t('Table')} ${i18n.t('name')}`"
          @editingEnabled="enableNameEdit"
          @editingDisabled="disableNameEdit"
          @update="updateName"
        />
      </div>
      <div class="step-element-controls">
        <button v-if="element.attributes.orderable.urls.update_url" class="btn icon-btn btn-light" @click="enableNameEdit" tabindex="-1">
          <i class="fas fa-pen"></i>
        </button>
        <button v-if="element.attributes.orderable.urls.delete_url" class="btn icon-btn btn-light" @click="showDeleteModal" tabindex="-1">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>
    <div class="step-table"
         :class="{'edit': editingTable, 'view': !editingTable, 'locked': !element.attributes.orderable.urls.update_url}"
         tabindex="0"
         @keyup.enter="!editingTable && enableTableEdit()">
      <div  class="enable-edit-mode" v-if="!editingTable && element.attributes.orderable.urls.update_url" @click="enableTableEdit">
        <div class="enable-edit-mode__icon">
          <i class="fas fa-pen"></i>
        </div>
      </div>
      <div ref="hotTable" class="hot-table-container" @click="!editingTable && enableTableEdit()">
      </div>
      <div v-if="editingTable" class="edit-message">
        {{ i18n.t('protocols.steps.table.edit_message') }}
      </div>
    </div>
    <div class="edit-buttons" v-if="editingTable">
      <button class="btn icon-btn btn-primary" @click="updateTable">
        <i class="fas fa-check"></i>
      </button>
      <button class="btn icon-btn btn-light" @click="disableTableEdit">
        <i class="fas fa-times"></i>
      </button>
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement" @cancel="closeDeleteModal"/>

    <div ref="nameModal" class="modal" :id="`tableNameModal${element.attributes.orderable.id}`" tabindex="-1" role="dialog">
      <div class="modal-dialog modal-md" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
            <h4 class="modal-title" id="modal-destroy-team-label">
              {{ i18n.t('protocols.steps.table.name_modal.title')}}
            </h4>
          </div>
          <div class="modal-body">
            <p>{{ i18n.t('protocols.steps.table.name_modal.description')}}</p>
            <div class="sci-input-container" :class="{ 'error': nameModalError }">
              <input ref="nameModalInput" v-model="newName" type="text" class="sci-input-field" @keyup.enter="!nameModalError && updateName(newName)" required="true" />
              <div v-if="nameModalError" class="table-name-error">
                {{ i18n.t('protocols.steps.table.name_modal.error') }}
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" @click="updateName(newName)">{{ i18n.t('protocols.steps.table.name_modal.save')}}</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

 <script>
  import DeleteMixin from 'vue/protocol/mixins/components/delete.js'
  import deleteElementModal from 'vue/protocol/modals/delete_element.vue'
  import InlineEdit from 'vue/shared/inline_edit.vue'

  export default {
    name: 'StepTable',
    components: { deleteElementModal, InlineEdit },
    mixins: [DeleteMixin],
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
        type: Boolean, default: false
      }
    },
    data() {
      return {
        editingName: false,
        editingTable: false,
        tableObject: null,
        newName: null,
        reloadHeader: 0
      }
    },
    computed: {
      locked() {
        return !this.element.attributes.orderable.urls.update_url
      },
      defaultName() {
        return this.i18n.t('protocols.steps.table.default_name', { position: this.element.attributes.position + 1 });
      },
      nameModalError() {
        return !this.newName;
      }
    },
    updated() {
      this.loadTableData();
    },
    beforeUpdate() {
      this.tableObject.destroy();
    },
    mounted() {
      this.loadTableData();
      this.initNameModal();

      if (this.isNew) this.enableTableEdit();
    },
    methods: {
      enableTableEdit() {
        // if name is not present, open name modal
        if (!this.element.attributes.orderable.name) {
          this.tableObject.deselectCell();
          $(this.$refs.nameModal).modal('show');
          return;
        }

        this.editingTable = true;
        this.$nextTick(() => this.tableObject.selectCell(0,0));
      },
      disableTableEdit() {
        this.editingTable = false;
      },
      enableNameEdit() {
        this.editingName = true;
      },
      disableNameEdit() {
        this.editingName = false;
      },
      updateName(name) {
        this.element.attributes.orderable.name = name;

        if ($(this.$refs.nameModal).hasClass('in')) {
          // if name was updated from modal, hide it and put table in edit mode
          $(this.$refs.nameModal).modal('hide');
          this.disableNameEdit();

          // force reload header to properly reset name inline edit
          this.reloadHeader = this.reloadHeader + 1;

          this.update(this.enableTableEdit)
        } else {
          this.update();
        }
      },
      updateTable() {
        if (this.editingTable == false) return;

        let tableData = JSON.stringify({data: this.tableObject.getData()});
        this.element.attributes.orderable.contents = tableData;
        this.update();
        this.editingTable = false;
      },
      update(callback) {
        this.$emit('update', this.element, false, callback)
      },
      loadTableData() {
        let container = this.$refs.hotTable;
        let data = JSON.parse(this.element.attributes.orderable.contents);
        this.tableObject = new Handsontable(container, {
          data: data.data,
          width: '100%',
          startRows: 5,
          startCols: 5,
          rowHeaders: true,
          colHeaders: true,
          contextMenu: this.editingTable,
          formulas: true,
          readOnly: !this.editingTable,
          afterUnlisten: () => setTimeout(this.updateTable, 100) // delay makes cancel button work
        });
      },
      initNameModal() {
        this.newName = this.defaultName;
        $(this.$refs.nameModal).on('shown.bs.modal', () => {
          $(this.$refs.nameModalInput).focus();
        });
      }
    }
  }
</script>
