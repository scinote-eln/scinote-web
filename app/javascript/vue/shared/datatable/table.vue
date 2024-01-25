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
        :columnDefs="columnDefs"
        :tableState="tableState"
        :order="order"
        @applyFilters="applyFilters"
        @setTableView="switchViewRender('table')"
        @setCardsView="switchViewRender('cards')"
        @sort="applyOrder"
        @hideColumn="hideColumn"
        @showColumn="showColumn"
      />
      <div v-if="currentViewRender === 'cards'" ref="cardsContainer" @scroll="handleScroll"
           class="flex-grow basis-64 overflow-y-auto overflow-x-visible p-2 -ml-2">
        <div class="grid grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-4">
          <slot v-for="element in rowData" :key="element.id" name="card" :dtComponent="this" :params="element"></slot>
        </div>
      </div>
      <ag-grid-vue
        v-if="currentViewRender === 'table'"
        class="ag-theme-alpine w-full flex-grow h-full z-10"
        :class="{'opacity-0': initializing }"
        :columnDefs="extendedColumnDefs"
        :rowData="rowData"
        :defaultColDef="defaultColDef"
        :rowSelection="'multiple'"
        :suppressRowTransform="true"
        :gridOptions="gridOptions"
        :suppressRowClickSelection="true"
        :getRowClass="getRowClass"
        @grid-ready="onGridReady"
        @first-data-rendered="onFirstDataRendered"
        @sortChanged="setOrder"
        @columnResized="saveTableState"
        @columnMoved="saveTableState"
        @bodyScroll="handleScroll"
        @rowSelected="setSelectedRows"
        @cellClicked="clickCell"
        :CheckboxSelectionCallback="withCheckboxes"
      >
      </ag-grid-vue>
      <div v-if="dataLoading" class="flex absolute top-0 items-center justify-center w-full flex-grow h-full z-10">
        <img src="/images/medium/loading.svg" alt="Loading" class="p-4 rounded-xl bg-sn-white" />
      </div>
      <ActionToolbar
        v-if="selectedRows.length > 0 && actionsUrl"
        :actionsUrl="actionsUrl"
        :params="actionsParams"
        @toolbar:action="emitAction" />
    </div>
    <div v-if="scrollMode == 'pages'" class="flex items-center py-4">
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
      default: true
    },
    withRowMenu: {
      type: Boolean,
      default: false
    },
    tableId: {
      type: String,
      required: true
    },
    columnDefs: {
      type: Array,
      default: () => []
    },
    dataUrl: {
      type: String,
      required: true
    },
    actionsUrl: {
      type: String
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
      type: String
    },
    archivedPageUrl: {
      type: String
    },
    currentViewMode: {
      type: String,
      default: 'active'
    },
    viewRenders: {
      type: Object
    },
    filters: {
      type: Array,
      default: () => []
    },
    scrollMode: {
      type: String,
      default: 'pages'
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
      initializing: true,
      activeFilters: {},
      currentViewRender: 'table',
      cardCheckboxes: [],
      dataLoading: true,
      lastPage: false
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
    RowMenuRenderer
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
        items: JSON.stringify(this.selectedRows.map((row) => ({ id: row.id, type: row.type })))
      };
    },
    gridOptions() {
      return {
        suppressCellFocus: true
      };
    },
    extendedColumnDefs() {
      const columns = this.columnDefs.map((column) => ({
        ...column,
        cellRendererParams: {
          dtComponent: this
        },
        comparator: () => false
      }));

      if (this.withCheckboxes) {
        columns.unshift({
          field: 'checkbox',
          headerCheckboxSelection: true,
          headerCheckboxSelectionFilteredOnly: true,
          checkboxSelection: true,
          suppressMovable: true,
          width: 48,
          minWidth: 48,
          resizable: false,
          pinned: 'left',
          lockPosition: 'left'
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
          suppressMovable: true,
          cellRenderer: 'RowMenuRenderer',
          cellRendererParams: {
            dtComponent: this
          },
          cellStyle: {
            padding: 0,
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            overflow: 'visible'
          }
        });
      }

      return columns;
    }
  },
  watch: {
    reloadingTable() {
      if (this.reloadingTable) {
        this.updateTable();
      }
    },
    currentViewRender() {
      this.columnApi = null;
      this.gridApi = null;
      this.saveTableState();
    },
    perPage() {
      this.saveTableState();
    }
  },
  created() {
    if (this.tableState) {
      this.currentViewRender = this.tableState.currentViewRender || 'table';
      this.perPage = this.tableState.perPage || 20;
      this.order = this.tableState.order;
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
    handleScroll() {
      let target = null;
      if (this.currentViewRender === 'cards') {
        target = this.$refs.cardsContainer;
      } else {
        target = document.querySelector('.ag-body-viewport');
      }
      if (target.scrollTop + target.clientHeight >= target.scrollHeight - 50) {
        if (this.dataLoading || this.lastPage) return;

        this.dataLoading = true;
        this.page += 1;
        this.loadData();
      }
    },
    getRowClass() {
      if (this.currentViewMode === 'archived') {
        return '!bg-sn-light-grey';
      }
      return '';
    },
    formatData(data) {
      return data.map((item) => ({
        ...item.attributes,
        id: item.id,
        type: item.type
      }));
    },
    resize() {
      if (this.tableState) return;

      this.gridApi.sizeColumnsToFit();
    },
    updateTable() {
      if (this.scrollMode === 'pages') {
        this.loadData();
      } else {
        this.reloadTable();
      }
    },
    reloadTable() {
      if (this.dataLoading) return;

      this.dataLoading = true;
      this.selectedRows = [];
      this.page = 1;
      this.loadData(true);
    },
    loadData(reload = false) {
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
          if (reload) {
            if (this.gridApi) {
              this.gridApi.setRowData([]);
            }
            this.rowData = [];
          }

          if (this.scrollMode === 'pages') {
            this.selectedRows = [];
            if (this.gridApi) {
              this.gridApi.setRowData(this.formatData(response.data.data));
            }
            this.rowData = this.formatData(response.data.data);
          } else {
            const newRows = this.rowData.slice();
            this.formatData(response.data.data).forEach((row) => {
              newRows.push(row);
            });
            this.rowData = newRows;
            if (this.gridApi) {
              const viewport = document.querySelector('.ag-body-viewport');
              const { scrollTop } = viewport;
              this.gridApi.setRowData(this.rowData);
              this.$nextTick(() => {
                viewport.scrollTop = scrollTop;
              });
            }
            this.lastPage = !response.data.meta.next_page;
          }
          this.totalPage = response.data.meta.total_pages;
          this.$emit('tableReloaded');
          this.dataLoading = false;
        });
    },
    onGridReady(params) {
      this.gridApi = params.api;
      this.columnApi = params.columnApi;

      if (this.tableState) {
        if (this.order) {
          this.tableState.columnsState.forEach((column) => {
            const updatedColumn = column;
            updatedColumn.sort = this.order.column === column.colId ? this.order.dir : null;
            return updatedColumn;
          });
        }
        this.columnApi.applyColumnState({
          state: this.tableState.columnsState,
          applyOrder: true
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
      this.lastPage = false;
      this.reloadTable();
    },
    setPage(page) {
      this.page = page;
      this.loadData();
    },
    setOrder() {
      const orderState = this.getOrder(this.columnApi.getColumnState());
      const [order] = orderState;
      this.order = order;
      this.saveTableState();
      this.reloadTable();
    },
    saveTableState() {
      let columnsState = this.tableState?.columnsState;
      if (this.columnApi) {
        columnsState = this.columnApi.getColumnState();
      }
      const tableState = {
        columnsState: columnsState || [],
        order: this.order,
        currentViewRender: this.currentViewRender,
        perPage: this.perPage
      };
      localStorage.setItem(`datatable:${this.tableId}_columns_state`, JSON.stringify(tableState));
    },
    setSelectedRows() {
      this.selectedRows = this.gridApi.getSelectedRows();
    },
    emitAction(action) {
      this.$emit(action.name, action, this.selectedRows);
    },
    setSearchValue(value) {
      this.searchValue = value;
      this.reloadTable();
    },
    clickCell(e) {
      if (e.column.colId !== 'rowMenu' && e.column.userProvidedColDef.notSelectable !== true) {
        e.node.setSelected(true);
      }
    },
    applyFilters(filters) {
      this.activeFilters = filters;
      this.reloadTable();
    },
    switchViewRender(view) {
      if (this.currentViewRender === view) return;

      this.currentViewRender = view;
      this.initializing = true;
      this.selectedRows = [];
    },
    hideColumn(column) {
      this.columnApi.setColumnVisible(column.field, false);
      this.saveTableState();
    },
    showColumn(column) {
      this.columnApi.setColumnVisible(column.field, true);
      this.saveTableState();
    },
    getOrder(columnsState) {
      if (!columnsState) return null;

      return columnsState.filter((column) => column.sort)
        .map((column) => ({
          column: column.colId,
          dir: column.sort
        }));
    },
    applyOrder(column, dir) {
      this.order = {
        column,
        dir
      };
      this.saveTableState();
      this.reloadTable();
    }
  }
};
</script>
