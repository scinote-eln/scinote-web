<template>
  <div ref="container" class="border rounded transition-all overflow-hidden" :style="{height: (sectionOpened ? '448px' : '48px')}">
    <div class="flex items-center h-12 px-4 gap-4 assigned-repository-title">
      <div
        @click="toggleContainer"
        class="flex items-center grow overflow-hidden cursor-pointer"
        :data-e2e="`e2e-BT-task-assignedItems-inventory${ repository.id }-toggle`"
      >
        <i ref="openHandler" class="sn-icon sn-icon-right cursor-pointer"></i>
        <h3 class="my-0 flex items-center gap-1 overflow-hidden">
          <span :title="repository.attributes.name" class="assigned-repository-title truncate">{{ repository.attributes.name }}</span>
          <span class="text-sn-grey-500 font-normal text-base shrink-0">
            [{{ repository.attributes.assigned_rows_count }}]
          </span>
          <span v-if="repository.attributes.is_snapshot"
                class="bg-sn-light-grey text-sn-grey-500 font-normal  px-1.5 py-1 rounded shrink-0 text-sm">
            {{  i18n.t('my_modules.repository.snapshots.simple_view.snapshot_tag') }}
          </span>
        </h3>
      </div>
      <button
        v-if="repository.attributes.urls.full_view"
        class="btn btn-light icon-btn ml-auto full-screen"
        :data-table-url="fullViewUrl"
        :data-e2e="`e2e-BT-task-assignedItems-inventory${ repository.id }-expand`"
      >
        <i class="sn-icon sn-icon-expand"></i>
      </button>
    </div>
    <div style="height: 400px">
      <DataTable
        v-if="repositoryColumnsDef.length > 0"
        :columnDefs="repositoryColumnsDef"
        tableId="MyModuleRepositoryRows"
        :dataUrl="dataSource"
        :reloadingTable="reloadingTable"
        :toolbarActions="toolbarActions"
        :actionsUrl="''"
        :filters="[]"
        :tableOnly="true"
        @openConsumeModal="consume"
        @tableReloaded="reloadingTable = false"
      ></DataTable>
    </div>
    <ConsumeModal v-if="openConsumeModal" @updateConsume="updateConsume" @close="openConsumeModal = false" :row="selectedRow" />
    <ConfirmationModal
      :title="i18n.t('my_modules.repository.stock_warning_modal.title')"
      :description="warningModalDescription"
      confirmClass="btn btn-primary"
      :confirmText="i18n.t('my_modules.repository.stock_warning_modal.consume_anyway')"
      ref="warningModal"
    ></ConfirmationModal>
  </div>
</template>
<script>
import DataTable from '../../shared/datatable/table.vue';
import axios from '../../../packs/custom_axios.js';
import ConsumeModal from './modals/consume.vue';
import ConfirmationModal from '../../shared/confirmation_modal.vue';
import ColumnsMixin from '../../repository/columns_mixin.js';

import {
  index_ag_my_module_repository_path
} from '../../../routes.js';

export default {
  name: 'AssignedRepository',
  props: {
    repository: Object,
    myModuleId: String
  },
  components: {
    DataTable,
    ConsumeModal,
    ConfirmationModal
  },
  mixins: [ColumnsMixin],
  data: () => ({
    sectionOpened: false,
    warningModalDescription: '',
    submitting: false,
    reloadingTable: false,
    openConsumeModal: false,
  }),
  computed: {
    toolbarActions() {
      return {
        left: [],
        right: []
      };
    },
    dataSource() {
      return index_ag_my_module_repository_path(this.myModuleId, this.repository.id);
    },
    fullViewUrl() {
      let url = this.repository.attributes.urls.full_view;
      if (this.repository.attributes.has_stock && this.repository.attributes.has_stock_consumption) {
        url += '?include_stock_consumption=true';
      }
      return url;
    }
  },
  methods: {
    recalculateContainerSize() {
      const { container, openHandler } = this.$refs;

      if (this.sectionOpened) {
        container.style.height = '448px';
        openHandler.classList.remove('sn-icon-right');
        openHandler.classList.add('sn-icon-down');
        this.$emit('recalculateContainerSize', 400);
      } else {
        container.style.height = '48px';
        openHandler.classList.remove('sn-icon-down');
        openHandler.classList.add('sn-icon-right');
        this.$emit('recalculateContainerSize', 0);
      }
    },
    toggleContainer() {
      this.sectionOpened = !this.sectionOpened;
      this.recalculateContainerSize();
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
