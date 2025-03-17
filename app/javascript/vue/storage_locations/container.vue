<template>
  <div class="grid w-full h-full gap-6" :class="{ 'grid-cols-[auto_1fr]': withGrid }">
    <div v-if="withGrid" class="max-w-[40vw]">
      <Grid
        :gridSize="gridSize"
        :assignedItems="assignedItems"
        :selectedItems="selectedItems"
        :selectedEmptyCells="selectedEmptyCells"
        @selectEmptyCell="selectEmptyCell"
        @select="selectRow"
        @unselectRow="unselectRow"
        @unselectColumn="unselectColumn"
      />
    </div>
    <div class="h-full bg-white px-4">
      <DataTable :columnDefs="columnDefs"
                :tableId="tableId"
                :dataUrl="dataSource"
                ref="table"
                :reloadingTable="reloadingTable"
                :toolbarActions="toolbarActions"
                :actionsUrl="actionsUrl"
                :actionsMethod="'post'"
                :scrollMode="paginationMode"
                @assign="assignRow"
                @move="moveRow"
                @import="openImportModal = true"
                @unassign="unassignRows"
                @tableReloaded="handleTableReload"
                @selectionChanged="selectedItems = $event"
      />
    </div>
    <Teleport to="body">
      <AssignModal
        v-if="openAssignModal"
        :assignMode="assignMode"
        :selectedContainer="assignToContainer"
        :selectedPositions="assignToPositions"
        :selectedRow="rowIdToMove"
        :selectedRowName="rowNameToMove"
        :cellId="cellIdToUnassign"
        @assign="assignCallback"
        @close="openAssignModal = false"
      ></AssignModal>
      <ImportModal
        v-if="openImportModal"
        :containerId="containerId"
        @close="openImportModal = false"
        @reloadTable="resetTableSearch(); reloadingTable = true"
      ></ImportModal>
      <ConfirmationModal
        :title="i18n.t('storage_locations.show.unassign_modal.title')"
        :description="storageLocationUnassignDescription"
        confirmClass="btn btn-danger"
        :confirmText="i18n.t('storage_locations.show.unassign_modal.button')"
        ref="unassignStorageLocationModal"
      ></ConfirmationModal>
    </Teleport>
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';
import DataTable from '../shared/datatable/table.vue';
import Grid from './grid.vue';
import AssignModal from './modals/assign.vue';
import ImportModal from './modals/import.vue';
import ConfirmationModal from '../shared/confirmation_modal.vue';
import RemindersRender from './renderers/reminders.vue';
import ItemNameRenderer from './renderers/item_name_renderer.vue';

