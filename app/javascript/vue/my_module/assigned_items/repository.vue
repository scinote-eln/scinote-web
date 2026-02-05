<template>
  <div ref="container"
       :class="{'p-4 bg-white rounded transition-all overflow-hidden mb-4': !onlyRepository}"
       :style="{height: (sectionOpened ? openSize : '60px')}">
    <div v-if="!onlyRepository" class="flex items-center h-6 gap-4 assigned-repository-title mb-1">
      <div
        @click="toggleContainer"
        class="flex items-center gap-4 grow overflow-hidden cursor-pointer"
        :data-e2e="`e2e-BT-task-assignedItems-inventory${ repository.id }-toggle`"
      >
        <i ref="openHandler" class="sn-icon sn-icon-down cursor-pointer"></i>
        <h3 class="my-0 flex items-center gap-4 overflow-hidden">
          <span :title="repository.attributes.name" class="assigned-repository-title truncate">{{ repository.attributes.name }}</span>
          <span class="text-sn-grey-500 font-normal text-base shrink-0">
            [{{ repository.attributes.assigned_rows_count }}]
          </span>
          <span class="bg-sn-light-grey  font-normal  px-1.5 py-1 rounded-full shrink-0 text-xs">
            <template v-if="repository.attributes.is_snapshot">
              {{  i18n.t('my_modules.repository.snapshots.simple_view.snapshot_tag') }}
            </template>
            <template v-else>
              {{  i18n.t('my_modules.repository.snapshots.simple_view.live_tag') }}
            </template>
          </span>

        </h3>
      </div>
    </div>
    <div style="height: 540px">
      <DataTable
        v-if="repositoryColumnsDef.length > 0"
        :columnDefs="repositoryColumnsDef"
        :tableId="`my_module_repository_rows_my_module_${myModuleId}_repository_${repository.id}`"
        :dataUrl="dataSource"
        :reloadingTable="reloadingTable"
        :toolbarActions="toolbarActions"
        :actionsUrl="toolbarActionsUrl"
        :filters="[]"
        :tableOnly="true"
        @openConsumeModal="consume"
        @export="exportRows"
        @export_consumption="exportConsumption"
        @print="printRows"
        @assign="openAssignItemModal = true"
        @unassign="unassignRows"
        @unassign_downstream="unassignDownstreamRows"
        @create="openCreateItemModal = true"
        @tableReloaded="reloadingTable = false"
      ></DataTable>
    </div>
    <Teleport to="body">
      <ConsumeModal v-if="openConsumeModal" @updateConsume="updateConsume" @close="openConsumeModal = false" :row="selectedRow" />
      <ConfirmationModal
        :title="i18n.t('my_modules.repository.stock_warning_modal.title')"
        :description="warningModalDescription"
        confirmClass="btn btn-primary"
        :confirmText="i18n.t('my_modules.repository.stock_warning_modal.consume_anyway')"
        ref="warningModal"
      ></ConfirmationModal>
      <ConfirmationModal
        :title="i18n.t('my_modules.repository.unassign_modal.title')"
        :description="unassignConfirmationModalDescription"
        confirmClass="btn btn-primary"
        :confirmText="unassignConfirmationModalActionText"
        ref="unassignConfirmationModal"
      ></ConfirmationModal>
      <CreateItemModal
        v-if="openCreateItemModal"
        :myModuleId="myModuleId"
        :selectedRepositoryValue="repository.id"
        @tableReloaded="newCreatedRow"
        @close="openCreateItemModal = false"></CreateItemModal>
      <AssignItemModal
          v-if="openAssignItemModal"
          :myModuleId="myModuleId"
          :selectedRepositoryValue="repository.id"
          @assignRows="assignRows"
          @close="openAssignItemModal = false"/>
    </Teleport>
  </div>
</template>
<script>
import DataTable from '../../shared/datatable/table.vue';
import axios from '../../../packs/custom_axios.js';
import ConsumeModal from './modals/consume.vue';
import ConfirmationModal from '../../shared/confirmation_modal.vue';
import ColumnsMixin from '../../repository/columns_mixin.js';
import CreateItemModal from '../assigned_items/modals/new_item.vue';
import AssignItemModal from './modals/assign_item.vue';

import {
  index_ag_my_module_repository_path,
  actions_toolbar_my_module_repositories_path,
  my_module_repository_path
} from '../../../routes.js';

