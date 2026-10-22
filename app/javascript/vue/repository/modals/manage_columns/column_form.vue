<template>
  <div>
    <div class="modal-header">
      <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-manageColumnsModal-close">
        <i class="sn-icon sn-icon-close"></i>
      </button>
      <h4 class="modal-title truncate !flex items-center gap-2">
        <span v-if="column">{{ i18n.t('libraries.manange_modal_column.edit.title', { name: column.headerName }) }}</span>
        <span v-else>{{ i18n.t('libraries.manange_modal_column.new.title') }}</span>
      </h4>
    </div>
    <div class="modal-body">
      <NameTypeFields
        v-model:name="name"
        v-model:dataType="dataType"
        :nameError="nameError"
        :disabledType="!!column"
        :options="typeOptions"
      />
      <hr v-if="typeComponent" />
      <component
        :is="typeComponent"
        v-if="typeComponent"
        ref="typeFields"
        :column="column"
        :repositoryId="repositoryId"
        :kind="typeKind"
      />
    </div>
    <div class="modal-footer">
      <button class="btn btn-secondary" @click="$emit('back')">
        {{ i18n.t('general.cancel') }}
      </button>
      <button class="btn btn-success" :disabled="saving" @click="save" data-e2e="e2e-BT-invItems-manageColumns-save">
        {{ column ? i18n.t('libraries.manange_modal_column.edit.button') : i18n.t('libraries.manange_modal_column.new.button') }}
      </button>
    </div>
  </div>
</template>

<script>
/* global HelperModule GLOBAL_CONSTANTS */
import axios from '../../../../packs/custom_axios.js';
import {
  repository_repository_columns_text_columns_path,
  repository_repository_columns_text_column_path,
  repository_repository_columns_number_columns_path,
  repository_repository_columns_number_column_path,
  repository_repository_columns_asset_columns_path,
  repository_repository_columns_asset_column_path,
  repository_repository_columns_list_columns_path,
  repository_repository_columns_list_column_path,
  repository_repository_columns_checklist_columns_path,
  repository_repository_columns_checklist_column_path,
  repository_repository_columns_status_columns_path,
  repository_repository_columns_status_column_path,
  repository_repository_columns_stock_columns_path,
  repository_repository_columns_stock_column_path,
  repository_repository_columns_date_time_columns_path,
  repository_repository_columns_date_time_column_path
} from '../../../../routes.js';
import NameTypeFields from './name_type_fields.vue';
import NumberColumnType from './column_types/number.vue';
import ListColumnType from './column_types/list.vue';
import ChecklistColumnType from './column_types/checklist.vue';
import StatusColumnType from './column_types/status.vue';
import StockColumnType from './column_types/stock.vue';
import DateTimeColumnType from './column_types/date_time.vue';
import { CREATABLE_TYPES, typeLabel } from './column_types.js';

const ROUTES = {
  RepositoryTextValue: { create: repository_repository_columns_text_columns_path, update: repository_repository_columns_text_column_path },
  RepositoryNumberValue: { create: repository_repository_columns_number_columns_path, update: repository_repository_columns_number_column_path },
  RepositoryAssetValue: { create: repository_repository_columns_asset_columns_path, update: repository_repository_columns_asset_column_path },
  RepositoryListValue: { create: repository_repository_columns_list_columns_path, update: repository_repository_columns_list_column_path },
  RepositoryChecklistValue: { create: repository_repository_columns_checklist_columns_path, update: repository_repository_columns_checklist_column_path },
  RepositoryStatusValue: { create: repository_repository_columns_status_columns_path, update: repository_repository_columns_status_column_path },
  RepositoryStockValue: { create: repository_repository_columns_stock_columns_path, update: repository_repository_columns_stock_column_path },
  RepositoryDateValue: { create: repository_repository_columns_date_time_columns_path, update: repository_repository_columns_date_time_column_path },
  RepositoryTimeValue: { create: repository_repository_columns_date_time_columns_path, update: repository_repository_columns_date_time_column_path },
  RepositoryDateTimeValue: { create: repository_repository_columns_date_time_columns_path, update: repository_repository_columns_date_time_column_path }
};

