<template>
  <div class="h-full">
    <DataTable v-if="loadedColumns"
               :columnDefs="columnDefs"
               tableId="Repository"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :currentViewMode="currentViewMode"
               :toolbarActions="toolbarActions"
               :activePageUrl="activePageUrl"
               :archivedPageUrl="archivedPageUrl"
               :actionsUrl="actionsUrl"
               @tableReloaded="reloadingTable = false"
    />
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';
import ConfirmationModal from '../shared/confirmation_modal.vue';
import DataTable from '../shared/datatable/table.vue';

export default {
  name: 'RepositoriesTable',
  components: {
    DataTable,
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
    columnsUrl: {
      type: String,
      required: true
    },
    currentViewMode: {
      type: String,
      required: true
    },
    activePageUrl: {
      type: String,
      required: true
    },
    archivedPageUrl: {
      type: String,
      required: true
    },
    linkedRepository: {
      type: Boolean,
      required: false
    }
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
      const columns = [{
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
        sortable: true
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

      if (this.currentViewMode === 'archived') {
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

      if (this.linkedRepository) {
        columns.push({
          field: 'extrnal_id',
          headerName: this.i18n.t('repositories.table.external_id'),
          sortable: true
        });
      }

      this.customColumns.forEach((column) => {
        columns.push({
          field: 'col_' + column.id,
          headerName: column.attributes.name,
          sortable: true
        });
      });

      return columns;
    },
    toolbarActions() {
      const left = [];
      return {
        left,
        right: []
      };
    }
  },
  methods: {
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
