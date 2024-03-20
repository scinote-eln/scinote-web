<template>
  <div v-if="!stateLoading" class="flex flex-col h-full" :class="{'pb-4': windowScrollerSeen && selectedRows.length === 0}">
    <div
      class="relative flex flex-col flex-grow z-10"
      :class="{'overflow-y-hidden pb-20': currentViewRender === 'cards'}"
    >
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
        @pinColumn="pinColumn"
        @unPinColumn="unPinColumn"
        @reorderColumns="reorderColumns"
        @resetColumnsToDefault="resetColumnsToDefault"
      />
      <div v-if="this.objectArchived && this.currentViewMode === 'active'" class="pt-6" >
        <em> {{ hiddenDataMessage }} </em>
      </div>
      <div v-else class="w-full h-full">
        <div v-if="currentViewRender === 'cards'" ref="cardsContainer" @scroll="handleScroll"
            class="flex-grow basis-64 overflow-y-auto h-full overflow-x-visible p-2 -ml-2">
          <div class="grid gap-4" :class="gridColsClass">
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
          :enableCellTextSelection="true"
          @grid-ready="onGridReady"
          @first-data-rendered="onFirstDataRendered"
          @sortChanged="setOrder"
          @columnResized="onColumnResized"
          @columnMoved="onColumnMoved"
          @bodyScroll="handleScroll"
          @columnPinned="handlePin"
          @columnVisible="handleVisibility"
          @rowSelected="setSelectedRows"
          @cellClicked="clickCell"
          :CheckboxSelectionCallback="withCheckboxes"
        >
        </ag-grid-vue>
        <div v-if="dataLoading" class="flex absolute top-0 items-center justify-center w-full flex-grow h-full z-10">
          <img src="/images/medium/loading.svg" alt="Loading" class="p-16 rounded-xl bg-sn-white" />
        </div>
      </div>
      <ActionToolbar
        v-if="selectedRows.length > 0 && actionsUrl"
        :actionsUrl="actionsUrl"
        :params="actionsParams"
        @toolbar:action="emitAction" />
    </div>
    <div v-if="scrollMode == 'pages'" class="flex items-center py-4" :class="{'opacity-0': initializing }">
      <div class="flex items-center gap-4">
        {{ i18n.t('datatable.show') }}
        <div class="w-36">
          <SelectDropdown
            :value="perPage"
            :options="perPageOptions"
            @change="setPerPage"
          ></SelectDropdown>
        </div>
        <div v-show="!dataLoading">
          <span v-if="selectedRows.length">
            {{ i18n.t('datatable.entries.selected', { count: totalEntries, selected: selectedRows.length }) }}
          </span>
          <span v-else>
            {{ i18n.t('datatable.entries.total', { count: totalEntries, selected: selectedRows.length }) }}
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
</template>

<script>

