<template>
  <div class="h-full">
    <DataTable :columnDefs="columnDefs"
               tableId="StorageLocationsTable"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :toolbarActions="toolbarActions"
               :actionsUrl="actionsUrl"
               @create_location="openCreateLocationModal"
               @create_box="openCreateBoxModal"
               @edit="edit"
               @tableReloaded="reloadingTable = false"
    />
    <Teleport to="body">
      <EditModal v-if="openEditModal"
                 @close="openEditModal = false"
                 @tableReloaded="reloadingTable = true"
                 :createUrl="createUrl"
                 :editModalMode="editModalMode"
                 :directUploadUrl="directUploadUrl"
                 :editStorageLocation="editStorageLocation"
      />
    </Teleport>
  </div>
</template>

<script>
/* global */

import DataTable from '../shared/datatable/table.vue';
import EditModal from './modals/new_edit.vue';

export default {
  name: 'RepositoriesTable',
  components: {
    DataTable,
    EditModal
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
    },
    directUploadUrl: {
      type: String
    }
  },
  data() {
    return {
      reloadingTable: false,
      openEditModal: false,
      editModalMode: null,
      editStorageLocation: null
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
        field: 'sub_locations',
        headerName: this.i18n.t('storage_locations.index.table.sub_locations'),
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
    openCreateLocationModal() {
      this.openEditModal = true;
      this.editModalMode = 'location';
      this.editStorageLocation = null;
    },
    openCreateBoxModal() {
      this.openEditModal = true;
      this.editModalMode = 'box';
      this.editStorageLocation = null;
    },
    edit(action, params) {
      this.openEditModal = true;
      this.editModalMode = params[0].container ? 'box' : 'location';
      [this.editStorageLocation] = params;
    },
    // Renderers
    nameRenderer(params) {
      const {
        name,
        urls
      } = params.data;
      let boxIcon = '';
      if (params.data.container) {
        boxIcon = '<i class="sn-icon sn-icon-item"></i>';
      }
      return `<a class="hover:no-underline flex items-center gap-1"
                 title="${name}" href="${urls.show}">
                 ${boxIcon}
                 <span class="truncate">${name}</span>
              </a>`;
    }
  }
};

</script>