export default {
  name: 'StorageLocationsContainer',
  components: {
    DataTable,
    Grid,
    AssignModal,
    ConfirmationModal,
    RemindersRender,
    ImportModal,
    ItemNameRenderer
  },
  props: {
    canManage: {
      type: String,
      required: true
    },
    dataSource: {
      type: String,
      required: true
    },
    actionsUrl: {
      type: String,
      required: true
    },
    withGrid: {
      type: Boolean,
      default: false
    },
    containerId: {
      type: Number,
      default: null
    },
    gridSize: Array
  },
  data() {
    return {
      reloadingTable: false,
      openEditModal: false,
      openImportModal: false,
      editModalMode: null,
      editStorageLocation: null,
      objectToMove: null,
      moveToUrl: null,
      assignedItems: [],
      selectedItems: [],
      selectedEmptyCells: [],
      openAssignModal: false,
      assignToContainer: null,
      rowIdToMove: null,
      rowNameToMove: null,
      cellIdToUnassign: null,
      assignMode: 'assign',
      storageLocationUnassignDescription: ''
    };
  },
  computed: {
    paginationMode() {
      return this.withGrid ? 'none' : 'pages';
    },
    assignToPositions() {
      if (this.assignMode === 'assign' && this.withGrid) {
        return this.selectedEmptyCells.map((cell) => [cell.row + 1, cell.column + 1, { occupied: false }]).concat(
          this.selectedItems.map((item) => [item.position[0], item.position[1], { occupied: true, id: item.id }])
        );
      }
      return [];
    },
    rowsList() {
      return Array.from({ length: this.gridSize[0] }, (v, i) => String.fromCharCode(97 + i));
    },
    tableId() {
      return this.withGrid ? 'StorageLocationsContainerGrid' : 'StorageLocationsContainer';
    },
    columnDefs() {
      let columns = [];

      if (this.withGrid) {
        columns.push({
          field: 'position_formatted',
          headerName: this.i18n.t('storage_locations.show.table.position'),
          sortable: true,
          cellClass: 'text-sn-blue cursor-pointer'
        });
      }

      columns = columns.concat(
        [
          {
            field: 'reminders',
            headerName: this.i18n.t('storage_locations.show.table.reminders'),
            sortable: false,
            cellRenderer: RemindersRender
          },
          {
            field: 'row_code',
            headerName: this.i18n.t('storage_locations.show.table.row_id'),
            sortable: true
          },
          {
            field: 'row_name',
            headerName: this.i18n.t('storage_locations.show.table.row_name'),
            sortable: true,
            cellRenderer: ItemNameRenderer
          },
          {
            field: 'stock',
            headerName: this.i18n.t('storage_locations.show.table.stock'),
            sortable: false
          }
        ]
      );

      return columns;
    },
    toolbarActions() {
      const left = [];

      if (this.canManage) {
        left.push({
          name: 'assign',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('storage_locations.show.toolbar.assign'),
          type: 'emit',
          buttonStyle: 'btn btn-primary'
        });

        left.push({
          name: 'import',
          icon: 'sn-icon sn-icon-import',
          label: this.i18n.t('storage_locations.show.import_modal.import_button'),
          type: 'emit',
          buttonStyle: 'btn btn-light'
        });
      }

      return {
        left,
        right: []
      };
    }
  },
  methods: {
    updateTable() {
      this.reloadingTable = true;
    },
    handleTableReload(items, params) {
      this.reloadingTable = false;
      if (!params.filtered) {
        this.assignedItems = items;
      }
    },
    resetTableSearch() {
      this.$refs.table.searchValue = '';
    },
    selectRow(row) {
      if (this.$refs.table.selectedRows.includes(row)) {
        this.$refs.table.selectedRows = this.$refs.table.selectedRows.filter((r) => r !== row);
      } else {
        this.$refs.table.selectedRows.push(row);
      }
      this.$refs.table.restoreSelection();
    },
    selectEmptyCell(cell) {
      if (this.selectedEmptyCells.find((c) => c.row === cell.row && c.column === cell.column)) {
        this.selectedEmptyCells = this.selectedEmptyCells.filter((c) => c.row !== cell.row || c.column !== cell.column);
      } else {
        this.selectedEmptyCells.push(cell);
      }
    },
    assignRow() {
      this.openAssignModal = true;
      this.rowIdToMove = null;
      this.rowNameToMove = null;
      this.assignToContainer = this.containerId;
      this.assignToPositions = [];
      this.cellIdToUnassign = null;
      this.assignMode = 'assign';
    },
    assignCallback() {
      this.openAssignModal = false;
      this.resetTableSearch();
      this.reloadingTable = true;
      this.selectedEmptyCells = [];
    },
    moveRow(_event, data) {
      this.assignMode = 'move';
      this.openAssignModal = true;
      this.rowIdToMove = data[0].row_id;
      this.rowNameToMove = data[0].row_name || this.i18n.t('storage_locations.show.hidden');
      this.assignToContainer = null;
      this.assignToPosition = null;
      this.cellIdToUnassign = data[0].id;
    },
    unselectRow(row) {
      this.selectedEmptyCells = this.selectedEmptyCells.filter((cell) => cell.row !== this.rowsList.indexOf(row));
      this.$refs.table.selectedRows = this.$refs.table.selectedRows.filter((r) => r.position[0] !== this.rowsList.indexOf(row) + 1);
      this.$refs.table.restoreSelection();
    },
    unselectColumn(column) {
      this.selectedEmptyCells = this.selectedEmptyCells.filter((cell) => cell.column !== column - 1);
      this.$refs.table.selectedRows = this.$refs.table.selectedRows.filter((r) => r.position[1] !== column);
      this.$refs.table.restoreSelection();
    },
    async unassignRows(event, rows) {
      this.storageLocationUnassignDescription = this.i18n.t(
        'storage_locations.show.unassign_modal.description',
        { items: rows.length }
      );
      const ok = await this.$refs.unassignStorageLocationModal.show();
      if (ok) {
        axios.post(event.path).then(() => {
          this.resetTableSearch();
          this.reloadingTable = true;
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.error, 'danger');
        });
      }
    }
  }
};

</script>
