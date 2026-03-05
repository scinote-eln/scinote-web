<template>
  <div class="flex flex-col h-full" :class="{'pb-4': windowScrollerSeen}">
    <div class="relative flex flex-col flex-grow z-10">
      <div class="h-4 w-full"></div>
      <div class="w-full h-full">
        <ag-grid-vue
          ref="agGrid"
          class="ag-theme-alpine w-full flex-grow h-full z-10"
          :columnDefs="columnDefs"
          :defaultColDef="{
            resizable: true
          }"
          :gridOptions="gridOptions"
          :rowData="rowData"
          :suppressRowTransform="true"
          :suppressRowClickSelection="true"
          :enableCellTextSelection="true"
          @first-data-rendered="resize"
          @sortChanged="setOrder"
          @grid-ready="onGridReady"
        ></ag-grid-vue>
      </div>
      <div class="flex items-center py-4" :class="{'opacity-0': initializing }" data-e2e="e2e-CO-tableInfo">
        <div class="flex items-center gap-4" data-e2e="e2e-TX-tableInfo-show">
          {{ i18n.t('datatable.show') }}
          <div class="w-36">
            <SelectDropdown
              :value="perPage"
              :options="perPageOptions"
              :data-e2e="'e2e-DD-tableInfo-rows'"
              @change="setPerPage"
            ></SelectDropdown>
          </div>
          <div v-show="!dataLoading" data-e2e="e2e-TX-tableInfo-entries">
            <span>
              {{ i18n.t('datatable.entries.filtered', { count: totalEntries, selected: 0 }) }}
            </span>
          </div>
        </div>
        <div class="ml-auto">
          <Pagination
            :totalPage="totalPage"
            :currentPage="page"
            @setPage="setPage"
          ></Pagination>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

/* global GLOBAL_CONSTANTS */
import { AgGridVue } from 'ag-grid-vue3';
import { PerfectScrollbar } from 'vue3-perfect-scrollbar';
import axios from '../../../packs/custom_axios.js';
import SelectDropdown from '../../shared/select_dropdown.vue';
import Pagination from '../../shared/datatable/pagination.vue';
import CustomHeader from '../../shared/datatable/tableHeader';

export default {
  name: 'App',
  props: {
    columnDefs: {
      type: Array,
      default: () => []
    },
    dataUrl: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      rowData: [],
      gridApi: null,
      defaultColDef: {
        resizable: true
      },
      perPage: 20,
      page: 1,
      order: null,
      totalPage: 0,
      totalEntries: null,
      initializing: true,
      dataLoading: true,
      lastPage: false,
      gridReady: false,
      windowScrollerSeen: false,
      gridColsClass: ''
    };
  },
  components: {
    AgGridVue,
    SelectDropdown,
    PerfectScrollbar,
    Pagination,
    agColumnHeader: CustomHeader
  },
  computed: {
    perPageOptions() {
      return [10, 20, 50, 100].map((value) => ([value, `${value} ${this.i18n.t('datatable.rows')}`]));
    },
    gridOptions() {
      return {
        suppressCellFocus: true,
        rowHeight: 40,
        headerHeight: 40
      };
    }
  },
  created() {
    this.initializing = false;
    this.loadData();
  },
  mounted() {
    window.addEventListener('resize', this.resize);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.resize);
  },
  methods: {
    formatData(data) {
      return data.map((item) => ({
        ...item.attributes,
        id: item.id,
        type: item.type
      }));
    },
    resize() {
      this.windowScrollerSeen = document.documentElement.scrollWidth > document.documentElement.clientWidth;

      this.gridApi?.autoSizeAllColumns();
    },
    reloadTable() {
      if (this.dataLoading) return;

      this.dataLoading = true;
      this.page = 1;
      this.loadData(true);
    },
    loadData(reload = false) {
      axios
        .get(this.dataUrl, {
          params: {
            per_page: this.perPage,
            page: this.page,
            order: this.order
          }
        })
        .then((response) => {
          if (reload) {
            if (this.gridApi) this.gridApi.setGridOption('rowData', []);
            this.rowData = [];
          }

          if (this.gridApi) this.gridApi.setGridOption('rowData', this.formatData(response.data.data));
          this.rowData = this.formatData(response.data.data);

          this.totalPage = response.data.meta.total_pages;
          this.totalEntries = response.data.meta.total_count;
          
          this.dataLoading = false;
          this.gridApi?.refreshCells({
            force: true
          });
        })
        .catch((e) => {
          this.dataLoading = false;
          console.error(e);
          window.HelperModule.flashAlertMsg(this.i18n.t('general.error'), 'danger');
        });
    },
    onGridReady(params) {
      this.gridApi = params.api;
      this.gridReady = true;

      this.gridApi.sizeColumnsToFit();
      this.initializing = false;
    },
    setPerPage(value) {
      this.perPage = value;
      this.page = 1;
      this.lastPage = false;
      this.reloadTable();
    },
    setPage(page) {
      this.page = page;
      this.loadData(false);
    },
    setOrder() {
      const orderState = this.getOrder(this.gridApi?.getColumnState());
      const [order] = orderState;
      this.order = order;
      this.reloadTable();
    },
    getOrder(columnsState) {
      if (!columnsState) return null;

      return columnsState.filter((column) => column.sort)
        .map((column) => ({
          column: column.colId,
          dir: column.sort
        }));
    }
  }
};
</script>
