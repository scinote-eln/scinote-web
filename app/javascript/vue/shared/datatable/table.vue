<template>
  <div class="flex flex-col h-full">
    <div class="relative flex flex-col flex-grow">
      <Toolbar :toolbarActions="toolbarActions" @toolbar:action="emitAction" :searchValue="searchValue" @search:change="setSearchValue" />
      <ag-grid-vue
        class="ag-theme-alpine w-full flex-grow h-full"
        :class="{'opacity-0': initializing}"
        :columnDefs="columnDefs"
        :rowData="rowData"
        :defaultColDef="defaultColDef"
        :rowSelection="'multiple'"
        :gridOptions="gridOptions"
        @grid-ready="onGridReady"
        @first-data-rendered="onFirstDataRendered"
        @sortChanged="setOrder"
        @columnResized="saveColumnsState"
        @columnMoved="saveColumnsState"
        @rowSelected="setSelectedRows"
        :CheckboxSelectionCallback="withCheckboxes"
      >
      </ag-grid-vue>
      <ActionToolbar v-if="selectedRows.length > 0 && actionsUrl" :actionsUrl="actionsUrl" :params="actionsParams" @toolbar:action="emitAction" />
    </div>
    <div class="flex items-center py-4">
      <div class="mr-auto">
        <Pagination
          :totalPage="totalPage"
          :currentPage="page"
          @setPage="setPage"
        ></Pagination>
      </div>
      <div class="flex items-center gap-4">
        {{ i18n.t('datatable.show') }}
        <div class="w-36">
          <Select
            :value="perPage"
            :options="perPageOptions"
            @change="setPerPage"
          ></Select>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { AgGridVue } from "ag-grid-vue3";
import axios from '../../../packs/custom_axios.js';
import Select from '../select.vue';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import Pagination from './pagination.vue';
import CustomHeader from './tableHeader';
import ActionToolbar from './action_toolbar.vue';
import Toolbar from './toolbar.vue';

export default {
  name: "App",
  props: {
    withCheckboxes: {
      type: Boolean,
      default: true,
    },
    tableId: {
      type: String,
      required: true,
    },
    columnDefs: {
      type: Array,
      default: () => [],
    },
    dataUrl: {
      type: String,
      required: true,
    },
    actionsUrl: {
      type: String,
    },
    toolbarActions: {
      type: Object,
      required: true
    },
    reloadingTable: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      rowData: [],
      gridApi: null,
      columnApi: null,
      defaultColDef: {
        resizable: true
      },
      perPage: 20,
      page: 1,
      order: null,
      totalPage: 0,
      selectedRows: [],
      searchValue: '',
      initializing: true
    };
  },
  components: {
    AgGridVue,
    Select,
    PerfectScrollbar,
    Pagination,
    agColumnHeader: CustomHeader,
    ActionToolbar,
    Toolbar
  },
  computed: {
    perPageOptions() {
      return [10, 20, 50, 100].map(value => [ value, `${value} ${this.i18n.t('datatable.rows')}` ]);
    },
    tableState() {
      if (!localStorage.getItem(`datatable:${this.tableId}_columns_state`)) return null;

      return JSON.parse(localStorage.getItem(`datatable:${this.tableId}_columns_state`));
    },
    actionsParams() {
      return {
        item_ids: this.selectedRows.map(row => row.id).join(',')
      }
    },
    gridOptions() {
      return {
        suppressCellFocus: true
      }
    }
  },
  beforeMount() {
    if (this.withCheckboxes) {
      this.columnDefs.unshift({
        field: "checkbox",
        headerCheckboxSelection: true,
        headerCheckboxSelectionFilteredOnly: true,
        checkboxSelection: true,
        width: 48,
        minWidth: 48,
        resizable: false
      });
    }
  },
  watch: {
    reloadingTable() {
      if (this.reloadingTable) {
        this.loadData();
      }
    }
  },
  mounted() {
    this.loadData();
    window.addEventListener('resize', this.resize);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.resize);
  },
  methods: {
    formatData(data) {
      return data.map( (item) => Object.assign({}, item.attributes, { id: item.id }) );
    },
    resize() {
      if (this.tableState) return;

      this.gridApi.sizeColumnsToFit();
    },
    loadData() {
      axios
        .get(this.dataUrl, {
          params: {
            per_page: this.perPage,
            page: this.page,
            order: this.order,
            search: this.searchValue
          }
        })
        .then((response) => {
          this.selectedRows = [];
          this.gridApi.setRowData(this.formatData(response.data.data));
          this.totalPage = response.data.meta.total_pages;
          this.$emit('tableReloaded');
        })
    },
    onGridReady(params) {
      this.gridApi = params.api;
      this.columnApi = params.columnApi;

      if (this.tableState) {
        this.columnApi.applyColumnState({
          state: this.tableState,
          applyOrder: true
        });
      }
      setTimeout(() => {
        this.initializing = false;
      }, 200);
    },
    onFirstDataRendered(params) {
      this.resize();
    },
    setPerPage(value) {
      this.perPage = value;
      this.loadData();
    },
    setPage(page) {
      this.page = page;
      this.loadData();
    },
    setOrder() {
      const orderState = this.columnApi.getColumnState().filter(column => column.sort).map(column => {
        return {
          column: column.colId,
          dir: column.sort
        }
      });
      this.order = orderState[0];
      this.saveColumnsState();
      this.loadData();
    },
    saveColumnsState() {
      if (!this.columnApi) return;

      const columnsState = this.columnApi.getColumnState();
      localStorage.setItem(`datatable:${this.tableId}_columns_state`, JSON.stringify(columnsState));
    },
    setSelectedRows() {
      this.selectedRows = this.gridApi.getSelectedRows();
    },
    emitAction(action) {
      this.$emit(action.name, action, this.selectedRows);
    },
    setSearchValue(value) {
      this.searchValue = value;
      this.loadData();
    }
  }
};
</script>