/* global GLOBAL_CONSTANTS */
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
    },
    objectArchived: {
      type: Boolean,
      default: false
    },
    hiddenDataMessage: {
      type: String
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
      totalEntries: null,
      selectedRows: [],
      keepSelection: false,
      searchValue: '',
      initializing: true,
      activeFilters: {},
      currentViewRender: 'table',
      cardCheckboxes: [],
      dataLoading: true,
      stateLoading: true,
      lastPage: false,
      tableState: null,
      userSettingsUrl: null,
      gridReady: false,
      windowScrollerSeen: false,
      resetGridCols: false,
      navigatorCollapsed: false,
      gridColsClass: ''
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
    actionsParams() {
      return {
        items: JSON.stringify(this.selectedRows.map((row) => ({ id: row.id, type: row.type })))
      };
    },
    gridOptions() {
      return {
        suppressCellFocus: true,
        rowHeight: 40,
        headerHeight: 40,
        getRowId: (params) => `e2e-TB-row-${params.data.code || params.data.id}`
      };
    },
    extendedColumnDefs() {
      const columns = this.columnDefs.map((column) => ({
        ...column,
        minWidth: column.minWidth || 110,
        cellRendererParams: {
          dtComponent: this
        },
        pinned: (column.field === 'name' ? 'left' : null),
        comparator: () => null
      }));

      if (this.withCheckboxes) {
        columns.unshift({
          field: 'checkbox',
          headerCheckboxSelection: true,
          headerCheckboxSelectionFilteredOnly: true,
          checkboxSelection: true,
          suppressMovable: true,
          width: 40,
          minWidth: 40,
          maxWidth: 40,
          resizable: true,
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
    },
    stateKey() {
      return `${this.tableId}_${this.currentViewMode}_state`;
    }
  },
  watch: {
    reloadingTable() {
      if (this.reloadingTable) {
        this.updateTable();
        this.$nextTick(() => {
          this.selectedRows = [];
        });
      }
    },
    perPage() {
      this.saveTableState();
    },
    resetGridCols() {
      if (this.resetGridCols) {
        this.setGridColsClass();
        this.resetGridCols = false;
      }
    },
    currentViewRender() {
      if (this.currentViewRender === 'cards') {
        this.setGridColsClass();
      }
    }
  },
  created() {
    window.resetGridColumns = (newNavigatorCollapsed) => {
      setTimeout(() => {
        this.navigatorCollapsed = newNavigatorCollapsed;
        this.setGridColsClass();
      }, 400);
    };
    this.userSettingsUrl = document.querySelector('meta[name="user-settings-url"]').getAttribute('content');
    this.fetchTableState();
  },
  mounted() {
    this.navigatorCollapsed = document.querySelector('.sci--layout').getAttribute('data-navigator-collapsed') === 'true';
    this.setGridColsClass();

    window.addEventListener('resize', this.resize);
  },
  beforeDestroy() {
    delete window.resetGridColumns;
    window.removeEventListener('resize', this.resize);
  },
  methods: {
    setGridColsClass() {
      if (this.currentViewRender !== 'cards') return;
      const availableGridWidth = document.querySelector('.sci--layout-content').offsetWidth;
      const { paddingLeft, paddingRight } = getComputedStyle(document.querySelector('.sci--layout-content'));
      const padding = parseInt(paddingLeft, 10) + parseInt(paddingRight, 10);

      let maxGridCols = Math.floor((availableGridWidth - padding) / GLOBAL_CONSTANTS.TABLE_CARD_MIN_WIDTH) || 1;
      if (maxGridCols > 1) {
        const gap = (maxGridCols - 1) * GLOBAL_CONSTANTS.TABLE_CARD_GAP;
        maxGridCols = Math.floor((availableGridWidth - gap - padding) / GLOBAL_CONSTANTS.TABLE_CARD_MIN_WIDTH);
      }

      if (this.navigatorCollapsed) {
        this.gridColsClass = 'grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4';
      } else {
        this.gridColsClass = `grid-cols-${maxGridCols}`;
      }
    },
    handleScroll() {
      if (this.scrollMode === 'pages') return;

      let target = null;
      if (this.currentViewRender === 'cards') {
        target = this.$refs.cardsContainer;
      } else {
        target = document.querySelector('.ag-body-viewport');
      }

      if (!target) return;

      if (target.scrollTop + target.clientHeight >= target.scrollHeight - 50) {
        if (this.dataLoading || this.lastPage) return;

        this.dataLoading = true;
        this.page += 1;
        this.loadData();
      }
    },
    handlePin(event) {
      if (event.pinned === 'right') {
        this.columnApi.setColumnPinned(event.column.colId, null);
      }
      this.saveTableState();
    },
    handleVisibility(event) {
      if (!event.visible && event.source !== 'api') {
        this.columnApi.setColumnVisible(event.column.colId, true);
      }
      this.saveTableState();
    },
    // Table states
    fetchTableState() {
      axios.get(this.userSettingsUrl, { params: { key: this.stateKey } })
        .then((response) => {
          if (response.data.data) {
            this.tableState = response.data.data;
            this.currentViewRender = this.tableState.currentViewRender;
            this.perPage = this.tableState.perPage;
            this.order = this.tableState.order;
            if (this.currentViewRender === 'cards') {
              this.initializing = false;
            }
          }
          this.stateLoading = false;
          this.loadData();
        });
    },
    applyTableState() {
      const { columnsState } = this.tableState;
      this.columnsState = columnsState;

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

      setTimeout(() => {
        this.initializing = false;
      }, 200);
    },
    saveTableState() {
      if (this.initializing) {
        return;
      }
      const columnsState = this.columnApi ? this.columnApi.getColumnState() : this.tableState?.columnsState || [];
      const tableState = {
        columnsState,
        order: this.order,
        currentViewRender: this.currentViewRender,
        perPage: this.perPage
      };
      const settings = {
        key: this.stateKey,
        data: tableState
      };
      axios.put(this.userSettingsUrl, { settings: [settings] });
      this.tableState = tableState;
    },
    getRowClass() {
      if (this.currentViewMode === 'archived') {
        return '!bg-sn-super-light-grey';
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
      this.windowScrollerSeen = document.documentElement.scrollWidth > document.documentElement.clientWidth;
      this.setGridColsClass();
      if (this.tableState) return;

      this.columnApi?.autoSizeAllColumns();
    },
    updateTable() {
      if (this.scrollMode === 'pages') {
        this.loadData();
      } else {
        this.reloadTable();
      }
    },
    reloadTable(clearSelection = true) {
      if (this.dataLoading) return;

      this.dataLoading = true;
      if (clearSelection) this.selectedRows = [];
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
            if (this.gridApi) this.gridApi.setRowData([]);
            this.rowData = [];
          }

          if (this.scrollMode === 'pages') {
            if (this.gridApi) this.gridApi.setRowData(this.formatData(response.data.data));
            this.rowData = this.formatData(response.data.data);
          } else {
            this.handleInfiniteScroll(response);
          }
          this.totalPage = response.data.meta.total_pages;
          this.totalEntries = response.data.meta.total_count;
          this.$emit('tableReloaded');
          this.dataLoading = false;
          this.restoreSelection();

          this.handleScroll();
        });
    },
    handleInfiniteScroll(response) {
      const newRows = this.rowData.slice();
      this.formatData(response.data.data).forEach((row) => {
        if (this.currentViewMode === 'active' && row.archived) {
          return;
        }
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
    },
    onGridReady(params) {
      this.gridApi = params.api;
      this.columnApi = params.columnApi;
      this.gridReady = true;
      if (this.tableState) {
        this.applyTableState();
      } else {
        this.gridApi.sizeColumnsToFit();
        this.initializing = false;
      }
    },
    onFirstDataRendered() {
      this.resize();
    },
    setPerPage(value) {
      this.perPage = value;
      this.page = 1;
      this.lastPage = false;
      this.reloadTable(false);
    },
    setPage(page) {
      this.page = page;
      this.loadData(false);
    },
    setOrder() {
      const orderState = this.getOrder(this.columnApi.getColumnState());
      const [order] = orderState;
      this.order = order;
      this.saveTableState();
      this.reloadTable(false);
    },
    restoreSelection() {
      if (this.gridApi) {
        this.gridApi.forEachNode((node) => {
          if (this.selectedRows.find((row) => row.id === node.data.id)) {
            node.setSelected(true);
          }
        });
      }
    },
    setSelectedRows(e) {
      if (!this.rowData.find((row) => row.id === e.data.id)) return;

      if (e.node.isSelected()) {
        if (this.selectedRows.find((row) => row.id === e.data.id)) return;

        this.selectedRows.push(e.data);
      } else {
        this.selectedRows = this.selectedRows.filter((row) => row.id !== e.data.id);
      }
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
      this.columnApi = null;
      this.gridApi = null;
      this.saveTableState();
      this.initializing = true;
      this.selectedRows = [];
    },
    hideColumn(column) {
      this.columnApi.setColumnVisible(column.field, false);
    },
    showColumn(column) {
      this.columnApi.setColumnVisible(column.field, true);
    },
    pinColumn(column) {
      this.columnApi.setColumnPinned(column.field, 'left');
      this.hideLastPinnedResizeCell();
    },
    unPinColumn(column) {
      this.columnApi.setColumnPinned(column.field, null);
      this.hideLastPinnedResizeCell();
    },
    reorderColumns(columns) {
      this.columnApi.moveColumns(columns, 1);
      this.saveTableState();
    },
    resetColumnsToDefault() {
      this.columnApi.resetColumnState();
      this.gridApi.sizeColumnsToFit();
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
      this.reloadTable(false);
    },
    onColumnMoved(event) {
      if (event.finished) {
        this.hideLastPinnedResizeCell();
        this.saveTableState();
      }
    },
    onColumnResized(event) {
      if (event.finished) {
        this.saveTableState();
      }
    },
    hideLastPinnedResizeCell() {
      $('.ag-pinned-left-header .ag-header-cell .ag-header-cell-resize').css('opacity', 100);
      let lastPinnedColIndex = 0;
      // eslint-disable-next-line func-names
      $('.ag-pinned-left-header .ag-header-cell').each(function () {
        const colIndex = parseInt($(this).attr('aria-colindex'), 10);
        if (colIndex > lastPinnedColIndex) lastPinnedColIndex = colIndex;
      });
      $(`.ag-pinned-left-header .ag-header-cell[aria-colindex="${lastPinnedColIndex}"] .ag-header-cell-resize`).css('opacity', 0);
    }
  }
};
</script>
