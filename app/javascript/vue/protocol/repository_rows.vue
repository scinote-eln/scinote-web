<template>
  <div ref="container" class="border rounded transition-all" :style="{height: '448px'}">
    <div style="height: 400px">
      <ag-grid-vue
          class="ag-theme-alpine w-full flex-grow h-[340px] z-10"
          :columnDefs="columnDefs"
          :rowData="preparedRows"
          :rowSelection="false"
          :suppressRowTransform="true"
          :suppressRowClickSelection="true"
          :enableCellTextSelection="true"
          @grid-ready="onGridReady"
          @sortChanged="setOrder"
        >
      </ag-grid-vue>
      <div class="h-[60px] flex items-center border-transparent border-t border-t-sn-light-grey border-solid grey px-6">
        <div class="ml-auto">
          <Pagination
            :totalPage="Math.ceil(protocolRepositoryRows.recordsTotal / perPage)"
            :currentPage="page"
            @setPage="setPage"
          ></Pagination>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { AgGridVue } from 'ag-grid-vue3';
import axios from '../../packs/custom_axios.js';
import CustomHeader from '../shared/datatable/tableHeader';
import Pagination from '../shared/datatable/pagination.vue';

export default {
  name: 'ProtocolRepositoryRows',
  props: {
    dataUrl: {
      type: String,
      required: true
    }
  },
  components: {
    AgGridVue,
    agColumnHeader: CustomHeader,
    Pagination
  },
  data: () => ({
    protocolRepositoryRows: {
      data: [],
      recordsTotal: 0
    },
    order: { column: 0, dir: 'asc' },
    sectionOpened: false,
    page: 1,
    perPage: 20,
    gridApi: null,
    columnApi: null,
    gridReady: false
  }),
  created() {
    this.loadData();
  },
  computed: {
    preparedRows() {
      return this.protocolRepositoryRows.data;
    },
    columnDefs() {
      const columns = [
        {
          field: '0',
          flex: 1,
          headerName: this.i18n.t('protocols.repository_rows.table.id'),
          sortable: true,
          comparator: () => null,
          cellRendererParams: {
            dtComponent: this
          }
        },
        {
          field: '1',
          flex: 1,
          headerName: this.i18n.t('protocols.repository_rows.table.name'),
          sortable: true,
          comparator: () => null,
          cellRendererParams: {
            dtComponent: this
          }
        },
        {
          field: '2',
          flex: 1,
          headerName: this.i18n.t('protocols.repository_rows.table.repository'),
          sortable: true,
          comparator: () => null,
          cellRendererParams: {
            dtComponent: this
          }
        }
    ];

      return columns;
    }
  },
  methods: {
    setOrder() {
      const orderState = this.getOrder(this.columnApi.getColumnState());
      const [order] = orderState;
      order.column = 0;
      this.order = order;

      this.loadData();
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
    loadData() {
      axios.post(this.dataUrl, {
        length: this.perPage,
        order: [this.order],
        start: (this.page - 1) * this.perPage
      }).then((response) => {
        this.protocolRepositoryRows = response.data;
      });
    },
    setPage(page) {
      this.page = page;
      this.loadData();
    },
  }
};
</script>
