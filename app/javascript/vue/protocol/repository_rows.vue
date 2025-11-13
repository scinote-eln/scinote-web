<template>
  <div class="h-full flex flex-col">
    <div class="py-4 px-6 flex items-center gap-3 bg-sn-super-light-blue
                border-transparent border-[1px] border-solid border-b-sn-alert-science-blue-disabled">
      <i class="sn-icon sn-icon-alert-success text-sn-science-blue"></i>
      <span>{{ this.i18n.t('protocols.repository_rows.index.disclaimer') }}</span>
    </div>
    <div class="h-full flex-grow">
      <DataTable :columnDefs="columnDefs"
                tableId="ProtocolRepositoryRowsTable"
                :dataUrl="dataUrl"
                :reloadingTable="reloadingTable"
                :toolbarActions="toolbarActions"
                :actionsUrl="actionsUrl"
                :hideColumnsManagment="true"
                @assignRow="showAssignModal = true"
                @tableReloaded="reloadingTable = false"
                @delete="deleteRows"
          />
    </div>
    <AssignRowModal
    v-if="showAssignModal"
    @close="showAssignModal = false;"
    @assign="assignRow" />
    <ConfirmationModal
      :title="i18n.t('protocols.repository_rows.delete_modal.title')"
      :description="deleteDescription"
      confirmClass="btn btn-danger"
      :confirmText="i18n.t('protocols.repository_rows.delete_modal.confirm')"
      ref="deleteModal"
    ></ConfirmationModal>
  </div>
</template>
<script>


import axios from '../../packs/custom_axios.js';
import AssignRowModal from './modals/assign_row_modal.vue';
import DataTable from '../shared/datatable/table.vue';
import ConfirmationModal from '../shared/confirmation_modal.vue';
import RowNameRenderer from './repository_row_renderers/row_name.vue';
import RepositoryNameRenderer from './repository_row_renderers/repository_name.vue';


export default {
  name: 'TagsTable',
  components: {
    DataTable,
    AssignRowModal,
    ConfirmationModal,
    RowNameRenderer,
    RepositoryNameRenderer
  },
  props: {
    dataUrl: {
      type: String,
      required: true
    },
    actionsUrl: {
      type: String,
      required: true
    },
    createUrl: {
      type: String
    }
  },
  data() {
    return {
      reloadingTable: false,
      showAssignModal: false,
      deleteDescription: '',
      columnDefs: [
        {
          field: 'name',
          headerName: this.i18n.t('protocols.repository_rows.table.name'),
          sortable: true,
          suppressMovable: true,
          cellRenderer: 'RowNameRenderer'
        }, {
          field: 'row_code',
          headerName: this.i18n.t('protocols.repository_rows.table.id'),
          sortable: true,
          suppressMovable: true
        }, {
          field: 'repository_name',
          headerName: this.i18n.t('protocols.repository_rows.table.repository'),
          sortable: true,
          suppressMovable: true,
          cellRenderer: 'RepositoryNameRenderer'
        }
      ]
    };
  },
  computed: {
    toolbarActions() {
      const left = [];
      if (this.createUrl) {
        left.push({
          name: 'assignRow',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('protocols.repository_rows.index.assign_item'),
          type: 'emit',
          path: '',
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
    assignRow(rowId) {
      this.showAssignModal = false;
      axios.post(this.createUrl, {
        protocol_repository_row: {
          repository_row_id: rowId
        }
      }).then(() => {
        this.reloadingTable = true;
      }).catch((e) => {
        HelperModule.flashAlertMsg(e.response.data.errors, 'danger');
      });
    },
    async deleteRows(event, rows) {
      this.deleteDescription = this.i18n.t('protocols.repository_rows.delete_modal.description_html', { count: rows.length });

      const ok = await this.$refs.deleteModal.show();
      if (ok) {
        axios.delete(event.path).then(() => {
          this.reloadingTable = true;
        });
      }
    }
  }
};

</script>
