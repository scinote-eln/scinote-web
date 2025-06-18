<template>
  <div class="h-full">
    <DataTable :columnDefs="columnDefs"
               tableId="UserGroup"
               :dataUrl="dataSource"
               :reloadingTable="reloadingTable"
               :toolbarActions="toolbarActions"
               :actionsUrl="actionsUrl"
               @tableReloaded="reloadingTable = false"
               @create="addMemberModal = true"
               @delete="removeMembers"
      />
  </div>
  <AddMemberModal v-if="addMemberModal" :createUrl="createUrl" :usersUrl="usersUrl"
                   @close="addMemberModal = false" @create="reloadingTable = true; addMemberModal = false" />
  <DeleteModal
    :title="i18n.t('user_groups.show.remove_modal.title', { group: groupName })"
    :description="removeModalDescription"
    confirmClass="btn btn-danger"
    :confirmText="i18n.t('user_groups.show.remove_modal.confirm')"
    ref="removeModal"
  ></DeleteModal>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';

import DataTable from '../shared/datatable/table.vue';
import AddMemberModal from './modal/add_member.vue';
import DeleteModal from '../shared/confirmation_modal.vue';


export default {
  name: 'UserGroupsTable',
  components: {
    DataTable,
    AddMemberModal,
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
    groupName: {
      type: String,
      required: true
    },
  },
  data() {
    return {
      addMemberModal: false,
      reloadingTable: false,
      removeModalDescription: '',
      columnDefs: [
        {
          field: 'name',
          headerName: this.i18n.t('user_groups.show.name'),
          sortable: true,
        }, {
          field: 'email',
          headerName: this.i18n.t('user_groups.show.email'),
          sortable: true,
        }, {
          field: 'created_at',
          headerName: this.i18n.t('user_groups.show.created_at'),
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
          label: this.i18n.t('user_groups.show.add_members'),
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
    async removeMembers(event, rows) {
      const description = this.i18n.t('user_groups.show.remove_modal.description_html', { number: rows.length });
      this.removeModalDescription = description;
      const ok = await this.$refs.removeModal.show();
      if (ok) {
        axios.delete(event.path).then(() => {
          this.reloadingTable = true;
          HelperModule.flashAlertMsg(this.i18n.t('user_groups.show.remove_modal.success'), 'success');
        }).catch(() => {
          HelperModule.flashAlertMsg(this.i18n.t('user_groups.show.remove_modal.error'), 'danger');
        });
      }
    },
  }
};

</script>
