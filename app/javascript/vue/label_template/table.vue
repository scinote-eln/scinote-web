<template>
  <div class="h-full">
    <DataTable :columnDefs="columnDefs"
               :tableId="'LabelTemplates'"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :toolbarActions="toolbarActions"
               :actionsUrl="actionsUrl"
               @tableReloaded="reloadingTable = false"
               @set_as_default="setDefault"
               @duplicate="duplicate"
               @create="createTemplate"
               @sync_fluics="syncFluicsLabels"
               @delete="deleteTemplates"
      />
      <DeleteModal
        :title="i18n.t('label_templates.index.delete_modal.title')"
        :description="i18n.t('label_templates.index.delete_modal.description')"
        :confirmClass="'btn btn-danger'"
        :confirmText="i18n.t('general.delete')"
        ref="deleteModal"
      ></DeleteModal>
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';

import DataTable from '../shared/datatable/table.vue';
import DeleteModal from '../shared/confirmation_modal.vue';

export default {
  name: 'LabelTemplatesTable',
  components: {
    DataTable,
    DeleteModal,
  },
  props: {
    dataSource: {
      type: String,
      required: true,
    },
    actionsUrl: {
      type: String,
      required: true,
    },
    createUrl: {
      type: String,
    },
    syncFluicsUrl: {
      type: String,
    },
  },
  data() {
    return {
      reloadingTable: false,
      columnDefs: [
        {
          field: 'default',
          headerName: this.i18n.t('label_templates.index.default_label'),
          cellRenderer: this.defaultRenderer,
          sortable: true,
        }, {
          field: 'name',
          headerName: this.i18n.t('label_templates.index.thead_name'),
          cellRenderer: this.labelNameRenderer,
          sortable: true,
        }, {
          field: 'format',
          headerName: this.i18n.t('label_templates.index.format'),
          sortable: true,
          cellRenderer: ({ data: { format, icon_url: iconUrl } }) => `<span>${iconUrl}</span> <span>${format}</span>`
        }, {
          field: 'description',
          headerName: this.i18n.t('label_templates.index.description'),
          sortable: true,
        }, {
          field: 'modified_by',
          headerName: this.i18n.t('label_templates.index.updated_by'),
          sortable: true,
        }, {
          field: 'updated_at',
          headerName: this.i18n.t('label_templates.index.updated_at'),
          sortable: true,
        }, {
          field: 'created_by',
          headerName: this.i18n.t('label_templates.index.created_by'),
          sortable: true,
        }, {
          field: 'created_at',
          headerName: this.i18n.t('label_templates.index.created_at'),
          sortable: true,
        },
      ],
    };
  },
  computed: {
    toolbarActions() {
      const left = [];
      if (this.createUrl) {
        left.push({
          name: 'create',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('label_templates.index.toolbar.new'),
          type: 'emit',
          path: this.createUrl,
          buttonStyle: 'btn btn-primary',
        });
      }
      if (this.syncFluicsUrl) {
        left.push({
          name: 'sync_fluics',
          icon: 'sn-icon sn-icon-refresh',
          label: this.i18n.t('label_templates.index.toolbar.update_fluics_labels'),
          type: 'emit',
          path: this.syncFluicsUrl,
          buttonStyle: 'btn btn-light'
        });
      }
      return {
        left,
        right: [],
      };
    },
  },
  methods: {
    labelNameRenderer(params) {
      const editUrl = params.data.urls.show;
      return `<a href="${editUrl}" title="${params.data.name}">
                ${params.data.name}
              </a>`;
    },
    defaultRenderer(params) {
      const defaultSelected = params.data.default;
      return defaultSelected ? '<i class="sn-icon sn-icon-approval"></i>' : '';
    },
    setDefault(action) {
      axios.post(action.path).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    duplicate(action, rows) {
      axios.post(action.path, { selected_ids: rows.map((row) => row.id) }).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    createTemplate(action) {
      axios.post(action.path).then((response) => {
        window.location.href = response.data.redirect_url;
      });
    },
    syncFluicsLabels(action) {
      axios.post(action.path).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    async deleteTemplates(action, rows) {
      const ok = await this.$refs.deleteModal.show();
      if (ok) {
        axios.delete(action.path, { data: { selected_ids: rows.map((row) => row.id) } }).then((response) => {
          this.reloadingTable = true;
          HelperModule.flashAlertMsg(response.data.message, 'success');
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.error, 'danger');
        });
      }
    },
  },
};

</script>
