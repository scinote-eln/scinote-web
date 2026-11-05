<template>
  <div class="h-full">
    <DataTable
      v-if="repositoryColumnsDef.length > 0 || (archived && currentViewMode == 'active')"
      :columnDefs="repositoryColumnsDef"
      :tableId="'repository_table_' + repositoryId"
      :dataUrl="dataSource"
      ref="repositoryTable"
      :reloadingTable="reloadingTable"
      :toolbarActions="toolbarActions"
      :actionsUrl="toolbarActionsUrl"
      loadMethod="post"
      :postParams="{
        advanced_search: {
          filter_elements: activeFilter
        }
      }"
      :enableBarcodeSearch="true"
      :keyboardNavigation="true"
      :fetchColumnsOnReload="true"
      :addingNewRow="addingNewRow"
      :newRowTemplate="newRowTemplate"
      :activePageUrl="activePageUrl"
      :archivedPageUrl="archivedPageUrl"
      :currentViewMode="currentViewMode"
      :customManageColumnsModal="ManageColumnsModal"
      :manageColumnsModalProps="{ repositoryId, canManageColumns: canManageRepository }"
      @reloadColumns="legacyReloadTableComponent"
      :objectArchived="archived"
      :hiddenDataMessage="i18n.t('repositories.show.no_active_repository_rows_archived_repository')"
      @cancelCreation="cancelCreation"
      @showTextCell="showTextCellModal"
      @updateCell="updateCell"
      @uploadFile="uploadFile"
      @openStockModal="openStockModal"
      @updateRemindersCount="updateRemindersCount"
      @createRow="createRow"
      @changeName="changeName"
      @tableReloaded="onTableReloaded"
      @applyFilters="applyFilters"
      @startCreate="addingNewRow = true"
      @importItems="importItems"
      @clearAllReminders="clearAllReminders"
      @assign="openAssignToTaskModal"
      @duplicate="duplicateRows"
      @exportRows="exportRows"
      @exportConsumption="exportConsumption"
      @printLabel="printLabel"
      @archive="archiveRows"
      @restore="restoreRows"
      @delete="deleteRows"
      @createEvent="createEvent"
      @cellKeyboardActivate="onCellKeyboardActivate"
    ></DataTable>
    <div v-else class="flex items-center justify-center w-full h-96 text-sn-grey-500">
      {{ i18n.t('repositories.show.laoding_table_configuration') }}
    </div>
    <teleport to="body">
      <ImportRepositoryModal
        ref="importModal"
        :repository-url="repositoryUrl"
        @import-success="reloadingTable = true" />
      <TextCellModal
        v-if="textCellModalObject"
        :row="textCellModalObject.row"
        :colDef="textCellModalObject.colDef"
        @updateCell="updateCell"
        @close="textCellModalObject = null"/>
      <StockValueModal
        v-if="stockValueModalUrl"
        :stockUrl="stockValueModalUrl"
        @updateStock="updateStock"
        @close="stockValueModalUrl = null"/>
      <ExportItemsModal
        v-if="exportParams"
        :repository="repositoryVersion"
        :params="exportParams"
        @close="exportParams = null"/>
      <ExportConsumptionModal
        v-if="exportStockConsumptionRows"
        :repository="repositoryVersion"
        :rows="exportStockConsumptionRows"
        @close="exportStockConsumptionRows = null"/>
      <PrintModal
        v-if="printLabelRows"
        :repositoryId="repositoryId"
        :rowIds="printLabelRows"
        @close="printLabelRows = null"/>
      <AssignToTasksModal
        v-if="assignToTasksModalRows"
        :rowsToAssign="assignToTasksModalRows"
        :repositoryId="repositoryId"
        @reloadTable="reloadingTable = true"
        @close="assignToTasksModalRows = null"/>
      <CreateEventModal
        v-if="createEventModalRow"
        :repositoryId="repositoryId"
        :repositoryRowId="createEventModalRow"
        @event:created="createEventModalRow = null"
        @close="createEventModalRow = null"/>
    </teleport>
  </div>
</template>
<script>
import DataTable from '../shared/datatable/table.vue';
import axios from '../../packs/custom_axios.js';
import ColumnsMixin from './columns_mixin.js';
import TextCellModal from './modals/text_cell.vue';
import StockValueModal from './modals/stock_value_modal.vue';
import ImportRepositoryModal from '../repositories/modals/import/container.vue';
import AssignToTasksModal from './modals/assign_to_tasks.vue';
import ExportItemsModal from './modals/export_items.vue';
import ExportConsumptionModal from './modals/export_stock_consumption_modal.vue';
import PrintModal from './modals/print_modal.vue';
import CreateEventModal from '../equipment_bookings/manage_modal.vue';
import RepositoryFilters from './filters.vue'
import ManageColumnsModal from './modals/manage_columns.vue';