const TYPE_COMPONENTS = {
  RepositoryNumberValue: NumberColumnType,
  RepositoryListValue: ListColumnType,
  RepositoryChecklistValue: ChecklistColumnType,
  RepositoryStatusValue: StatusColumnType,
  RepositoryStockValue: StockColumnType,
  RepositoryDateValue: DateTimeColumnType,
  RepositoryTimeValue: DateTimeColumnType,
  RepositoryDateTimeValue: DateTimeColumnType
};

const TYPE_KINDS = {
  RepositoryDateValue: 'date',
  RepositoryTimeValue: 'time',
  RepositoryDateTimeValue: 'datetime'
};

export default {
  name: 'ColumnForm',
  components: { NameTypeFields },
  props: {
    column: { type: Object, default: null },
    repositoryId: { type: [String, Number], required: true },
    columnDefs: { type: Array, required: true }
  },
  data() {
    return {
      name: this.column?.headerName || '',
      dataType: this.column ? this.column.cellRendererParams.columnDataType.replace('RangeValue', 'Value') : 'RepositoryTextValue',
      nameError: null,
      saving: false
    };
  },
  computed: {
    typeComponent() {
      return TYPE_COMPONENTS[this.dataType] || null;
    },
    typeKind() {
      return TYPE_KINDS[this.dataType];
    },
    hasStockColumn() {
      return this.columnDefs.some((col) => col.field === 'stock');
    },
    stockDisabled() {
      if (this.dataType === 'RepositoryStockValue') return false;

      return !GLOBAL_CONSTANTS.STOCK_MANAGEMENT_ENABLED || this.hasStockColumn;
    },
    typeOptions() {
      return CREATABLE_TYPES.map((type) => {
        const meta = {};
        if (type === 'RepositoryStockValue' && this.stockDisabled) {
          meta.disabled = true;
          if (this.hasStockColumn) {
            meta.hint = this.i18n.t('libraries.manange_modal_column.stock_type.one_per_inventory');
          }
        }
        return [type, typeLabel(this.i18n, type), meta];
      });
    }
  },
  methods: {
    save() {
      this.nameError = null;

      if (!this.name.trim()) {
        this.nameError = this.i18n.t('libraries.manange_modal_column.empty_name_error');
        return;
      }

      if (this.$refs.typeFields && !this.$refs.typeFields.valid()) return;

      this.saving = true;
      const extra = this.$refs.typeFields?.payload() || {};
      let columnType = this.dataType;
      if (Object.prototype.hasOwnProperty.call(extra, 'range')) {
        if (extra.range) columnType = this.dataType.replace('Value', 'RangeValue');
        delete extra.range;
      }

      const body = { repository_column: { name: this.name, ...extra } };
      const routes = ROUTES[this.dataType];

      let request;
      if (this.column) {
        request = axios.patch(routes.update(this.repositoryId, this.column.cellRendererParams.columnId), body);
      } else {
        body.repository_column.column_type = columnType;
        request = axios.post(routes.create(this.repositoryId), body);
      }

      request.then((response) => {
        this.saving = false;
        this.$emit('saved', response.data.message);
      }).catch((error) => {
        this.saving = false;
        const errors = error.response?.data || {};
        const columnErrors = errors.repository_column || errors;
        if (columnErrors.name) {
          this.nameError = Array.isArray(columnErrors.name) ? columnErrors.name[0] : columnErrors.name;
          return;
        }
        const firstKey = Object.keys(columnErrors)[0];
        const firstValue = firstKey ? columnErrors[firstKey] : null;
        const message = Array.isArray(firstValue) ? firstValue[0] : firstValue;
        HelperModule.flashAlertMsg(message || this.i18n.t('general.error'), 'danger');
      });
    }
  }
};
</script>
