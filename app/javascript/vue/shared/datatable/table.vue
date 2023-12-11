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
        :currentViewRender="currentViewRender"
        :viewRenders="viewRenders"
        :filters="filters"
        @applyFilters="applyFilters"
        @setTableView="switchViewRender('table')"
        @setCardsView="switchViewRender('cards')"
      />
      <div v-if="currentViewRender === 'cards'" class="flex-grow basis-64 overflow-y-auto overflow-x-visible p-2 -ml-2">
        <div class="grid grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-4">
          <slot v-for="element in rowData" :key="element.id" name="card" :dtComponent="this" :params="element"></slot>
        </div>
      </div>
      <ag-grid-vue
        v-if="currentViewRender === 'table'"
        class="ag-theme-alpine w-full flex-grow h-full z-10"
        :class="{'opacity-0': initializing}"
        :columnDefs="extendedColumnDefs"
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
      <ActionToolbar
        v-if="selectedRows.length > 0 && actionsUrl"
        :actionsUrl="actionsUrl"
        :params="actionsParams"
        @toolbar:action="emitAction" />
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
          <SelectDropdown
            :value="perPage"
            :options="perPageOptions"
            @change="setPerPage"
          ></SelectDropdown>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { AgGridVue } from 'ag-grid-vue3';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import axios from '../../../packs/custom_axios.js';
import SelectDropdown from '../select_dropdown.vue';
import Pagination from './pagination.vue';
import CustomHeader from './tableHeader';
import ActionToolbar from './action_toolbar.vue';
import Toolbar from './toolbar.vue';
import RowMenuRenderer from './row_menu_renderer.vue';

export default {
  name: 'App',
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
      required: true,
    },
    reloadingTable: {
      type: Boolean,
      default: false,
    },
    activePageUrl: {
      type: String,
    },
    archivedPageUrl: {
      type: String,
    },
    currentViewMode: {
      type: String,
      default: 'active',
    },
    viewRenders: {
      type: Object,
    },
    filters: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      rowData: [],
      gridApi: null,
      columnApi: null,
      defaultColDef: {
        resizable: true,
      },
      perPage: 20,
      page: 1,
      order: null,
      totalPage: 0,
      selectedRows: [],
      searchValue: '',
      initializing: true,
      activeFilters: {},
      currentViewRender: 'table',
      cardCheckboxes: [],
    };
  },
  components: {
    AgGridVue,
    SelectDropdown,
    PerfectScrollbar,
    Pagination,
    agColumnHeader: CustomHeader,
    ActionToolbar,
    Toolbar,
    RowMenuRenderer,
  },
  computed: {
    perPageOptions() {
      return [10, 20, 50, 100].map((value) => ([value, `${value} ${this.i18n.t('datatable.rows')}`]));
    },
    tableState() {
      if (!localStorage.getItem(`datatable:${this.tableId}_columns_state`)) return null;

      return JSON.parse(localStorage.getItem(`datatable:${this.tableId}_columns_state`));
    },
    actionsParams() {
      return {
        items: JSON.stringify(this.selectedRows.map((row) => ({ id: row.id, type: row.type }))),
      };
    },
    gridOptions() {
      return {
        suppressCellFocus: true,
      };
    },
    extendedColumnDefs() {
      const columns = this.columnDefs.map((column) => ({
        ...column,
        cellRendererParams: {
          dtComponent: this,
        },
      }));

      if (this.withCheckboxes) {
        columns.unshift({
          field: 'checkbox',
          headerCheckboxSelection: true,
          headerCheckboxSelectionFilteredOnly: true,
          checkboxSelection: true,
          width: 48,
          minWidth: 48,
          resizable: false,
          pinned: 'left',
        });
      }

      if (this.withRowMenu) {
        columns.push({
          field: 'rowMenu',
          headerName: '',
          width: 42,
          minWidth: 42,
          resizable: false,
          sortable: false,
          cellRenderer: 'RowMenuRenderer',
          cellRendererParams: {
            dtComponent: this,
          },
          pinned: 'right',
          cellStyle: {
            padding: 0,
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            overflow: 'visible',
          },
        });
      }

      return columns;
    },
  },
  watch: {
    reloadingTable() {
      if (this.reloadingTable) {
        this.loadData();
      }
    },
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
      return data.map((item) => ({
        ...item.attributes,
        id: item.id,
        type: item.type,
      }));
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
            filters: this.activeFilters,
          },
        })
        .then((response) => {
          this.selectedRows = [];
          this.gridApi.setRowData(this.formatData(response.data.data));
          this.rowData = this.formatData(response.data.data);
          this.totalPage = response.data.meta.total_pages;
          this.$emit('tableReloaded');
        });
    },
    onGridReady(params) {
      this.gridApi = params.api;
      this.columnApi = params.columnApi;

      if (this.tableState) {
        this.columnApi.applyColumnState({
          state: this.tableState,
          applyOrder: true,
        });
      }
      setTimeout(() => {
        this.initializing = false;
      }, 200);
    },
    onFirstDataRendered() {
      this.resize();
    },
    setPerPage(value) {
      this.perPage = value;
      this.page = 1;
      this.loadData();
    },
    setPage(page) {
      this.page = page;
      this.loadData();
    },
    setOrder() {
      const orderState = this.columnApi.getColumnState()
        .filter((column) => column.sort)
        .map((column) => ({
          column: column.colId,
          dir: column.sort,
        }));
      const [order] = orderState;
      this.order = order;
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
      if (e.column.colId !== 'rowMenu' && e.column.userProvidedColDef.notSelectable !== true) {
        e.node.setSelected(true);
      }
    },
    applyFilters(filters) {
      this.activeFilters = filters;
      this.loadData();
    },
    switchViewRender(view) {
      if (this.currentViewRender === view) return;

      this.currentViewRender = view;
      this.initializing = true;
      this.selectedRows = [];
    },
  },
};
</script>
