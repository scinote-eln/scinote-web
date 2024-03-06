<template>
  <div class="h-full">
    <DataTable :columnDefs="columnDefs"
               :tableId="'ProtocolTemplates'"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :currentViewMode="currentViewMode"
               :toolbarActions="toolbarActions"
               :activePageUrl="activePageUrl"
               :archivedPageUrl="archivedPageUrl"
               :actionsUrl="actionsUrl"
               :filters="filters"
               @create="create"
               @archive="archive"
               @restore="restore"
               @export="exportProtocol"
               @duplicate="duplicate"
               @versions="versions"
               @tableReloaded="reloadingTable = false"
               @import_file="importFile"
               @import_protocols_io="importProtocolsIo"
               @import_docx="importDocx"
               @access="access"
               @linked_my_modules="linkedMyModules"
    />
  </div>
  <NewProtocolModal v-if="newProtocol" :createUrl="createUrl"
                   :userRolesUrl="userRolesUrl"
                   @close="newProtocol = false" @create="updateTable" />
  <AccessModal v-if="accessModalParams" :params="accessModalParams"
               @close="accessModalParams = null" @refresh="this.reloadingTable = true" />
  <LinkedMyModulesModal v-if="linkedMyModulesModalObject" :protocol="linkedMyModulesModalObject"
                        @close="linkedMyModulesModalObject = null"/>
  <VersionsModal v-if="VersionsModalObject" :protocol="VersionsModalObject"
                 @close="VersionsModalObject = null" @refresh="this.reloadingTable = true"/>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';

import DataTable from '../shared/datatable/table.vue';
import UsersRenderer from '../projects/renderers/users.vue';
import NewProtocolModal from './modals/new.vue';
import AccessModal from '../shared/access_modal/modal.vue';
import KeywordsRenderer from './renderers/keywords.vue';
import LinkedMyModulesRenderer from './renderers/linked_my_modules.vue';
import LinkedMyModulesModal from './modals/linked_my_modules.vue';
import VersionsRenderer from './renderers/versions.vue';
import VersionsModal from './modals/versions.vue';

