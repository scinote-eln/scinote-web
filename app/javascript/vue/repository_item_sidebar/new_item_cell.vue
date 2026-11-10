<template>
  <div class="max-h-11">
    <cell-renderer v-if="editable" :params="params" />
    <Teleport to="body">
      <TextCellModal
        v-if="textModalOpen"
        :row="params.data"
        :colDef="params.colDef"
        @updateCell="saveText"
        @close="textModalOpen = false"/>
      <StockValueModal
        v-if="stockModalOpen"
        :stockData="stockData"
        @saveDraft="update"
        @close="stockModalOpen = false"/>
    </Teleport>
  </div>
</template>

<script>
import CellRenderer from '../repository/renderers/cell_renderer.vue';
import TextCellModal from '../repository/modals/text_cell.vue';
import StockValueModal from '../repository/modals/stock_value_modal.vue';

export default {
  name: 'NewItemCell',
  components: {
    CellRenderer,
    TextCellModal,
    StockValueModal
  },
  props: {
    column: { type: Object, required: true },
    repositoryId: { type: [Number, String], required: true },
    itemName: { type: String, default: '' },
    canManageStock: { type: Boolean, default: false }
  },
  emits: ['change'],
  data() {
    return {
      value: null,
      textModalOpen: false,
      stockModalOpen: false
    };
  },
  computed: {
    dataType() {
      return this.column.data_type;
    },
    editable() {
      if (this.dataType === 'RepositoryStockValue') return this.canManageStock;

      return this.dataType in CellRenderer.components;
    },
    cellValue() {
      if (!this.value) return null;

      switch (this.dataType) {
        case 'RepositoryTextValue':
          return { value: { edit: this.value } };
        case 'RepositoryAssetValue':
          return { value: { file_name: this.value.name } };
        default:
          return null;
      }
    },
    stock() {
      if (!this.value) return { value: {} };

      const unit = this.column.column_items.find((item) => item.id === this.value.unit_item_id);
      const amount = this.value.amount.toFixed(this.column.metadata.decimals);

      return { value: { stock_formatted: `${amount} ${unit.label}` } };
    },
    stockData() {
      const stock = this.value || {};

      return {
        repository_row_name: this.itemName,
        stock_value: {
          decimals: this.column.metadata.decimals,
          units: this.column.column_items.map((unit) => [unit.id, unit.label]),
          amount: stock.amount?.toString(),
          unit: stock.unit_item_id,
          reminder_enabled: !!stock.low_stock_threshold,
          low_stock_treshold: stock.low_stock_threshold,
          comment: stock.comment
        }
      };
    },
    params() {
      const field = `col_${this.column.id}`;
      const data = { id: null, permissions: { manage: true }, [field]: this.cellValue };
      if (this.dataType === 'RepositoryStockValue') data.stock = this.stock;

      return {
        value: this.cellValue,
        data,
        colDef: {
          field,
          headerName: this.column.name,
          cellRendererParams: {
            repositoryId: this.repositoryId,
            columnId: this.column.id,
            columnDataType: this.dataType,
            columnItems: this.column.column_items,
            metadata: this.column.metadata
          }
        },
        repositoryId: this.repositoryId,
        columnId: this.column.id,
        columnDataType: this.dataType,
        columnItems: this.column.column_items,
        metadata: this.column.metadata,
        dtComponent: { $emit: this.handleRendererEvent }
      };
    }
  },
  methods: {
    handleRendererEvent(eventName, ...args) {
      switch (eventName) {
        case 'updateCell':
        case 'uploadFile':
          this.update(args[2]);
          break;
        case 'showTextCell':
          this.textModalOpen = true;
          break;
        case 'openStockModal':
          this.stockModalOpen = true;
          break;
        default:
          break;
      }
    },
    saveText(_row, _colDef, text) {
      this.update(text);
    },
    update(value) {
      this.value = value;
      this.textModalOpen = false;
      this.stockModalOpen = false;

      // The number editor lets partial input such as '-' through, which the server cannot parse.
      const unparsable = this.dataType === 'RepositoryNumberValue' && Number.isNaN(Number(value));
      this.$emit('change', unparsable ? null : value);
    }
  }
};
</script>
