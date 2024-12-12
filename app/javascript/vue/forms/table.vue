<template>
  <div class="h-full">
    <DataTable :columnDefs="columnDefs"
               :tableId="'FormsTable'"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :toolbarActions="toolbarActions"
               :actionsUrl="actionsUrl"
               @tableReloaded="reloadingTable = false"
               @create="createForm"
               @access="access"
      />
  </div>
  <AccessModal v-if="accessModalParams" :params="accessModalParams"
               @close="accessModalParams = null" @refresh="this.reloadingTable = true" />
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';

import DataTable from '../shared/datatable/table.vue';
import DeleteModal from '../shared/confirmation_modal.vue';
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
    AccessModal
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
    }
  },
  data() {
    return {
      reloadingTable: false,
      accessModalParams: null,
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
      axios.post(action.path).then((response) => {
        window.location.href = response.data.data.attributes.urls.show;
      });
    },
    access(_event, rows) {
      this.accessModalParams = {
        object: rows[0],
        roles_path: this.userRolesUrl
      };
    }
  }
};

</script>
