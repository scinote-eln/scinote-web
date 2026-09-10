<template>
  <div class="h-full">
    <DataTable
      v-if="repositoryColumnsDef.length > 0"
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
      :fetchColumnsOnReload="true"
      :addingNewRow="addingNewRow"
      :newRowTemplate="newRowTemplate"
      :activePageUrl="activePageUrl"
      :archivedPageUrl="archivedPageUrl"
      :currentViewMode="currentViewMode"
      @cancelCreation="cancelCreation"
      @showTextCell="showTextCellModal"
      @updateCell="updateCell"
      @uploadFile="uploadFile"
      @openStockModal="openStockModal"
      @updateRemindersCount="updateRemindersCount"
      @manageColumns="openManageColumnsModal"
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
        @close="createEventModalRow = null"/>
    </teleport>
    <button ref="legacyManageColumns" class="hidden manage-repo-column-index"
            :data-modal-url="repositoriesUrl"
            data-action="new">
    </button>
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

import {
  repository_table_index_ag_path,
  repository_path,
  repository_repository_rows_path,
  repository_repository_row_path,
  repository_repository_row_repository_cell_path,
  rails_direct_uploads_path,
  repository_repository_columns_path,
  edit_repository_repository_column_path,
  repository_columns_destroy_html_path,
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
    canManageRepository: { type: Boolean, default: false }
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
  },
  computed: {
    repositoriesUrl() {
      return repository_repository_columns_path(this.repositoryId)
    },
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
          repositoryId: this.repositoryId
        }
      });

      if (this.canManageRepository) {
        right.push({
          name: 'manageColumns',
          icon: 'sn-icon sn-icon-add-columns',
          type: 'emit',
          tooltip: this.i18n.t('libraries.repository_columns.button_tooltip'),
          buttonStyle: 'btn btn-light icon-btn btn-black'
        })
      }

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
    updateRowData(row) {
      this.$refs.repositoryTable.updateRowData(row);
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

      const headerIDs = [];
      this.repositoryColumnsDef.forEach((column) => {
        if (column.cellRendererParams?.legacyId) {
          headerIDs.push(column.cellRendererParams.legacyId);
        }
      });

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
        updatedRow[columnDef.field] = response.data;
        this.$refs.repositoryTable.updateRowData(updatedRow);
        this.textCellModalObject = null;
      }).catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
        textCellModalObject = null;
      });
    },
    openStockModal(row) {
      this.stockValueModalUrl = row.stock.value.stock_url;
    },
    updateStock(row) {
      this.stockValueModalUrl = null;
      this.$refs.repositoryTable.updateRowData(row);
    },
    updateRemindersCount(row, count) {
      const updatedRow = {
        id: row.id,
      }
      updatedRow['active_reminders_count'] = count;
      this.$refs.repositoryTable.updateRowData(updatedRow);
    },
    openManageColumnsModal() {
      this.$refs.legacyManageColumns.click();
    },
    legacyReloadTableComponent() {
      this.repositoryColumnsDef = []
      this.loadRepositoryColumns();
    },
    legacyColumnsHTML() {
      const columnsHTML = []
      this.customColumns.forEach((column, index) => {

        const name = column.attributes.name
        const typeName = I18n.t('libraries.manange_modal_column.select.' + column.attributes.data_type.split(/(?=[A-Z])/).join('_').toLowerCase());
        const editUrl = edit_repository_repository_column_path(this.repositoryId, column.id)
        const destroyUrl = repository_columns_destroy_html_path(this.repositoryId, column.id)
        const e2eName = name.toLowerCase().replace(' ', '_');

        let listItem = `<li class="col-list-el editable has-permissions" data-position="${index}" data-id="${column.id}">
          <div class="text truncate" title="${name}"  data-e2e="e2e-TX-invItems-manageColumnsModal-${e2eName}-columnName">
            ${name}
          </div>
          <span class="column-type pull-right shrink-0">${
            typeName
          }</span>
          <span class="sci-btn-group manage-controls pull-right" data-view-mode="active">
            <button class="btn icon-btn btn-light btn-xs edit-repo-column manage-repo-column"
                    data-action="edit"
                    data-modal-url="${editUrl}">
              <span class="sn-icon sn-icon-edit" title="Edit"  data-e2e="e2e-BT-invItems-manageColumnsModal-${e2eName}-edit"></span>
            </button>
            <button class="btn icon-btn btn-light btn-xs delete-repo-column manage-repo-column"
                    data-action="destroy"
                    data-modal-url="${destroyUrl}">
                    <span class="sn-icon sn-icon-delete" title="Delete" data-e2e="e2e-BT-invItems-manageColumnsModal-${e2eName}-delete"></span>
            </button>
          </span>
          <br>
        </li>`;

        columnsHTML.push(listItem)
      });
      return columnsHTML
    },
    applyFilters(filters) {
      this.activeFilter = filters.data
      this.reloadingTable = true
    }
  }
};
</script>