import {
  repository_table_index_ag_path,
  repository_path,
  repository_repository_rows_path,
  repository_repository_row_path,
  repository_repository_row_repository_cell_path,
  rails_direct_uploads_path,
  team_repository_hide_reminders_path,
  actions_toolbar_repository_repository_rows_path,
  repository_copy_records_path,
  repository_archive_records_path,
  repository_restore_records_path,
  repository_delete_records_path
} from '../../routes.js';

export default {
  name: 'RepositoryTable',
  props: {
    repositoryId: Number,
    createUrl: String,
    activePageUrl: String,
    archivedPageUrl: String,
    currentViewMode: { type: String, default: 'active' },
    canManageRepository: { type: Boolean, default: false },
    canManageFilters: { type: Boolean, default: false },
    archived: { type: Boolean }
  },
  components: {
    DataTable,
    TextCellModal,
    StockValueModal,
    ImportRepositoryModal,
    RepositoryFilters,
    AssignToTasksModal,
    ExportItemsModal,
    ExportConsumptionModal,
    PrintModal,
    CreateEventModal
  },
  mixins: [ColumnsMixin],
  data: () => ({
    ManageColumnsModal,
    repositoryVersion: null,
    addingNewRow: false,
    reloadingTable: false,
    textCellModalObject: null,
    stockValueModalUrl: null,
    hasActiveReminders: false,
    assignToTasksModalRows: null,
    exportParams: null,
    exportStockConsumptionRows: null,
    printLabelRows: null,
    createEventModalRow: null,
    currentPageRows: [],
    activeFilter: [],
    itemCardFocus: null,
    newRowTemplate: {
      name: {
        value: '',
        isValid: false
      },
    },
  }),
  created() {
    window.repositoryTable = this;
    this.loadRepository();
  },
  beforeUnmount() {
    delete window.repositoryTable;
    this.stopItemCardFocus(false);
  },
  computed: {
    toolbarActions() {
      const left = [];
      const right = [];
      const isActiveView = this.currentViewMode !== 'archived';

      if (this.createUrl && isActiveView) {
        left.push({
          name: 'startCreate',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('repositories.add_new_record'),
          type: 'emit',
          path: this.createUrl,
          buttonStyle: 'btn btn-primary'
        });
        left.push({
          name: 'importItems',
          icon: 'sn-icon sn-icon-import',
          label: this.i18n.t('repositories.import_records.update_inventory'),
          type: 'emit',
          buttonStyle: 'btn btn-light'
        });
      }

      if (this.hasActiveReminders && isActiveView) {
        left.push({
          name: 'clearAllReminders',
          icon: 'fas fa-bell-slash',
          label: this.i18n.t('repositories.hide_reminders'),
          type: 'emit',
          buttonStyle: 'btn btn-light'
        });
      }

      right.push({
        name: 'filters',
        type: 'component',
        params: {
          componentRenderer: RepositoryFilters,
          repositoryId: this.repositoryId,
          canManageFilters: this.canManageFilters
        }
      });

      return {
        left: left,
        right: right
      };
    },
    dataSource() {
      return repository_table_index_ag_path(this.repositoryId);
    },
    repositoryUrl() {
      return repository_path(this.repositoryId);
    },
    createRowUrl() {
      return repository_repository_rows_path(this.repositoryId);
    },
    toolbarActionsUrl() {
      return actions_toolbar_repository_repository_rows_path(this.repositoryId)
    },
  },
  methods: {
    // Item card opened with Enter on a Name cell: Tab cycles inside the card
    // until it closes, then focus returns to that Name cell.
    onCellKeyboardActivate({ column, rowIndex }) {
      if (column.getColId() !== 'name') return;

      this.$nextTick(() => {
        if (this.isItemCardShowing()) this.startItemCardFocus(rowIndex);
      });
    },
    isItemCardShowing() {
      return Boolean(window.repositoryItemSidebarComponent?.isShowing);
    },
    startItemCardFocus(rowIndex) {
      this.stopItemCardFocus(false);
      const wrapper = document.getElementById('repository-item-sidebar-wrapper');
      if (!wrapper) return;

      const observer = new MutationObserver(() => {
        if (!this.isItemCardShowing()) this.stopItemCardFocus(true);
      });
      observer.observe(wrapper, { attributes: true, attributeFilter: ['style', 'class'] });
      this.itemCardFocus = { rowIndex, wrapper, observer };
      document.addEventListener('keydown', this.handleItemCardKeydown, true);
      wrapper.focus({ preventScroll: true });
    },
    stopItemCardFocus(restoreFocus) {
      if (!this.itemCardFocus) return;

      const { rowIndex, wrapper, observer } = this.itemCardFocus;
      observer.disconnect();
      document.removeEventListener('keydown', this.handleItemCardKeydown, true);
      this.itemCardFocus = null;

      if (!restoreFocus) return;
      // Don't take focus back if the card was closed by clicking somewhere else
      const active = document.activeElement;
      if (!active || active === document.body || wrapper.contains(active)) {
        this.$refs.repositoryTable?.gridApi?.setFocusedCell(rowIndex, 'name');
      }
    },
    handleItemCardKeydown(event) {
      if (!this.itemCardFocus) return;
      if (!this.isItemCardShowing()) {
        this.stopItemCardFocus(true);
        return;
      }
      // Leave keys alone while a modal opened from the card is in front of it
      if (document.querySelector('.modal.in')) return;

      if (event.key === 'Escape') {
        this.closeItemCardOnEscape(event);
      } else if (event.key === 'Tab') {
        this.trapTabInItemCard(event);
      }
    },
    closeItemCardOnEscape(event) {
      const { target } = event;
      const { wrapper } = this.itemCardFocus;
      if (event.defaultPrevented || target.closest?.('.sn-select-dropdown, .sn-dropdown, .dp__menu')) return;

      // First Escape closes a dropdown opened inside the card (they close on an outside click)
      if (document.querySelector('.sn-select-dropdown, .sn-dropdown')) {
        wrapper.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
        wrapper.dispatchEvent(new MouseEvent('click', { bubbles: true }));
        return;
      }
      const close = () => window.repositoryItemSidebarComponent?.toggleShowHideSidebar(null);
      if (target.matches?.('input, textarea, select, [contenteditable="true"]')) {
        // Let the field handle Escape (e.g. cancel an edit) first; close only if it kept focus
        setTimeout(() => {
          if (this.itemCardFocus && document.activeElement === target) close();
        });
        return;
      }
      close();
    },
    trapTabInItemCard(event) {
      const { wrapper } = this.itemCardFocus;
      const focusable = Array.from(wrapper.querySelectorAll([
        'a[href]',
        'button:not([disabled])',
        'input:not([disabled]):not([type="hidden"])',
        'select:not([disabled])',
        'textarea:not([disabled])',
        '[contenteditable="true"]',
        '[tabindex]:not([tabindex="-1"])'
      ].join(', '))).filter((el) => el.getClientRects().length > 0);

      // No stopPropagation: card dropdowns close themselves on Tab
      event.preventDefault();
      if (focusable.length === 0) {
        wrapper.focus({ preventScroll: true });
        return;
      }

      const index = focusable.indexOf(document.activeElement);
      let next;
      if (index === -1) {
        next = event.shiftKey ? focusable[focusable.length - 1] : focusable[0];
      } else {
        const step = event.shiftKey ? -1 : 1;
        next = focusable[(index + step + focusable.length) % focusable.length];
      }
      next.focus();
    },
    updateRowData(row) {
      // DataTable prepends unknown rows, so skip pushes for rows that aren't loaded
      if (!this.findLoadedRow(row.id)) return;

      this.$refs.repositoryTable.updateRowData(row);
      if ((row.attributes || row).active_reminders_count > 0) this.hasActiveReminders = true;
    },
    findLoadedRow(rowId) {
      return this.$refs.repositoryTable?.rowData?.find((r) => String(r.id) === String(rowId));
    },
    loadRepository() {
      axios.get(this.repositoryUrl)
        .then((response) => {
          this.repositoryVersion = response.data.data;
          this.hasActiveReminders = response.data.data.attributes.has_active_reminders;
          this.loadRepositoryColumns();
        });
    },
    onTableReloaded(rows) {
      this.reloadingTable = false;
      this.currentPageRows = rows;
    },
    importItems() {
      this.$refs.importModal.open();
    },
    clearAllReminders() {
      const rowIds = this.currentPageRows
        .filter((row) => row.active_reminders_count > 0)
        .map((row) => row.id);

      axios.post(team_repository_hide_reminders_path(this.repositoryVersion.attributes.team_id, this.repositoryId),
                 { visible_reminder_repository_row_ids: rowIds })
        .then(() => {
          this.hasActiveReminders = false;
          this.reloadingTable = true;
        });
    },
    cancelCreation() {
      this.addingNewRow = false;
    },
    createRow(newRow) {
      axios.post(this.createRowUrl, {
        repository_row: {
          name: newRow.name.value
        }
      }).then((response) => {
        this.addingNewRow = false;
        this.$refs.repositoryTable.updateRowData(response.data.data);
      }).catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
      });
    },
    changeName(name, row) {
      axios.patch(repository_repository_row_path(row.repository_id, row.id), {
        repository_row: {
          name
        }
      }).then((response) => {
        this.$refs.repositoryTable.updateRowData(response.data.data);
      }).catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
      });
    },
    showTextCellModal(_e, rows, colDef) {
      this.textCellModalObject = {
        row: rows[0],
        colDef
      }
    },
    openAssignToTaskModal(_e, rows) {
      this.assignToTasksModalRows = rows.map((row) => ( row.id ));
    },
    duplicateRows(_e, rows) {
      const rowIds = rows.map((row) => row.id);
      axios.post(repository_copy_records_path(this.repositoryId), {
        selected_rows: rowIds
      }).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.flash, 'success');
      }).catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
      });
    },
    printLabel(_e, rows) {
      this.printLabelRows = rows.map((row) => ( row.id ));
    },
    exportConsumption(_e, rows) {
      this.exportStockConsumptionRows = rows.map((row) => ( row.id ));
    },
    createEvent(_e, rows) {
      this.createEventModalRow = parseInt(rows[0].id, 10);
    },
    archiveRows(_e, rows) {
      const rowIds = rows.map((row) => row.id);
      axios.post(repository_archive_records_path(this.repositoryId), {
        selected_rows: rowIds
      }).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.flash, 'success');
      }).catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
      });
    },
    restoreRows(_e, rows) {
      const rowIds = rows.map((row) => row.id);
      axios.post(repository_restore_records_path(this.repositoryId), {
        selected_rows: rowIds
      }).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.flash, 'success');
      }).catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
      });
    },
    deleteRows(_e, rows) {
      const rowIds = rows.map((row) => row.id);
      axios.post(repository_delete_records_path(this.repositoryId), {
        selected_rows: rowIds
      }).then((response) => {
        this.reloadingTable = true;
        HelperModule.flashAlertMsg(response.data.flash, 'success');
      }).catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
      });
    },
    exportRows(_e, rows) {
      const rowIds = rows.map((row) => row.id);

      const headerIDs = this.legacyColumnIds();

      this.exportParams = {
        rows: rowIds,
        headers: headerIDs
      }
    },
    uploadFile(row, columnDef, file) {
      const upload = new ActiveStorage.DirectUpload(file, rails_direct_uploads_path());
      upload.create((error, blob) => {
        if (error) {
          HelperModule.flashAlertMsg(`Upload failed: ${error}`, 'danger');
        } else {
          this.updateCell(row, columnDef, blob.signed_id);
        }
      });
    },
    updateCell(row, columnDef, value) {
      axios.post(repository_repository_row_repository_cell_path({
        repository_id: row.repository_id,
        repository_row_id: row.id,
        repository_column_id: columnDef.field.split('_')[1] }), {
        value: value
      }).then((response) => {
        const updatedRow = {
          id: row.id,
        }
        updatedRow[columnDef.field] = response.data.cell;
        if (response.data.active_reminders_count !== undefined) {
          updatedRow.active_reminders_count = response.data.active_reminders_count;
        }
        this.updateRowData(updatedRow);
        this.textCellModalObject = null;
      }).catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
        this.textCellModalObject = null;
      });
    },
    openStockModal(row) {
      this.stockValueModalUrl = row.stock.value.stock_url;
    },
    updateStock(row) {
      this.stockValueModalUrl = null;
      this.$refs.repositoryTable.updateRowData(row);
      if (row.attributes?.active_reminders_count > 0) this.hasActiveReminders = true;
    },
    updateRemindersCount(row, count) {
      const updatedRow = {
        id: row.id,
      }
      updatedRow['active_reminders_count'] = count;
      this.$refs.repositoryTable.updateRowData(updatedRow);
      if (count > 0) this.hasActiveReminders = true;
    },
    legacyReloadTableComponent() {
      this.repositoryColumnsDef = []
      this.loadRepositoryColumns();
    },
    applyFilters(filters) {
      this.activeFilter = filters.data
      this.reloadingTable = true
    }
  }
};
</script>
