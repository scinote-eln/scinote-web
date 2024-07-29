<template>
  <div class="grid w-full h-full gap-6" :class="{ 'grid-cols-2': withGrid }">
    <div v-if="withGrid">
      <div class="py-4">
        <div class="h-11">
          <button class="btn btn-primary" @click="assignRow">
            <i class="sn-icon sn-icon-new-task"></i>
            {{ i18n.t('storage_locations.show.toolbar.assign') }}
          </button>
        </div>
      </div>
      <Grid :gridSize="gridSize" :assignedItems="assignedItems" @assign="assignRowToPosition"/>
    </div>
    <div class="h-full bg-white p-4">
      <DataTable :columnDefs="columnDefs"
                tableId="StorageLocationsContainer"
                :dataUrl="dataSource"
                ref="table"
                :reloadingTable="reloadingTable"
                :toolbarActions="toolbarActions"
                :actionsUrl="actionsUrl"
                :scrollMode="paginationMode"
                @assign="assignRow"
                @move="moveRow"
                @unassign="unassignRows"
                @tableReloaded="handleTableReload"
      />
    </div>
    <Teleport to="body">
      <AssignModal
        v-if="openAssignModal"
        :assignMode="assignMode"
        :selectedContainer="assignToContainer"
        :selectedPosition="assignToPosition"
        :selectedRow="rowIdToMove"
        :cellId="cellIdToUnassign"
        :withGrid="withGrid"
        @close="openAssignModal = false; this.reloadingTable = true"
      ></AssignModal>
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
import ConfirmationModal from '../shared/confirmation_modal.vue';

export default {
  name: 'StorageLocationsContainer',
  components: {
    DataTable,
    Grid,
    AssignModal,
    ConfirmationModal
  },
  props: {
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
      editModalMode: null,
      editStorageLocation: null,
      objectToMove: null,
      moveToUrl: null,
      assignedItems: [],
      openAssignModal: false,
      assignToPosition: null,
      assignToContainer: null,
      rowIdToMove: null,
      cellIdToUnassign: null,
      assignMode: 'assign',
      storageLocationUnassignDescription: ''
    };
  },
  computed: {
    paginationMode() {
      return this.withGrid ? 'none' : 'pages';
    },
    columnDefs() {
      const columns = [{
        field: 'position',
        headerName: this.i18n.t('storage_locations.show.table.position'),
        sortable: true,
        notSelectable: true,
        cellRenderer: this.nameRenderer
      },
      {
        field: 'reminders',
        headerName: this.i18n.t('storage_locations.show.table.reminders'),
        sortable: true
      },
      {
        field: 'row_id',
        headerName: this.i18n.t('storage_locations.show.table.row_id'),
        sortable: true
      },
      {
        field: 'row_name',
        headerName: this.i18n.t('storage_locations.show.table.row_name'),
        sortable: true
      },
      {
        field: 'stock',
        headerName: this.i18n.t('storage_locations.show.table.stock'),
        sortable: true
      }];

      return columns;
    },
    toolbarActions() {
      const left = [];

      if (!this.withGrid) {
        left.push({
          name: 'assign',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('storage_locations.show.toolbar.assign'),
          type: 'emit',
          buttonStyle: 'btn btn-primary'
        });
      }

      return {
        left,
        right: []
      };
    }
  },
  methods: {
    handleTableReload(items) {
      this.reloadingTable = false;
      this.assignedItems = items;
    },
    assignRow() {
      this.openAssignModal = true;
      this.rowIdToMove = null;
      this.assignToContainer = this.containerId;
      this.assignToPosition = null;
      this.cellIdToUnassign = null;
      this.assignMode = 'assign';
    },
    assignRowToPosition(position) {
      this.openAssignModal = true;
      this.rowIdToMove = null;
      this.assignToContainer = this.containerId;
      this.assignToPosition = position;
      this.cellIdToUnassign = null;
      this.assignMode = 'assign';
    },
    moveRow(_event, data) {
      this.openAssignModal = true;
      this.rowIdToMove = data[0].row_id;
      this.assignToContainer = null;
      this.assignToPosition = null;
      this.cellIdToUnassign = data[0].id;
      this.assignMode = 'move';
    },
    async unassignRows(event, rows) {
      this.storageLocationUnassignDescription = this.i18n.t(
        'storage_locations.show.unassign_modal.description',
        { items: rows.length }
      );
      const ok = await this.$refs.unassignStorageLocationModal.show();
      if (ok) {
        axios.post(event.path).then(() => {
          this.reloadingTable = true;
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.error, 'danger');
        });
      }
    }
  }
};

</script>
