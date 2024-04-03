<template>
  <div class="h-full">
    <DataTable v-if="loadedColumns"
               ref="table"
               :columnDefs="columnDefs"
               tableId="Repository"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :currentViewMode="currentViewMode"
               :toolbarActions="toolbarActions"
               :activePageUrl="activePageUrl"
               :archivedPageUrl="archivedPageUrl"
               :actionsUrl="actionsUrl"
               :withCheckboxes="!assignedView"
               :withoutToolbar="simpleView"
               @create="addRow"
               @tableReloaded="reloadingTable = false"
    />
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';
import ConfirmationModal from '../shared/confirmation_modal.vue';
import DataTable from '../shared/datatable/table.vue';

//Renderers
import RepositoryAssetValue from './renderers/asset_value.vue';
import RepositoryChecklistValue from './renderers/checklist_value.vue';
import RepositoryDateValue from './renderers/date_value.vue';
import RepositoryListValue from './renderers/list_value.vue';
import RepositoryTextValue from './renderers/text_value.vue';
import RepositoryNumberValue from './renderers/number_value.vue';
import RepositoryStatusValue from './renderers/status_value.vue';
import RepositoryTimeValue from './renderers/time_value.vue';
import RepositoryDateTimeValue from './renderers/date_time_value.vue';
import RepositoryDateRangeValue from './renderers/date_range_value.vue';
import RepositoryTimeRangeValue from './renderers/time_range_value.vue';
import RepositoryDateTimeRangeValue from './renderers/date_time_range_value.vue';
import RepositoryStockValue from './renderers/stock_value.vue';
import AssignedRenderer from './renderers/assigned.vue';

export default {
  name: 'RepositoriesTable',
  components: {
    DataTable,
    ConfirmationModal,
    RepositoryAssetValue,
    RepositoryChecklistValue,
    RepositoryDateValue,
    RepositoryListValue,
    RepositoryTextValue,
    RepositoryNumberValue,
    RepositoryStatusValue,
    RepositoryTimeValue,
    RepositoryDateTimeValue,
    RepositoryDateRangeValue,
    RepositoryTimeRangeValue,
    RepositoryDateTimeRangeValue,
    RepositoryStockValue,
    AssignedRenderer
  },
  props: {
    dataSource: {
      type: String,
      required: true
    },
    createUrl: {
      type: String
    },
    actionsUrl: {
      type: String,
      required: true
    },
    columnsUrl: {
      type: String,
      required: true
    },
    currentViewMode: String,
    activePageUrl: String,
    archivedPageUrl: String,
    linkedRepository: Boolean,
    readOnly: Boolean,
    assignedView: Boolean,
    simpleView: Boolean
  },
  created() {
    this.loadColumns();
  },
  data() {
    return {
      reloadingTable: false,
      customColumns: [],
      loadedColumns: false
    };
  },
  computed: {
    columnDefs() {
      let columns;
      if (this.simpleView) {
        columns = [{
          field: 'name',
          headerName: this.i18n.t('repositories.table.row_name'),
          sortable: true,
          notSelectable: true
        }]
      } else {
        columns = [{
          field: 'name',
          headerName: this.i18n.t('repositories.table.row_name'),
          sortable: true,
          notSelectable: true
        },
        {
          field: 'code',
          headerName: this.i18n.t('repositories.table.id'),
          sortable: true
        },
        {
          field: 'assigned',
          headerName: this.i18n.t('repositories.table.assigned'),
          sortable: true,
          cellRenderer: 'AssignedRenderer'
        },
        {
          field: 'connections',
          headerName: this.i18n.t('repositories.table.relationships')
        },
        {
          field: 'created_at',
          headerName: this.i18n.t('repositories.table.added_on'),
          sortable: true
        },
        {
          field: 'created_by',
          headerName: this.i18n.t('repositories.table.added_by'),
          sortable: true
        }];
      }

      if (this.currentViewMode === 'archived' && !this.simpleView) {
        columns.push({
          field: 'archived_on',
          headerName: this.i18n.t('repositories.table.archived_on'),
          sortable: true
        });
        columns.push({
          field: 'archived_by',
          headerName: this.i18n.t('repositories.table.archived_by'),
          sortable: true
        });
      }

      if (this.linkedRepository && !this.simpleView) {
        columns.push({
          field: 'extrnal_id',
          headerName: this.i18n.t('repositories.table.external_id'),
          sortable: true
        });
      }

      this.customColumns.forEach((column) => {
        if (!this.simpleView || column.attributes.data_type === 'RepositoryStockValue') {
          columns.push({
            field: `col_${column.id}`,
            headerName: column.attributes.name,
            sortable: true,
            cellRenderer: column.attributes.data_type,
            notSelectable: true,
            columnId: column.id,
            columnItems: column.attributes.column_items,
            readOnly: this.readOnly
          });
        }
      });

      return columns;
    },
    toolbarActions() {
      const left = [];
      if (this.createUrl) {
        left.push({
          name: 'create',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('repositories.add_new_record'),
          type: 'emit',
          path: this.createUrl,
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
    addRow() {
      axios.post(this.createUrl, { repository_row: { name: 'New item' } })
        .then((response) => {
          this.reloadingTable = true;
        });
    },
    loadColumns() {
      axios.get(this.columnsUrl)
        .then((response) => {
          this.customColumns = response.data.data;
          this.loadedColumns = true;
        })
        .catch((error) => {
          HelperModule.handleError(error);
        });
    }
  }
};

</script>
