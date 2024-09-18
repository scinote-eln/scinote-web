<template>
  <div class="h-full">
    <DataTable :columnDefs="columnDefs"
               tableId="Repositories"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :currentViewMode="currentViewMode"
               :toolbarActions="toolbarActions"
               :activePageUrl="activePageUrl"
               :archivedPageUrl="archivedPageUrl"
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
  <ConfirmationModal
    :title="deleteModal.title"
    :description="deleteModal.description"
    confirmClass="btn btn-danger"
    :confirmText="i18n.t('repositories.index.modal_delete.delete')"
    ref="deleteModal"
    :e2eAttributes="deleteModal.e2eAttributes"
  ></ConfirmationModal>
  <ExportRepositoryModal
    v-if="exportRepository"
    :rows="exportRepository"
    :exportAction="exportAction"
    @close="exportRepository = null; exportAction = null"
    @export="updateTable"
  ></ExportRepositoryModal>
  <NewRepositoryModal
    v-if="newRepository"
    :createUrl="createUrl"
    @close="newRepository = false"
    @create="updateTable" />
  <EditRepositoryModal
    v-if="editRepository"
    :repository="editRepository"
    @close="editRepository = null"
    @update="updateTable" />
  <DuplicateRepositoryModal
    v-if="duplicateRepository"
    :repository="duplicateRepository"
    @close="duplicateRepository = null"
    @duplicate="updateTable" />
  <ShareObjectModal
    v-if="shareRepository"
    :object="shareRepository"
    :globalShareEnabled="true"
    @close="shareRepository = null"
    @share="updateTable" />
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';
import ConfirmationModal from '../shared/confirmation_modal.vue';
import ExportRepositoryModal from './modals/export.vue';
import NewRepositoryModal from './modals/new.vue';
import EditRepositoryModal from './modals/edit.vue';
import DuplicateRepositoryModal from './modals/duplicate.vue';
import ShareObjectModal from '../shared/share_modal.vue';
import DataTable from '../shared/datatable/table.vue';
import NameRenderer from './renderers/name.vue';

export default {
  name: 'RepositoriesTable',
  components: {
    DataTable,
    ConfirmationModal,
    ExportRepositoryModal,
    NewRepositoryModal,
    EditRepositoryModal,
    DuplicateRepositoryModal,
    NameRenderer,
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
    createUrl: {
      type: String
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
    }
  },
  data() {
    return {
      reloadingTable: false,
      exportRepository: null,
      newRepository: false,
      editRepository: null,
      duplicateRepository: null,
      shareRepository: null,
      exportAction: null,
      deleteModal: {
        title: '',
        description: '',
        e2eAttributes: {
          modalName: '',
          title: '',
          close: '',
          cancel: '',
          confirm: ''
        }
      },
      exportModal: {
        title: '',
        description: ''
      }
    };
  },
  computed: {
    columnDefs() {
      const columns = [{
        field: 'name',
        headerName: this.i18n.t('libraries.index.table.name'),
        sortable: true,
        notSelectable: true,
        cellRenderer: 'NameRenderer'
      },
      {
        field: 'code',
        headerName: this.i18n.t('libraries.index.table.id'),
        sortable: true
      },
      {
        field: 'nr_of_rows',
        headerName: this.i18n.t('libraries.index.table.number_of_items'),
        sortable: true
      },
      {
        field: 'shared_label',
        headerName: this.i18n.t('libraries.index.table.shared'),
        sortable: true
      },
      {
        field: 'team',
        headerName: this.i18n.t('libraries.index.table.ownership'),
        sortable: true
      },
      {
        field: 'created_at',
        headerName: this.i18n.t('libraries.index.table.added_on'),
        sortable: true
      },
      {
        field: 'created_by',
        headerName: this.i18n.t('libraries.index.table.added_by'),
        sortable: true
      }];

      if (this.currentViewMode === 'archived') {
        columns.push({
          field: 'archived_on',
          headerName: this.i18n.t('libraries.index.table.archived_on'),
          sortable: true
        });
        columns.push({
          field: 'archived_by',
          headerName: this.i18n.t('libraries.index.table.archived_by'),
          sortable: true
        });
      }

      return columns;
    },
    toolbarActions() {
      const left = [];
      if (this.createUrl && this.currentViewMode !== 'archived') {
        left.push({
          name: 'create',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('libraries.index.no_libraries.create_new_button'),
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
    updateTable() {
      this.reloadingTable = true;
      this.newRepository = false;
      this.editRepository = null;
      this.duplicateRepository = null;
      this.shareRepository = null;
      this.exportRepository = null;
      this.exportAction = null;
    },
    archive(event, rows) {
      axios.post(event.path, { repository_ids: rows.map((row) => row.id) }).then((response) => {
        this.updateTable();
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    restore(event, rows) {
      axios.post(event.path, { repository_ids: rows.map((row) => row.id) }).then((response) => {
        this.updateTable();
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    async deleteRepository(event, rows) {
      const [repository] = rows;
      this.deleteModal.e2eAttributes = {
        modalName: 'e2e-MD-deleteInventory',
        title: 'e2e-TX-deleteInventoryModal-title',
        close: 'e2e-BT-deleteInventoryModal-close',
        cancel: 'e2e-BT-deleteInventoryModal-cancel',
        confirm: 'e2e-BT-deleteInventoryModal-delete'
      };
      this.deleteModal.title = this.i18n.t('repositories.index.modal_delete.title_html', { name: repository.name });
      this.deleteModal.description = `
        <p data-e2e="e2e-TX-deleteInventoryModal-info">${this.i18n.t('repositories.index.modal_delete.message_html', { name: repository.name })}</p>
        <div class="alert alert-danger" role="alert" data-e2e="e2e-TX-deleteInventoryModal-warning">
          <span class="fas fa-exclamation-triangle"></span>
          ${this.i18n.t('repositories.index.modal_delete.alert_heading')}
          <ul>
            <li>${this.i18n.t('repositories.index.modal_delete.alert_line_1')}</li>
            <li>${this.i18n.t('repositories.index.modal_delete.alert_line_2')}</li>
          </ul>
        </div>
      `;

      const ok = await this.$refs.deleteModal.show();
      if (ok) {
        axios.delete(event.path).then((response) => {
          this.updateTable();
          HelperModule.flashAlertMsg(response.data.message, 'success');
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.error, 'danger');
        });
      }
    },
    exportRepositories(action, rows) {
      this.exportRepository = rows;
      this.exportAction = action;
    },
    update(_event, rows) {
      const [repository] = rows;
      this.editRepository = repository;
    },
    duplicate(_event, rows) {
      const [repository] = rows;
      this.duplicateRepository = repository;
    },
    share(_event, rows) {
      const [repository] = rows;
      this.shareRepository = repository;
    }
  }
};

</script>
