<template>
  <div class="h-full">
    <DataTable :columnDefs="columnDefs"
               tableId="StorageLocationsTable"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :toolbarActions="toolbarActions"
               :actionsUrl="actionsUrl"
               @archive="archive"
               @restore="restore"
               @delete="deleteRepository"
               @update="update"
               @duplicate="duplicate"
               @export="exportRepositories"
               @share="share"
               @create="newRepository = true"
               @tableReloaded="reloadingTable = false"
    />
  </div>
</template>

<script>
/* global */

import DataTable from '../shared/datatable/table.vue';

export default {
  name: 'RepositoriesTable',
  components: {
    DataTable
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
    createUrl: {
      type: String
    }
  },
  data() {
    return {
      reloadingTable: false
    };
  },
  computed: {
    columnDefs() {
      const columns = [{
        field: 'name',
        headerName: this.i18n.t('storage_locations.index.table.name'),
        sortable: true,
        notSelectable: true,
        cellRenderer: this.nameRenderer
      },
      {
        field: 'code',
        headerName: this.i18n.t('storage_locations.index.table.id'),
        sortable: true
      },
      {
        field: 'sub_location_count',
        headerName: this.i18n.t('storage_locations.index.table.sub_locations'),
        width: 250,
        sortable: true
      },
      {
        field: 'items',
        headerName: this.i18n.t('storage_locations.index.table.items'),
        sortable: true
      },
      {
        field: 'free_spaces',
        headerName: this.i18n.t('storage_locations.index.table.free_spaces'),
        sortable: true
      },
      {
        field: 'shared',
        headerName: this.i18n.t('storage_locations.index.table.shared'),
        sortable: true
      },
      {
        field: 'owned_by',
        headerName: this.i18n.t('storage_locations.index.table.owned_by'),
        sortable: true
      },
      {
        field: 'created_on',
        headerName: this.i18n.t('storage_locations.index.table.created_on'),
        sortable: true
      },
      {
        field: 'description',
        headerName: this.i18n.t('storage_locations.index.table.description'),
        sortable: true
      }];

      return columns;
    },
    toolbarActions() {
      const left = [];
      if (this.createUrl) {
        left.push({
          name: 'create_location',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('storage_locations.index.new_location'),
          type: 'emit',
          path: this.createUrl,
          buttonStyle: 'btn btn-primary'
        });
        left.push({
          name: 'create_box',
          icon: 'sn-icon sn-icon-item',
          label: this.i18n.t('storage_locations.index.new_box'),
          type: 'emit',
          path: this.createUrl,
          buttonStyle: 'btn btn-secondary'
        });
      }
      return {
        left,
        right: []
      };
    }
  },
  methods: {
    // Renderers
    nameRenderer(params) {
      const {
        name,
        urls
      } = params.data;
      return `<a class="hover:no-underline flex items-center gap-1"
                 title="${name}" href="${urls.show}">
                 <span class="truncate">${name}</span>
              </a>`;
    }
  }
};

</script>
