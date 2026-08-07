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
      @cancelCreation="cancelCreation"
      @showTextCell="showTextCellModal"
      @updateCell="updateCell"
      @updateRemindersCount="updateRemindersCount"
      @createRow="createRow"
      @changeName="changeName"
      @tableReloaded="reloadingTable = false"
      @startCreate="addingNewRow = true"
    ></DataTable>
    <teleport to="body">
      <TextCellModal
        <TextCellModal
          v-if="textCellModalObject"
          :row="textCellModalObject.row"
          :colDef="textCellModalObject.colDef"
          @updateCell="updateCell"
          @close="textCellModalObject = null"/>
      </teleport>
  </div>
</template>
<script>
import DataTable from '../shared/datatable/table.vue';
import axios from '../../packs/custom_axios.js';
import ColumnsMixin from './columns_mixin.js';
import TextCellModal from './modals/text_cell.vue';

import {
  repository_table_index_ag_path,
  repository_path,
  repository_repository_rows_path,
  repository_repository_row_path,
  repository_repository_row_repository_cell_path
} from '../../routes.js';

export default {
  name: 'RepositoryTable',
  props: {
    repositoryId: Number,
    createUrl: String,
  },
  components: {
    DataTable,
    TextCellModal
  },
  mixins: [ColumnsMixin],
  data: () => ({
    repositoryVersion: null,
    addingNewRow: false,
    reloadingTable: false,
    textCellModalObject: null,
    newRowTemplate: {
      name: {
        value: '',
        isValid: false
      },
    },
  }),
  created() {
    this.loadRepository();
  },
  computed: {
    toolbarActions() {
      const left = [];
      const right = [];

      if (this.createUrl) {
        left.push({
          name: 'startCreate',
          icon: 'sn-icon sn-icon-new-task',
          label: this.i18n.t('repositories.add_new_record'),
          type: 'emit',
          path: this.createUrl,
          buttonStyle: 'btn btn-primary'
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
    loadRepository() {
      axios.get(this.repositoryUrl)
        .then((response) => {
          this.repositoryVersion = response.data.data;
          this.loadRepositoryColumns();
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
