<template>
  <div class="h-full">
    <DataTable :columnDefs="columnDefs"
               tableId="StorageLocationsTable"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :toolbarActions="toolbarActions"
               :actionsUrl="actionsUrl"
               :filters="filters"
               @create_location="openCreateLocationModal"
               @create_container="openCreateContainerModal"
               @edit="edit"
               @duplicate="duplicate"
               @tableReloaded="reloadingTable = false"
               @move="move"
               @delete="deleteStorageLocation"
               @share="share"
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
             :selectedObject="objectToMove"
             @close="objectToMove = null" @move="updateTable()" />
      <ConfirmationModal
        :title="storageLocationDeleteTitle"
        :description="storageLocationDeleteDescription"
        confirmClass="btn btn-danger"
        :confirmText="i18n.t('general.delete')"
        ref="deleteStorageLocationModal"
      ></ConfirmationModal>
      <ShareObjectModal
        v-if="shareStorageLocation"
        :object="shareStorageLocation"
        @close="shareStorageLocation = null"
        @share="updateTable" />
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
import ShareObjectModal from '../shared/share_modal.vue';

export default {
  name: 'RepositoriesTable',
  components: {
    DataTable,
    EditModal,
    MoveModal,
    ConfirmationModal,
    ShareObjectModal
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
    createLocationUrl: {
      type: String
    },
    createLocationInstanceUrl: {
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
      editStorageLocation: null,
      objectToMove: null,
      moveToUrl: null,
      shareStorageLocation: null,
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
      if (this.createLocationUrl) {
        left.push({
          name: 'create_location',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('storage_locations.index.new_location'),
          type: 'emit',
          path: this.createLocationUrl,
          buttonStyle: 'btn btn-primary'
        });
      }

      if (this.createLocationInstanceUrl) {
        left.push({
          name: 'create_container',
          icon: 'sn-icon sn-icon-item',
          label: this.i18n.t('storage_locations.index.new_container'),
          type: 'emit',
          path: this.createLocationInstanceUrl,
          buttonStyle: 'btn btn-secondary'
        });
      }
      return {
        left,
        right: []
      };
    },
    filters() {
      const filters = [
        {
          key: 'query',
          type: 'Text'
        },
        {
          key: 'search_tree',
          type: 'Checkbox',
          label: this.i18n.t('storage_locations.index.filters_modal.search_tree')
        }
      ];

      return filters;
    },
    createUrl() {
      return this.editModalMode === 'location' ? this.createLocationUrl : this.createLocationInstanceUrl;
    }
  },
  methods: {
    openCreateLocationModal() {
      this.openEditModal = true;
      this.editModalMode = 'location';
      this.editStorageLocation = null;
    },
    openCreateContainerModal() {
      this.openEditModal = true;
      this.editModalMode = 'container';
      this.editStorageLocation = null;
    },
    edit(action, params) {
      this.openEditModal = true;
      this.editModalMode = params[0].container ? 'container' : 'location';
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
        urls,
        shared,
        ishared
      } = params.data;
      let containerIcon = '';
      if (params.data.container) {
        containerIcon = '<i class="sn-icon sn-icon-item"></i>';
      }
      let sharedIcon = '';
      if (shared || ishared) {
        sharedIcon = '<i class="fas fa-users"></i>';
      }
      return `<a class="hover:no-underline flex items-center gap-1"
                 title="${name}" href="${urls.show}">
                 ${sharedIcon}${containerIcon}
                 <span class="truncate">${name}</span>
              </a>`;
    },
    updateTable() {
      this.reloadingTable = true;
      this.objectToMove = null;
      this.shareStorageLocation = null;
    },
    move(event, rows) {
      [this.objectToMove] = rows;
      this.moveToUrl = event.path;
    },
    async deleteStorageLocation(event, rows) {
      const storageLocationType = rows[0].container ? this.i18n.t('storage_locations.container') : this.i18n.t('storage_locations.location');
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
    },
    share(_event, rows) {
      const [storageLocation] = rows;
      this.shareStorageLocation = storageLocation;
    }
  }
};

</script>
