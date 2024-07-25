<template>
  <div class="grid w-full h-full gap-6" :class="{ 'grid-cols-2': withGrid }">
    <div v-if="withGrid">
      <div class="py-4">
        <div class="h-11">
          <button class="btn btn-primary">
            <i class="sn-icon sn-icon-new-task"></i>
            {{ i18n.t('storage_locations.show.toolbar.assign') }}
          </button>
        </div>
      </div>
      <Grid :gridSize="gridSize" :assignedItems="assignedItems" />
    </div>
    <div class="h-full bg-white p-4">
      <DataTable :columnDefs="columnDefs"
                tableId="StorageLocationsBox"
                :dataUrl="dataSource"
                ref="table"
                :reloadingTable="reloadingTable"
                :toolbarActions="toolbarActions"
                :actionsUrl="actionsUrl"
                :scrollMode="paginationMode"
                @tableReloaded="handleTableReload"
      />
    </div>
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';
import DataTable from '../shared/datatable/table.vue';
import Grid from './grid.vue';

export default {
  name: 'StorageLocationsBox',
  components: {
    DataTable,
    Grid
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
      assignedItems: []
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
    }
  }
};

</script>