export default {
  name: 'LabelTemplatesTable',
  components: {
    DataTable,
    UsersRenderer,
    NewProtocolModal,
    AccessModal,
    KeywordsRenderer,
    LinkedMyModulesRenderer,
    LinkedMyModulesModal,
    VersionsRenderer,
    VersionsModal
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
    docxParserEnabled: {
      type: Boolean,
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
    userRolesUrl: {
      type: String,
      required: true
    },
    usersFilterUrl: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      reloadingTable: false,
      newProtocol: false,
      accessModalParams: null,
      linkedMyModulesModalObject: null,
      VersionsModalObject: null
    };
  },
  computed: {
    columnDefs() {
      const columns = [{
        field: 'name',
        headerName: this.i18n.t('protocols.index.thead.name'),
        sortable: true,
        notSelectable: true,
        cellRenderer: this.nameRenderer
      },
      {
        field: 'code',
        headerName: this.i18n.t('protocols.index.thead.id'),
        sortable: true
      },
      {
        field: 'has_draft',
        headerName: this.i18n.t('protocols.index.thead.versions'),
        sortable: true,
        cellRenderer: 'VersionsRenderer',
        notSelectable: true
      },
      {
        field: 'keywords',
        headerName: this.i18n.t('protocols.index.thead.keywords'),
        sortable: true,
        cellRenderer: 'KeywordsRenderer',
        notSelectable: true
      },
      {
        field: 'linked_tasks',
        headerName: this.i18n.t('protocols.index.thead.nr_of_linked_children'),
        sortable: true,
        cellRenderer: 'LinkedMyModulesRenderer'
      },
      {
        field: 'assigned_users',
        headerName: this.i18n.t('protocols.index.thead.access'),
        sortable: true,
        cellRenderer: 'UsersRenderer',
        minWidth: 210,
        notSelectable: true
      },
      {
        field: 'published_by',
        headerName: this.i18n.t('protocols.index.thead.published_by'),
        sortable: true
      },
      {
        field: 'published_on',
        headerName: this.i18n.t('protocols.index.thead.published_on'),
        sortable: true
      },
      {
        field: 'updated_at',
        headerName: this.i18n.t('protocols.index.thead.updated_at'),
        sortable: true
      }];

      if (this.currentViewMode === 'archived') {
        columns.push({
          field: 'archived_by',
          headerName: this.i18n.t('protocols.index.thead.archived_by'),
          sortable: true
        });
        columns.push({
          field: 'archived_on',
          headerName: this.i18n.t('protocols.index.thead.archived_on'),
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
          label: this.i18n.t('protocols.index.create_new'),
          type: 'emit',
          path: this.createUrl,
          buttonStyle: 'btn btn-primary'
        });
        const importMenu = {
          name: 'import',
          icon: 'sn-icon sn-icon-import',
          label: this.i18n.t('protocols.index.import'),
          type: 'menu',
          path: this.createUrl,
          buttonStyle: 'btn btn-light',
          menuItems: [
            {
              emit: 'import_file',
              text: this.i18n.t('protocols.index.import_eln')
            }
          ]
        };

        if (this.docxParserEnabled) {
          importMenu.menuItems.push({
            emit: 'import_docx',
            text: this.i18n.t('protocols.index.import_docx')
          });
        }

        importMenu.menuItems.push({
          emit: 'import_protocols_io',
          text: this.i18n.t('protocols.index.import_protocols_io')
        });

        left.push(importMenu);
      }
      return {
        left,
        right: []
      };
    },
    filters() {
      return [
        {
          key: 'name_and_keywords',
          type: 'Text',
          label: this.i18n.t('protocols.table.filters.label_name_and_keywords')
        },
        {
          key: 'published_on',
          type: 'DateRange',
          label: this.i18n.t('protocols.table.filters.published_on')
        },
        {
          key: 'modified_on',
          type: 'DateRange',
          label: this.i18n.t('protocols.table.filters.modified_on')
        },
        {
          key: 'published_by',
          type: 'Select',
          optionsUrl: this.usersFilterUrl,
          optionRenderer: this.usersFilterRenderer,
          labelRenderer: this.usersFilterRenderer,
          label: this.i18n.t('protocols.table.filters.published_by.label'),
          placeholder: this.i18n.t('protocols.table.filters.published_by.placeholder')
        },
        {
          key: 'members',
          type: 'Select',
          optionsUrl: this.usersFilterUrl,
          optionRenderer: this.usersFilterRenderer,
          labelRenderer: this.usersFilterRenderer,
          label: this.i18n.t('protocols.table.filters.members.label'),
          placeholder: this.i18n.t('protocols.table.filters.members.placeholder')
        },
        {
          key: 'has_draft',
          type: 'Checkbox',
          label: this.i18n.t('protocols.table.filters.has_draft')
        }
      ];
    }
  },
  methods: {
    updateTable() {
      this.newProtocol = false;
      this.reloadingTable = true;
    },
    create() {
      this.newProtocol = true;
    },
    duplicate(event, rows) {
      axios.post(event.path, { protocol_ids: rows.map((row) => row.id) }).then((response) => {
        this.updateTable();
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    versions(_event, rows) {
      [this.VersionsModalObject] = rows;
    },
    archive(event, rows) {
      axios.post(event.path, { protocol_ids: rows.map((row) => row.id) }).then((response) => {
        this.updateTable();
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    restore(event, rows) {
      axios.post(event.path, { protocol_ids: rows.map((row) => row.id) }).then((response) => {
        this.updateTable();
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    },
    exportProtocol(event) {
      const link = document.createElement('a');
      link.href = event.path;
      link.click();
    },
    importFile() {
      const fileInput = document.querySelector('#importFileInput');
      fileInput.click();
    },
    importProtocolsIo() {
      const protocolIoButton = document.querySelector('#importProtocolsIo');
      protocolIoButton.click();
    },
    importDocx() {
      const docxButton = document.querySelector('#importDocx');
      docxButton.click();
    },
    access(_event, rows) {
      this.accessModalParams = {
        object: rows[0],
        roles_path: this.userRolesUrl
      };
    },
    linkedMyModules(_event, rows) {
      [this.linkedMyModulesModalObject] = rows;
    },
    // renderers
    nameRenderer(params) {
      const { urls, name } = params.data;
      if (urls.show) {
        return `<a href="${urls.show}" title="${name}">${name}</a>`;
      }
      return `<span class="text-sn-grey" title="${name}">${name}</span>`;
    },
    usersFilterRenderer(option) {
      return `<div class="flex items-center gap-2">
                <img src="${option[2].avatar_url}" class="rounded-full w-6 h-6" />
                <span class="truncate" title="${option[1]}">${option[1]}</span>
              </div>`;
    }
  }
};

</script>
