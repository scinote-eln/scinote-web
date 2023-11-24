<template>
  <div class="flex flex-col h-full">
    <div class="relative flex flex-col flex-grow z-10">
      <Toolbar
        :toolbarActions="toolbarActions"
        @toolbar:action="emitAction"
        :searchValue="searchValue"
        @search:change="setSearchValue"
        :activePageUrl="activePageUrl"
        :archivedPageUrl="archivedPageUrl"
        :currentViewMode="currentViewMode"
        :filters="filters"
        @applyFilters="applyFilters"
      />
      <ag-grid-vue
        class="ag-theme-alpine w-full flex-grow h-full z-10"
        :class="{'opacity-0': initializing}"
        :columnDefs="columnDefs"
        :rowData="rowData"
        :defaultColDef="defaultColDef"
        :rowSelection="'multiple'"
        :suppressRowTransform="true"
        :gridOptions="gridOptions"
        :suppressRowClickSelection="true"
        @grid-ready="onGridReady"
        @first-data-rendered="onFirstDataRendered"
        @sortChanged="setOrder"
        @columnResized="saveColumnsState"
        @columnMoved="saveColumnsState"
        @rowSelected="setSelectedRows"
        @cellClicked="clickCell"
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
import RowMenuRenderer from './row_menu_renderer.vue';

export default {
  name: "App",
  props: {
    withCheckboxes: {
      type: Boolean,
      default: true,
    },
    withRowMenu: {
      type: Boolean,
      default: false,
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
    },
    activePageUrl: {
      type: String,
    },
    archivedPageUrl: {
      type: String,
    },
    currentViewMode: {
      type: String,
      default: 'active'
    },
    filters: {
      type: Array,
      default: () => []
    },

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
      initializing: true,
      activeFilters: {}
    };
  },
  components: {
    AgGridVue,
    Select,
    PerfectScrollbar,
    Pagination,
    agColumnHeader: CustomHeader,
    ActionToolbar,
    Toolbar,
    RowMenuRenderer
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
        items: JSON.stringify(this.selectedRows.map(row => { return {id: row.id, type: row.type} }))
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
        resizable: false,
        pinned: 'left'
      });
    }

    if (this.withRowMenu) {
      this.columnDefs.push({
        field: "rowMenu",
        headerName: '',
        width: 72,
        minWidth: 72,
        resizable: false,
        sortable: false,
        cellRenderer: 'RowMenuRenderer',
        cellStyle: {overflow: 'visible'},
        pinned: 'right'

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
      return data.map( (item) => Object.assign({}, item.attributes, { id: item.id, type: item.type }) );
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
            search: this.searchValue,
            view_mode: this.currentViewMode,
            filters: this.activeFilters
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
    },
    clickCell(e) {
      if (e.column.colId !== 'rowMenu') {
          e.node.setSelected(true);
      }
    },
    applyFilters(filters) {
      this.activeFilters = filters;
      this.loadData();
    }
  }
};
</script>
