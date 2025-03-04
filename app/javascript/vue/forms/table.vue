<template>
  <div class="h-full">
    <DataTable :columnDefs="columnDefs"
               :tableId="'FormsTable'"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :toolbarActions="toolbarActions"
               :activePageUrl="activePageUrl"
               :archivedPageUrl="archivedPageUrl"
               :currentViewMode="currentViewMode"
               :actionsUrl="actionsUrl"
               @tableReloaded="reloadingTable = false"
               @create="createForm"
               @archive="archive"
               @duplicate="duplicate"
               @restore="restore"
               @access="access"
               @export="exportFormResponse"
      />
  </div>
  <AccessModal v-if="accessModalParams" :params="accessModalParams"
               @close="accessModalParams = null" @refresh="this.reloadingTable = true" />
  <ConfirmationModal
    :title="i18n.t('forms.export.title')"
    :description="i18n.t('forms.export.description')"
    confirmClass="btn btn-primary"
    :confirmText="i18n.t('forms.export.export_button')"
    ref="exportModal"
  ></ConfirmationModal>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';

import DataTable from '../shared/datatable/table.vue';
import DeleteModal from '../shared/confirmation_modal.vue';
import ConfirmationModal from '../shared/confirmation_modal.vue';
import NameRenderer from './renderers/name.vue';
import UsersRenderer from '../projects/renderers/users.vue';

import AccessModal from '../shared/access_modal/modal.vue';


export default {
  name: 'FormsTable',
  components: {
    DataTable,
    DeleteModal,
    NameRenderer,
    UsersRenderer,
    AccessModal,
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
    userRolesUrl: {
      type: String,
      required: true
    },
    activePageUrl: { type: String },
    archivedPageUrl: { type: String },
    currentViewMode: { type: String, required: true }
  },
  data() {
    return {
      reloadingTable: false,
      accessModalParams: null,
      submitting: false,
      columnDefs: [
        {
          field: 'name',
          headerName: this.i18n.t('forms.index.table.name'),
          cellRenderer: 'NameRenderer',
          sortable: true
        }, {
          field: 'code',
          headerName: this.i18n.t('forms.index.table.code'),
          sortable: true
        }, {
          field: 'versions',
          headerName: this.i18n.t('forms.index.table.versions'),
          sortable: true
        }, {
          field: 'used_in_protocols',
          headerName: this.i18n.t('forms.index.table.used_in_protocols'),
          sortable: true
        }, {
          field: 'assigned_users',
          headerName: this.i18n.t('forms.index.table.access'),
          sortable: true,
          cellRenderer: 'UsersRenderer',
          minWidth: 210,
          notSelectable: true
        }, {
          field: 'published_by',
          headerName: this.i18n.t('forms.index.table.published_by'),
          sortable: true
        }, {
          field: 'published_on',
          headerName: this.i18n.t('forms.index.table.published_on'),
          sortable: true
        }, {
          field: 'updated_at',
          headerName: this.i18n.t('forms.index.table.updated_on'),
          sortable: true
        }
      ]
    };
  },
  computed: {
    toolbarActions() {
      const left = [];
      if (this.createUrl) {
        left.push({
          name: 'create',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('forms.index.toolbar.new'),
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
    createForm(action) {
      if (this.submitting) {
        return;
      }

      this.submitting = true;

      axios.post(action.path).then((response) => {
        window.location.href = response.data.data.attributes.urls.show;
      }).catch(() => {
        this.submitting = false;
      });
    },
    access(_event, rows) {
      this.accessModalParams = {
        object: rows[0],
        roles_path: this.userRolesUrl
      };
    },
    archive(event) {
      if (this.submitting) {
        return;
      }

      this.submitting = true;
      axios.post(event.path).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      }).finally(() => {
        this.submitting = false;
      });
    },
    duplicate(event) {
      if (this.submitting) {
        return;
      }

      this.submitting = true;
      axios.post(event.path).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      }).finally(() => {
        this.submitting = false;
      });
    },
    restore(event) {
      if (this.submitting) {
        return;
      }

      this.submitting = true;
      axios.post(event.path).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      }).finally(() => {
        this.submitting = false;
      });
    },
    async exportFormResponse(event) {
      const ok = await this.$refs.exportModal.show();
      if (ok) {
        axios.post(event.path).then((response) => {
          this.reloadingTable = true;
          HelperModule.flashAlertMsg(response.data.message, 'success');
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.error, 'danger');
        });
      }
    }
  }
};

</script>