export default {
  name: 'AssignedRepository',
  props: {
    repository: Object,
    myModuleId: String,
    reloadKey: Number,
    onlyRepository: {
      type: Boolean,
      default: false
    }
  },
  components: {
    DataTable,
    ConsumeModal,
    ConfirmationModal,
    CreateItemModal,
    AssignItemModal
  },
  mixins: [ColumnsMixin],
  data: () => ({
    openAssignItemModal: false,
    sectionOpened: true,
    warningModalDescription: '',
    unassignConfirmationModalDescription: '',
    unassignConfirmationModalActionText: '',
    submitting: false,
    reloadingTable: false,
    openConsumeModal: false,
    openCreateItemModal: false
  }),
  watch: {
    reloadKey() {
      this.reloadingTable = true;
    }
  },
  computed: {
    openSize() {
      return this.onlyRepository ? '540px' : '600px';
    },
    toolbarActions() {
      const left = [];
      const right = [];

      if (!this.repository.attributes.permissions.can_read) {
        return {};
      }

      if (this.repository.attributes.permissions.can_assign) {
        left.push({
          name: 'assign',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('my_modules.repository.assign_items'),
          type: 'emit',
          buttonStyle: 'btn btn-primary'
        });
        left.push({
          name: 'create',
          icon: 'sn-icon sn-icon-create-item',
          label: this.i18n.t('my_modules.repository.create_item'),
          type: 'emit',
          buttonStyle: 'btn btn-secondary'
        });
      }

      right.push({
        name: 'export',
        icon: 'sn-icon sn-icon-export',
        type: 'emit',
        buttonStyle: 'btn btn-light icon-btn btn-black',
      })
      return {
        left: left,
        right: right
      };
    },
    dataSource() {
      return index_ag_my_module_repository_path(this.myModuleId, this.repository.id);
    },
    toolbarActionsUrl() {
      return actions_toolbar_my_module_repositories_path(this.myModuleId);
    }
  },
  methods: {
    assignRows(rowIds, repositoryId, assignToDownstream = false) {
      this.openAssignItemModal = false;
      this.$emit('assignRows', rowIds, repositoryId, assignToDownstream);
    },
    async unassignRows(_e, rows, downstream = false) {
      const rowIds = rows.map(row => row.id);

      if (downstream) {
        this.unassignConfirmationModalDescription = this.i18n.t('my_modules.repository.unassign_modal.message_downstream', { number: rowIds.length });
        this.unassignConfirmationModalActionText = this.i18n.t('my_modules.repository.unassign_modal.action_downstream');
      } else {
        this.unassignConfirmationModalDescription = this.i18n.t('my_modules.repository.unassign_modal.message', { number: rowIds.length });
        this.unassignConfirmationModalActionText = this.i18n.t('my_modules.repository.unassign_modal.action');
      }
      const ok = await this.$refs.unassignConfirmationModal.show();
      if (ok) {
        axios.patch(my_module_repository_path(this.myModuleId, this.repository.id), {
          rows_to_unassign: rowIds,
          downstream: downstream
        }).then((response) => {
          HelperModule.flashAlertMsg(response.data.flash, 'success');
          this.reloadingTable = true;
        });
      }
    },
    unassignDownstreamRows(e, rows) {
      this.unassignRows(e, rows, true);
    },
    recalculateContainerSize() {
      const { container, openHandler } = this.$refs;

      if (this.sectionOpened) {
        container.style.height = '600px';
        openHandler.classList.remove('sn-icon-right');
        openHandler.classList.add('sn-icon-down');
      } else {
        container.style.height = '60px';
        openHandler.classList.remove('sn-icon-down');
        openHandler.classList.add('sn-icon-right');
      }
    },
    toggleContainer() {
      this.sectionOpened = !this.sectionOpened;
      this.recalculateContainerSize();
    },
    printRows(_e, rows) {
      if (typeof PrintModalComponent !== 'undefined') {
        PrintModalComponent.openModal();
        PrintModalComponent.repository_id = this.repository.id;
        PrintModalComponent.row_ids = rows.map(row => row.id);
      }
    },
    exportRows() {
      let headerIDs = [];
      this.repositoryColumnsDef.forEach((column) => {
        if (column.cellRendererParams?.legacyId) {
          headerIDs.push(column.cellRendererParams.legacyId);
        }
      });

      axios.post(this.repository.attributes.urls.export, {
        header_ids: headerIDs
      })
        .then((response) => {
          HelperModule.flashAlertMsg(response.data.message, 'success');
        })
        .catch((error) => {
          HelperModule.flashAlertMsg(error.response.data.message, 'danger');
        });
    },
    exportConsumption(_e, rows) {
      window.initExportStockConsumptionModal();

      if (window.exportStockConsumptionModalComponent) {
        window.exportStockConsumptionModalComponent.fetchRepositoryData(
          rows.map(row => row.id),
          { repository_id: this.repository.id }
        );
      }
    },

    newCreatedRow(repositoryRowSidebarUrl){
      this.reloadingTable = true
      window.repositoryItemSidebarComponent.toggleShowHideSidebar(repositoryRowSidebarUrl, this.myModuleId, null);
    },
    consume(row) {
      this.selectedRow = row;
      this.openConsumeModal = true;
    },
    async updateConsume({ newConsume, finalStock }) {
      this.openConsumeModal = false;
      const {
        consume, comment, url, unit
      } = newConsume;
      let readyToUpdate = false;
      if (finalStock < 0) {
        this.warningModalDescription = this.i18n.t('my_modules.repository.stock_warning_modal.description_html', { value: `${consume} ${unit}` });
        const ok = await this.$refs.warningModal.show();
        if (ok) {
          readyToUpdate = true;
        }
      } else {
        readyToUpdate = true;
      }

      if (readyToUpdate) {
        if (this.submitting) return;

        this.submitting = true;

        axios.post(url, {
          stock_consumption: consume,
          comment
        }).then(() => {
          this.reloadingTable = true;
          this.submitting = false;
        });
      }
    }
  }
};
</script>
