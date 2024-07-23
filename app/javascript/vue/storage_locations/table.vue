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
               @duplicate="duplicate"
               @tableReloaded="reloadingTable = false"
               @move="move"
               @delete="deleteStorageLocation"
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
      <MoveModal v-if="objectToMove" :moveToUrl="moveToUrl"
             :selectedObject="objectToMove" :storageLocationTreeUrl="storageLocationTreeUrl"
             @close="objectToMove = null" @move="updateTable()" />
      <ConfirmationModal
        :title="storageLocationDeleteTitle"
        :description="storageLocationDeleteDescription"
        confirmClass="btn btn-danger"
        :confirmText="i18n.t('general.delete')"
        ref="deleteStorageLocationModal"
      ></ConfirmationModal>
    </Teleport>
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';
import DataTable from '../shared/datatable/table.vue';
import EditModal from './modals/new_edit.vue';
import MoveModal from './modals/move.vue';
import ConfirmationModal from '../shared/confirmation_modal.vue';

export default {
  name: 'RepositoriesTable',
  components: {
    DataTable,
    EditModal,
    MoveModal,
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
    createUrl: {
      type: String
    },
    directUploadUrl: {
      type: String
    },
    storageLocationTreeUrl: {
      type: String
    }
  },
  data() {
    return {
      reloadingTable: false,
      openEditModal: false,
      editModalMode: null,
      editStorageLocation: null,
      objectToMove: null,
      moveToUrl: null,
      storageLocationDeleteTitle: '',
      storageLocationDeleteDescription: ''
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
    duplicate(action) {
      axios.post(action.path)
        .then(() => {
          this.reloadingTable = true;
          HelperModule.flashAlertMsg(this.i18n.t('storage_locations.index.duplicate.success_message'), 'success');
        })
        .catch(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        });
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
    },
    updateTable() {
      this.reloadingTable = true;
      this.objectToMove = null;
    },
    move(event, rows) {
      [this.objectToMove] = rows;
      this.moveToUrl = event.path;
    },
    async deleteStorageLocation(event, rows) {
      const storageLocationType = rows[0].container ? this.i18n.t('storage_locations.box') : this.i18n.t('storage_locations.location');
      const description = `
        <p>${this.i18n.t('storage_locations.index.delete_modal.description_1_html',
    { name: rows[0].name, type: storageLocationType, num_of_items: event.number_of_items })}</p>
        <p>${this.i18n.t('storage_locations.index.delete_modal.description_2_html')}</p>`;

      this.storageLocationDeleteDescription = description;
      this.storageLocationDeleteTitle = this.i18n.t('storage_locations.index.delete_modal.title', { type: storageLocationType });
      const ok = await this.$refs.deleteStorageLocationModal.show();
      if (ok) {
        axios.delete(event.path).then((_) => {
          this.reloadingTable = true;
          HelperModule.flashAlertMsg(this.i18n.t('storage_locations.index.delete_modal.success_message',
            {
              type: storageLocationType[0].toUpperCase() + storageLocationType.slice(1),
              name: rows[0].name
            }), 'success');
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.error, 'danger');
        });
      }
    }
  }
};

</script>
