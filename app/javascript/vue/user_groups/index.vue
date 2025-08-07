<template>
  <div class="h-full">
    <DataTable :columnDefs="columnDefs"
               :tableId="'UserGroups'"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :toolbarActions="toolbarActions"
               :actionsUrl="actionsUrl"
               @tableReloaded="reloadingTable = false"
               @assignUsers="assignUsers"
               @create="newGroup = true"
               @delete="deleteGroup"
      />
  </div>
  <CreateModal v-if="newGroup" :createUrl="createUrl" :usersUrl="usersUrl"
                   @close="newGroup = false" @create="reloadingTable = true; newGroup = false" />
  <DeleteModal
    :title="i18n.t('user_groups.index.delete_modal.title')"
    :description="deleteDescription"
    confirmClass="btn btn-danger"
    :confirmText="i18n.t('user_groups.index.delete_modal.confirm')"
    ref="deleteModal"
  ></DeleteModal>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';

import DataTable from '../shared/datatable/table.vue';
import NameRenderer from './renderers/name.vue';
import MembersRenderer from './renderers/members.vue';
import CreateModal from './modal/create_group.vue';
import DeleteModal from '../shared/confirmation_modal.vue';


export default {
  name: 'UserGroupsTable',
  components: {
    DataTable,
    NameRenderer,
    MembersRenderer,
    CreateModal,
    DeleteModal
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
    usersUrl: {
      type: String
    },
  },
  data() {
    return {
      reloadingTable: false,
      newGroup: false,
      deleteDescription: '',
      columnDefs: [
        {
          field: 'name',
          headerName: this.i18n.t('user_groups.index.group_name'),
          sortable: true,
          cellRenderer: 'NameRenderer'
        }, {
          field: 'members',
          headerName: this.i18n.t('user_groups.index.members'),
          sortable: true,
          cellRenderer: 'MembersRenderer',
          minWidth: 210,
          notSelectable: true
        }, {
          field: 'created_by',
          headerName: this.i18n.t('user_groups.index.created_by'),
          sortable: true
        }, {
          field: 'created_at',
          headerName: this.i18n.t('user_groups.index.created_on'),
          sortable: true
        }, {
          field: 'updated_at',
          headerName: this.i18n.t('user_groups.index.updated_on'),
          sortable: true,
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
          label: this.i18n.t('user_groups.index.new_group'),
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
    assignUsers(params, selectedUsers) {
      axios.post(params.data.urls.assign_users, { user_ids: selectedUsers })
        .then(() => {
          this.reloadingTable = true;
        })
    },
    async deleteGroup(event, rows) {
      const sanitizedName = rows[0].name.replace(/<\/?[^>]+(>|$)/g, "")
      const description = this.i18n.t('user_groups.index.delete_modal.description_html', { group: sanitizedName });
      this.deleteDescription = description;
      const ok = await this.$refs.deleteModal.show();
      if (ok) {
        axios.delete(event.path).then((response) => {
          this.reloadingTable = true;
          HelperModule.flashAlertMsg(response.data.message, 'success');
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.error, 'danger');
        });
      }
    },
  }
};

</script>
