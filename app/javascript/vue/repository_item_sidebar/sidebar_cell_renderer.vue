<template>
  <div>
    <div class="max-h-11">
      <cell-renderer :params="params" />
    </div>
    <Teleport to="body">
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
    </Teleport>
  </div>
</template>

<script>
/* global ActiveStorage HelperModule */

import axios from '../../packs/custom_axios.js';
import CellRenderer from '../repository/renderers/cell_renderer.vue';
import TextCellModal from '../repository/modals/text_cell.vue';
import StockValueModal from '../repository/modals/stock_value_modal.vue';
import {
  repository_repository_row_repository_cell_path,
  rails_direct_uploads_path
} from '../../routes.js';

export default {
  name: 'SidebarCellRenderer',
  components: {
    CellRenderer,
    TextCellModal,
    StockValueModal
  },
  props: {
    row: { type: Object, required: true },
    columnDef: { type: Object, required: true },
    repositoryId: { type: [Number, String], required: true }
  },
  emits: ['updateCell', 'updateRow'],
  data() {
    return {
      textCellModalObject: null,
      stockValueModalUrl: null
    };
  },
  computed: {
    field() {
      return `col_${this.columnDef.id}`;
    },
    colDef() {
      return {
        field: this.field,
        headerName: this.columnDef.name,
        cellRendererParams: {
          repositoryId: this.repositoryId,
          columnId: this.columnDef.id,
          columnDataType: this.columnDef.data_type,
          columnItems: this.columnDef.column_items,
          metadata: this.columnDef.metadata
        }
      };
    },
    params() {
      return {
        value: this.row[this.field],
        data: this.row,
        colDef: this.colDef,
        repositoryId: this.repositoryId,
        columnId: this.columnDef.id,
        columnDataType: this.columnDef.data_type,
        columnItems: this.columnDef.column_items,
        metadata: this.columnDef.metadata,
        dtComponent: { $emit: this.handleRendererEvent }
      };
    }
  },
  methods: {
    handleRendererEvent(eventName, ...args) {
      switch (eventName) {
        case 'updateCell': {
          const [rowData, colDef, value] = args;
          this.updateCell(rowData, colDef, value);
          break;
        }
        case 'uploadFile': {
          const [rowData, colDef, file] = args;
          this.uploadFile(rowData, colDef, file);
          break;
        }
        case 'showTextCell': {
          const [, rows, colDef] = args;
          this.textCellModalObject = { row: rows[0], colDef };
          break;
        }
        case 'openStockModal': {
          const [rowData] = args;
          this.stockValueModalUrl = rowData.stock?.value?.stock_url;
          break;
        }
        default:
          break;
      }
    },
    updateCell(rowData, colDef, value) {
      const columnId = colDef.field.split('_')[1];

      axios.post(
        repository_repository_row_repository_cell_path({
          repository_id: this.repositoryId,
          repository_row_id: rowData.id,
          repository_column_id: columnId
        }),
        { value }
      ).then((response) => {
        this.textCellModalObject = null;
        this.$emit('updateCell', {
          field: colDef.field,
          result: response.data.cell,
          activeRemindersCount: response.data.active_reminders_count
        });
      }).catch(() => {
        this.textCellModalObject = null;
      });
    },
    uploadFile(rowData, colDef, file) {
      const upload = new ActiveStorage.DirectUpload(file, rails_direct_uploads_path());
      upload.create((error, blob) => {
        if (error) {
          HelperModule.flashAlertMsg(`Upload failed: ${error}`, 'danger');
        } else {
          this.updateCell(rowData, colDef, blob.signed_id);
        }
      });
    },
    updateStock(newRow) {
      this.stockValueModalUrl = null;
      this.$emit('updateRow', newRow);
    }
  }
};
</script>
