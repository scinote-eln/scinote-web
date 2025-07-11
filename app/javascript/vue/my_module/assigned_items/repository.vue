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
        class="btn btn-light icon-btn ml-auto full-screen"
        :data-table-url="fullViewUrl"
        :data-e2e="`e2e-BT-task-assignedItems-inventory${ repository.id }-expand`"
      >
        <i class="sn-icon sn-icon-expand"></i>
      </button>
    </div>
    <div style="height: 400px">
      <ag-grid-vue
          class="ag-theme-alpine w-full flex-grow h-[340px] z-10"
          :columnDefs="columnDefs"
          :rowData="preparedAssignedItems"
          :rowSelection="false"
          :suppressRowTransform="true"
          :suppressRowClickSelection="true"
          :enableCellTextSelection="true"
          @grid-ready="onGridReady"
          @sortChanged="setOrder"
        >
      </ag-grid-vue>
      <div class="h-[60px] flex items-center border-transparent border-t border-t-sn-light-grey border-solid grey px-6">
        <div>
          {{ repository.attributes.footer_label }}
        </div>
        <div class="ml-auto">
          <Pagination
            :totalPage="Math.ceil(assignedItems.recordsTotal / perPage)"
            :currentPage="page"
            @setPage="setPage"
          ></Pagination>
        </div>
      </div>
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
import { AgGridVue } from 'ag-grid-vue3';
import axios from '../../../packs/custom_axios.js';
import CustomHeader from '../../shared/datatable/tableHeader';
import Pagination from '../../shared/datatable/pagination.vue';
import NameRenderer from './renderers/name.vue';
import StockRenderer from './renderers/stock.vue';
import ConsumeRenderer from './renderers/consume.vue';
import ConsumeModal from './modals/consume.vue';
import ConfirmationModal from '../../shared/confirmation_modal.vue';

export default {
  name: 'AssignedRepository',
  props: {
    repository: Object
  },
  components: {
    AgGridVue,
    agColumnHeader: CustomHeader,
    Pagination,
    NameRenderer,
    StockRenderer,
    ConsumeRenderer,
    ConsumeModal,
    ConfirmationModal
  },
  data: () => ({
    assignedItems: {
      data: [],
      recordsTotal: 0
    },
    order: { column: 0, dir: 'asc' },
    sectionOpened: false,
    page: 1,
    perPage: 20,
    gridApi: null,
    columnApi: null,
    gridReady: false,
    openConsumeModal: false,
    selectedRow: null,
    warningModalDescription: '',
    submitting: false
  }),
  computed: {
    preparedAssignedItems() {
      return this.assignedItems.data;
    },
    fullViewUrl() {
      let url = this.repository.attributes.urls.full_view;
      if (this.repository.attributes.has_stock && this.repository.attributes.has_stock_consumption) {
        url += '?include_stock_consumption=true';
      }
      return url;
    },
    columnDefs() {
      const columns = [{
        field: '0',
        flex: 1,
        headerName: this.i18n.t('repositories.table.row_name'),
        sortable: true,
        cellRenderer: 'NameRenderer',
        comparator: () => null,
        cellRendererParams: {
          dtComponent: this
        }
      }];

      if (this.repository.attributes.has_stock && this.repository.attributes.has_stock_consumption) {
        columns.push({
          field: 'stock',
          headerName: this.repository.attributes.stock_column_name,
          sortable: true,
          cellRenderer: 'StockRenderer',
          comparator: () => null
        });
        columns.push({
          field: 'consumedStock',
          headerName: this.i18n.t('repositories.table.row_consumption'),
          sortable: true,
          comparator: () => null,
          cellRendererParams: {
            dtComponent: this
          },
          cellRenderer: 'ConsumeRenderer'
        });
      }
      return columns;
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

        if (this.assignedItems.data.length === 0) this.getRows();
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
    setOrder() {
      const orderState = this.getOrder(this.columnApi.getColumnState());
      const [order] = orderState;
      if (order.column === 'stock') {
        order.column = 1;
      } else if (order.column === 'consumedStock') {
        order.column = 2;
      } else if (order.column === '0') {
        order.column = 0;
      }
      this.order = order;

      this.getRows();
    },
    getOrder(columnsState) {
      if (!columnsState) return null;

      return columnsState.filter((column) => column.sort)
        .map((column) => ({
          column: column.colId,
          dir: column.sort
        }));
    },
    onGridReady(params) {
      this.gridApi = params.api;
      this.columnApi = params.columnApi;
      this.gridReady = true;
    },
    getRows() {
      axios.post(this.repository.attributes.urls.assigned_rows, {
        assigned: 'assigned_simple',
        draw: this.page,
        length: this.perPage,
        order: [this.order],
        search: { value: '', regex: false },
        simple_view: true,
        start: (this.page - 1) * this.perPage,
        view_mode: true
      }).then((response) => {
        this.assignedItems = response.data;
      });
    },
    setPage(page) {
      this.page = page;
      this.getRows();
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
          this.getRows();
          this.submitting = false;
        });
      }
    }
  }
};
</script>
