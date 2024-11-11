<template>
  <div class="content__table-container pr-8"
    :data-e2e="`e2e-CO-${dataE2e}-${element.attributes.orderable.metadata.plateTemplate ? 'wellPlate' : 'table'}${element.id}`">
    <div class="sci-divider my-6" v-if="!inRepository"></div>
    <div class="table-header h-9 flex rounded mb-3 items-center relative w-full group/table-header" :class="{ 'editing-name': editingName, 'locked': locked }">
      <div v-if="!locked || element.attributes.orderable.name" :key="reloadHeader"
           class="grow-1 text-ellipsis whitespace-nowrap grow my-1 font-bold"
           :class="{'pointer-events-none': locked}">
        <InlineEdit
          :value="element.attributes.orderable.name"
          :characterLimit="255"
          :placeholder="i18n.t('protocols.steps.table.table_name')"
          :allowBlank="false"
          :autofocus="editingName"
          :attributeName="`${i18n.t('Table')} ${i18n.t('name')}`"
          :dataE2e="`${dataE2e}-${element.attributes.orderable.metadata.plateTemplate ? 'wellPlate' : 'table'}${element.id}`"
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
        :dataE2e="`e2e-DD-${dataE2e}-${element.attributes.orderable.metadata.plateTemplate ? 'wellPlate' : 'table'}${element.id}-options`"
        @edit="enableNameEdit"
        @duplicate="duplicateElement"
        @move="showMoveModal"
        @delete="showDeleteModal"
      ></MenuDropdown>
    </div>
    <Spreadsheet
      ref="spreadsheet"
      :license="license"
      :tabs="true"
      :toolbar="true"
      :allowExport="true"
      :onchange="update"
      :oninsertrow="update"
      :oninsertcolumn="update"
      :ondeletecolumn="update"
      :ondeleterow="update"
      :onmoverow="update"
      :onmovecolumn="update"
    >
      <Worksheet :data="tableData" :tableOverflow="true" tableWidth="600" resize="both" />
    </Spreadsheet>
    <div class="table-body group/table-body relative border-solid border-transparent"
         :class="{'edit border-sn-light-grey': editingTable, 'view': !editingTable, 'locked': !element.attributes.orderable.urls.update_url}"
         tabindex="0"
         :data_e2e="`e2e-TB-${dataE2e}-${element.attributes.orderable.metadata.plateTemplate ? 'wellPlate' : 'table'}${element.id}`"
         @keyup.enter="!editingTable && enableTableEdit()">
      <div ref="hotTable" class="hot-table-container" @click="!editingTable && enableTableEdit()">
      </div>
      <div class="text-xs pt-3 pb-2 text-sn-grey h-1">
        <span v-if="editingTable" :dataE2e="`e2e-TX-${dataE2e}-${element.attributes.orderable.metadata.plateTemplate ? 'wellPlate' : 'table'}${element.id}-editMessage`">
          {{ i18n.t('protocols.steps.table.edit_message') }}
        </span>
      </div>
    </div>
    <deleteElementModal v-if="confirmingDelete" @confirm="deleteElement" @cancel="closeDeleteModal"/>
    <tableNameModal v-if="nameModalOpen" :element="element" @update="updateEmptyName" @cancel="nameModalOpen = false" />
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
import InlineEdit from '../inline_edit.vue';
import TableNameModal from './modal/table_name.vue';
import moveElementModal from './modal/move.vue';
import MenuDropdown from '../menu_dropdown.vue';
import { Spreadsheet, Worksheet } from "@jspreadsheet/vue";

