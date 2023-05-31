<template>
  <div class="step-table-container">
     <div class="step-element-header" :class="{ 'editing-name': editingName, 'step-element--locked': locked }">
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
        <button v-if="element.attributes.orderable.urls.update_url" class="btn icon-btn btn-light" @click="enableNameEdit" tabindex="0">
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
    <div class="step-table"
         :class="{'edit': editingTable, 'view': !editingTable, 'locked': !element.attributes.orderable.urls.update_url}"
         tabindex="0"
         @keyup.enter="!editingTable && enableTableEdit()">
      <div  class="enable-edit-mode" v-if="!editingTable && element.attributes.orderable.urls.update_url" @click="enableTableEdit">
        <div class="enable-edit-mode__icon" tabindex="0">
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
    <tableNameModal v-if="nameModalOpen" :element="element" @update="updateEmptyName" @cancel="nameModalOpen = false" />
  </div>
</template>

 <script>
  import DeleteMixin from '../mixins/components/delete.js'
  import DuplicateMixin from '../mixins/components/duplicate.js'
  import deleteElementModal from '../modals/delete_element.vue'
  import InlineEdit from '../../shared/inline_edit.vue'
  import TableNameModal from '../modals/table_name_modal.vue'

  export default {
    name: 'StepTable',
    components: { deleteElementModal, InlineEdit, TableNameModal },
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
        type: Boolean, default: false
      },
      assignableMyModuleId: {
        type: Number,
        required: false
      }
    },
    data() {
      return {
        editingName: false,
        editingTable: false,
        tableObject: null,
        nameModalOpen: false,
        reloadHeader: 0
      }
    },
    computed: {
      locked() {
        return !this.element.attributes.orderable.urls.update_url
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

      if (this.isNew) this.enableTableEdit();
    },
    methods: {
      enableTableEdit() {
        if(this.locked) {
          return;
        }

        if (!this.element.attributes.orderable.name) {
          this.openNameModal();
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
        this.update();
      },
      openNameModal() {
        this.tableObject.deselectCell();
        this.nameModalOpen = true;
      },
      updateEmptyName(name) {
        this.disableNameEdit();

        // force reload header to properly reset name inline edit
        this.reloadHeader = this.reloadHeader + 1;

        this.element.attributes.orderable.name = name;
        this.$emit('update', this.element, false, () => {
          this.nameModalOpen = false;
          this.enableTableEdit();
        });
      },
      updateTable() {
        if (this.editingTable == false) return;

        this.update();
        this.editingTable = false;
      },
      update() {
        this.element.attributes.orderable.contents = JSON.stringify({ data: this.tableObject.getData() });
        this.element.attributes.orderable.metadata = JSON.stringify({
          cells: this.tableObject
                     .getCellsMeta()
                     .filter(e => !!e)
                     .map((x) => {
                          const {row, col} = x;
                          const plugins = this.tableObject.plugin;
                          const cellId = plugins.utils.translateCellCoords({row, col});
                          const calculated = plugins.matrix.getItem(cellId)?.value ||
                            this.tableObject.getDataAtCell(row, col) ||
                            null;
                          return {
                            row: row,
                            col: col,
                            className: x.className || '',
                            calculated: calculated
                          }
                      })
        });
        this.$emit('update', this.element)
        this.ajax_update_url()
      },
      ajax_update_url() {
        $.ajax({
          url: this.element.attributes.orderable.urls.update_url,
          method: 'PUT',
          data: this.element.attributes.orderable,
        })
      },
      loadTableData() {
        let container = this.$refs.hotTable;
        let data = JSON.parse(this.element.attributes.orderable.contents);
        let metadata = this.element.attributes.orderable.metadata || {};

        this.tableObject = new Handsontable(container, {
          data: data.data,
          width: '100%',
          startRows: 5,
          startCols: 5,
          rowHeaders: tableColRowName.tableRowHeaders(metadata.plateTemplate),
          colHeaders: tableColRowName.tableColHeaders(metadata.plateTemplate),
          cell: metadata.cells || [],
          contextMenu: this.editingTable,
          formulas: true,
          preventOverflow: 'horizontal',
          readOnly: !this.editingTable,
          afterUnlisten: () => setTimeout(this.updateTable, 100) // delay makes cancel button work
        });
      }
    }
  }
</script>
