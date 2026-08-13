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
      :filters="[]"
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
      @createRow="createRow"
      @changeName="changeName"
      @tableReloaded="onTableReloaded"
      @startCreate="addingNewRow = true"
      @importItems="importItems"
      @clearAllReminders="clearAllReminders"
    ></DataTable>
    <teleport to="body">
      <ImportRepositoryModal ref="importModal" :repository-url="repositoryUrl" @import-success="reloadingTable = true" />
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

import {
  repository_table_index_ag_path,
  repository_path,
  repository_repository_rows_path,
  repository_repository_row_path,
  repository_repository_row_repository_cell_path,
  rails_direct_uploads_path,
  team_repository_hide_reminders_path
} from '../../routes.js';

export default {
  name: 'RepositoryTable',
  props: {
    repositoryId: Number,
    createUrl: String,
    activePageUrl: String,
    archivedPageUrl: String,
    currentViewMode: { type: String, default: 'active' }
  },
  components: {
    DataTable,
    TextCellModal,
    StockValueModal,
    ImportRepositoryModal
  },
  mixins: [ColumnsMixin],
  data: () => ({
    repositoryVersion: null,
    addingNewRow: false,
    reloadingTable: false,
    textCellModalObject: null,
    stockValueModalUrl: null,
    hasActiveReminders: false,
    currentPageRows: [],
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
      return '';
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
    }
  }
};
</script>
