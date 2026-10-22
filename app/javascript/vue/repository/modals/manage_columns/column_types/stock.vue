<template>
  <div class="flex flex-col gap-4">
    <InputField
      :label="i18n.t('libraries.manange_modal_column.number_type.decimals_label')"
      v-model="decimals"
      isNumber
    />
    <ItemsEditor
      ref="itemsEditor"
      v-model="items"
      :limit="limit"
      :label="i18n.t('libraries.manange_modal_column.stock_type.stock_units')"
      :placeholder="placeholder"
      :delimiter="'\n'"
      :isEditing="!!column"
      :showPreview="false"
      :changeWarning="i18n.t('libraries.manange_modal_column.stock_type.units_changing_warning')"
      :description="i18n.t('libraries.manange_modal_column.stock_type.units_description')"
    />
  </div>
</template>

<script>
/* global GLOBAL_CONSTANTS */
import axios from '../../../../../packs/custom_axios.js';
import { items_repository_repository_columns_stock_column_path } from '../../../../../routes.js';
import ItemsEditor from './items_editor.vue';
import InputField from '../../../../shared/input_field.vue';

export default {
  name: 'StockColumnType',
  components: { ItemsEditor, InputField },
  props: {
    column: { type: Object, default: null },
    repositoryId: { type: [String, Number], required: true }
  },
  data() {
    return {
      maxDecimals: GLOBAL_CONSTANTS.REPOSITORY_NUMBER_TYPE_MAX_DECIMALS,
      decimals: String(this.column?.cellRendererParams?.metadata?.decimals ?? 0),
      limit: GLOBAL_CONSTANTS.REPOSITORY_STOCK_UNIT_ITEMS_PER_COLUMN,
      items: this.column ? [] : GLOBAL_CONSTANTS.REPOSITORY_STOCK_DEFAULT_UNITS
    };
  },
  computed: {
    placeholder() {
      return this.i18n.t('libraries.manange_modal_column.stock_type.textarea_placeholder_html')
        .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(code));
    }
  },
  created() {
    if (this.column) {
      axios.get(items_repository_repository_columns_stock_column_path(this.repositoryId, this.column.cellRendererParams.columnId), {
        params: { query: '' }
      }).then((response) => {
        this.items = response.data.map((item) => item.label);
      });
    }
  },
  methods: {
    valid() {
      const decimals = parseInt(this.decimals, 10);
      return !Number.isNaN(decimals) && decimals >= 0 && decimals <= this.maxDecimals && this.$refs.itemsEditor.valid();
    },
    payload() {
      return {
        metadata: { decimals: parseInt(this.decimals, 10) },
        repository_stock_unit_items_attributes: this.items.map((data) => ({ data }))
      };
    }
  }
};
</script>