export default {
  name: 'ContentTable',
  components: {
    deleteElementModal,
    InlineEdit,
    TableNameModal,
    moveElementModal,
    MenuDropdown,
    Spreadsheet,
    Worksheet
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
      type: Boolean, default: false
    },
    assignableMyModuleId: {
      type: Number,
      required: false
    },
    dataE2e: {
      type: String,
      default: ''
    }
  },
  data() {
    return {
      tableData: [],
      editingName: false,
      editingTable: false,
      editingCell: false,
      tableObject: null,
      nameModalOpen: false,
      reloadHeader: 0,
      updatingTableData: false,
    };
  },
  computed: {
    locked() {
      return !this.element.attributes.orderable.urls.update_url;
    },
    actionMenu() {
      const menu = [];
      if (this.element.attributes.orderable.urls.update_url) {
        menu.push({
          text: I18n.t('general.edit'),
          emit: 'edit',
          data_e2e: `e2e-BT-${this.dataE2e}-${this.element.attributes.orderable.metadata.plateTemplate ? 'wellPlate' : 'table'}${this.element.id}-options-edit`
        });
      }
      if (this.element.attributes.orderable.urls.duplicate_url) {
        menu.push({
          text: I18n.t('general.duplicate'),
          emit: 'duplicate',
          data_e2e: `e2e-BT-${this.dataE2e}-${this.element.attributes.orderable.metadata.plateTemplate ? 'wellPlate' : 'table'}${this.element.id}-options-duplicate`
        });
      }
      if (this.element.attributes.orderable.urls.move_targets_url) {
        menu.push({
          text: I18n.t('general.move'),
          emit: 'move',
          data_e2e: `e2e-BT-${this.dataE2e}-${this.element.attributes.orderable.metadata.plateTemplate ? 'wellPlate' : 'table'}${this.element.id}-options-move`
        });
      }
      if (this.element.attributes.orderable.urls.delete_url) {
        menu.push({
          text: I18n.t('general.delete'),
          emit: 'delete',
          data_e2e: `e2e-BT-${this.dataE2e}-${this.element.attributes.orderable.metadata.plateTemplate ? 'wellPlate' : 'table'}${this.element.id}-options-delete`
        });
      }
      return menu;
    }
  },
  created() {
    this.license = document.querySelector('meta[name="jspreadsheet-key"]').getAttribute('content');
    this.tableData = JSON.parse(this.element.attributes.orderable.contents).data;
    window.addEventListener('beforeunload', this.showSaveWarning);
  },
  beforeUnmount() {
    window.removeEventListener('beforeunload', this.showSaveWarning);
  },
  updated() {
    if (!this.updatingTableData) this.loadTableData();
  },
  beforeUpdate() {
    //if (!this.updatingTableData) this.tableObject.destroy();
  },
  mounted() {
    this.loadTableData();

    if (this.isNew) {
      // needs to first update to save metadata at table creation
      // updating is triggered by the afterChange hook
      this.enableTableEdit();
    }
  },
  methods: {
    showSaveWarning(e) {
      if (this.editingCell) {
        e.preventDefault();
        e.returnValue = '';
      }
    },
    enableTableEdit() {
      if (this.locked) {
        return;
      }

      if (!this.element.attributes.orderable.name) {
        this.openNameModal();
        return;
      }

      const { row = 0, col = 0 } = this.selectedCell || {};
      this.editingTable = true;
      this.$nextTick(() => this.tableObject.selectCell(row, col));
    },
    disableTableEdit() {
      this.editingTable = false;
      this.updatingTableData = false;
    },
    enableNameEdit() {
      this.editingName = true;
    },
    disableNameEdit() {
      this.editingName = false;
    },
    updateName(name) {
      this.element.attributes.orderable.name = name;
      // Prevents the table from being updated when the name is updated
      this.updatingTableData = true;
      this.update(() => {
        this.updatingTableData = false;
      });
    },
    openNameModal() {
      this.tableObject.deselectCell();
      this.nameModalOpen = true;
    },
    updateEmptyName(name) {
      this.disableNameEdit();

      // force reload header to properly reset name inline edit
      this.reloadHeader += 1;

      this.element.attributes.orderable.name = name;
      this.$emit('update', this.element, false, () => {
        this.nameModalOpen = false;
        this.enableTableEdit();
      });
    },
    updateTable() {
      if (this.editingTable === false) return;

      this.update(() => {
        this.editingTable = false;
        this.updatingTableData = false;
      });
    },
    update(callback = () => {}) {
      if (this.$refs.spreadsheet?.current) {
        const newTableData = this.$refs.spreadsheet.current[0].getData();

        this.element.attributes.orderable.contents = JSON.stringify({ data: newTableData });
        this.$emit('update', this.element, false, callback);
      }

      /*
      this.element.attributes.orderable.contents = JSON.stringify({ data: this.tableObject.getData() });
      const metadata = this.element.attributes.orderable.metadata || {};
      if (metadata.plateTemplate) {
        this.element.attributes.orderable.metadata = JSON.stringify({
          cells: this.tableObject
            .getCellsMeta()
            .filter((e) => !!e)
            .map((x) => {
              const { row, col } = x;
              return {
                row,
                col,
                className: x.className || ''
              };
            })
        });
      } else {
        this.element.attributes.orderable.metadata = JSON.stringify({
          cells: this.tableObject
            .getCellsMeta()
            .filter((e) => !!e)
            .map((x) => {
              const { row, col } = x;
              const plugins = this.tableObject.plugin;
              const cellId = plugins.utils.translateCellCoords({ row, col });
              const calculated = plugins.matrix.getItem(cellId)?.value
                                || this.tableObject.getDataAtCell(row, col)
                                || null;
              return {
                row,
                col,
                className: x.className || '',
                calculated
              };
            })
        });
      }


      */
    },
    updateTableData() {
      if (this.editingTable === false) return;
      this.updatingTableData = true;

      this.$nextTick(() => {
        this.update(() => {
          this.editingCell = false;
        });
      });
    },
    loadTableData() {
      return
      const container = this.$refs.hotTable;
      const data = JSON.parse(this.element.attributes.orderable.contents);
      const metadata = this.element.attributes.orderable.metadata || {};
      const formulasEnabled = !metadata.plateTemplate;

      this.tableObject = new Handsontable(container, {
        data: data.data,
        width: '100%',
        startRows: 5,
        startCols: 5,
        rowHeaders: tableColRowName.tableRowHeaders(metadata.plateTemplate),
        colHeaders: tableColRowName.tableColHeaders(metadata.plateTemplate),
        cell: metadata.cells || [],
        contextMenu: this.editingTable,
        formulas: formulasEnabled,
        preventOverflow: 'horizontal',
        readOnly: !this.editingTable,
        afterUnlisten: () => {
          this.editingTable = false;
        },
        afterSelection: (r, c, r2, c2) => {
          if (r === r2 && c === c2) {
            this.selectedCell = { row: r, col: c };
          }
        },
        afterChange: () => {
          this.updateTableData();
        },
        afterRemoveRow: () => {
          this.updateTableData();
        },
        afterRemoveCol: () => {
          this.updateTableData();
        },
        afterCreateCol: () => {
          this.updateTableData();
        },
        afterCreateRow: () => {
          this.updateTableData();
        },
        beforeKeyDown: (e) => {
          if (e.keyCode === 27) { // esc
            this.editingCell = false;
          }
        },
        afterBeginEditing: (e) => {
          this.editingCell = true;
        }
      });
      this.$nextTick(this.tableObject.render);
    }
  }
};
</script>
