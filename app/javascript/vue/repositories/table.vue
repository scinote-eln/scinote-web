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
  ></ConfirmationModal>
  <ConfirmationModal
    :title="exportModal.title"
    :description="exportModal.description"
    confirmClass="btn btn-primary"
    :confirmText="i18n.t('repositories.index.modal_export.export')"
    ref="exportModal"
  ></ConfirmationModal>
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
  <ShareRepositoryModal
    v-if="shareRepository"
    :repository="shareRepository"
    @close="shareRepository = null"
    @share="updateTable" />
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';
import ConfirmationModal from '../shared/confirmation_modal.vue';
import NewRepositoryModal from './modals/new.vue';
import EditRepositoryModal from './modals/edit.vue';
import DuplicateRepositoryModal from './modals/duplicate.vue';
import ShareRepositoryModal from './modals/share.vue';
import DataTable from '../shared/datatable/table.vue';

export default {
  name: 'RepositoriesTable',
  components: {
    DataTable,
    ConfirmationModal,
    NewRepositoryModal,
    EditRepositoryModal,
    DuplicateRepositoryModal,
    ShareRepositoryModal
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
      newRepository: false,
      editRepository: null,
      duplicateRepository: null,
      shareRepository: null,
      deleteModal: {
        title: '',
        description: ''
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
        cellRenderer: this.nameRenderer
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
        headerName: this.i18n.t('libraries.index.table.shared')
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
      if (this.createUrl) {
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
    async exportRepositories(event, rows) {
      this.exportModal.title = this.i18n.t('repositories.index.modal_export.title');
      this.exportModal.description = `
        <p class="description-p1">
          ${this.i18n.t('repositories.index.modal_export.description_p1_html', {
    team_name: rows[0].team,
    count: rows.length
  })}
        </p>
        <p class="bg-sn-super-light-blue p-3">
          ${this.i18n.t('repositories.index.modal_export.description_alert')}
        </p>
        <p class="mt-3">
          ${this.i18n.t('repositories.index.modal_export.description_p2')}
        </p>
        <p>
          ${this.i18n.t('repositories.index.modal_export.description_p3_html', {
    remaining_export_requests: event.num_of_requests_left,
    requests_limit: event.export_limit
  })}
        </p>
      `;

      const ok = await this.$refs.exportModal.show();

      if (ok) {
        axios.post(event.path, { repository_ids: rows.map((row) => row.id) }).then((response) => {
          HelperModule.flashAlertMsg(response.data.message, 'success');
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.error, 'danger');
        });
      }
    },
    async deleteRepository(event, rows) {
      const [repository] = rows;
      this.deleteModal.title = this.i18n.t('repositories.index.modal_delete.title_html', { name: repository.name });
      this.deleteModal.description = `
        <p>${this.i18n.t('repositories.index.modal_delete.message_html', { name: repository.name })}</p>
        <div class="alert alert-danger" role="alert">
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
    },
    // Renderers
    nameRenderer(params) {
      const {
        name,
        urls,
        shared,
        ishared
      } = params.data;
      let sharedIcon = '';
      if (shared || ishared) {
        sharedIcon = '<i class="fas fa-users"></i>';
      }
      return `<a class="hover:no-underline flex items-center gap-1"
                 title="${name}" href="${urls.show}">
                 <span class="truncate">${sharedIcon}${name}</span>
              </a>`;
    }
  }
};

</script>
