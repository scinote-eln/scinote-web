<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog !w-[90vw]" role="document">
      <Loading v-if="loading" />
      <div class="modal-content grow">
        <div class="modal-header gap-4">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-newInventoryModal-close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="edit-project-modal-label" data-e2e="e2e-TX-newInventoryModal-title">
            {{ i18n.t('repositories.import_records.steps.step3.title') }}
          </h4>
        </div>
        <div class="modal-body">

          <p class="text-sn-dark-grey mb-6">
            {{ i18n.t('repositories.import_records.steps.step3.subtitle', { inventory: params.attributes.name }) }}
          </p>
          <div class="flex items-center justify-between gap-4 mb-4">
            <div class="flex items-center gap-1 p-1 rounded-lg bg-sn-grey-100">
              <button
                v-for="tab in tabs"
                :key="tab.status"
                type="button"
                class="px-4 py-1.5 rounded-md border-0 text-sm whitespace-nowrap"
                :class="{
                  'bg-sn-white shadow font-bold text-sn-black': activeTab === tab.status,
                  'bg-transparent text-sn-dark-grey': activeTab !== tab.status,
                  'cursor-not-allowed': tab.count === 0,
                  'cursor-pointer': tab.count > 0
                }"
                :data-e2e="`e2e-BT-importPreview-tab-${tab.status}`"
                @click="selectTab(tab)"
              >
                {{ tab.label }}
                (<span :class="tab.count > 0 ? tab.countClass : ''">{{ tab.count }}</span>)
              </button>
            </div>
            <div class="truncate" :title="params.file_name">
              {{ i18n.t('repositories.import_records.steps.step2.importedFileText') }} {{ params.file_name }}
            </div>
          </div>
          <div style="height: 540px">
            <ag-grid-vue
              class="ag-theme-alpine w-full flex-grow h-full z-10"
              :columnDefs="columnDefs"
              :defaultColDef="{
                resizable: true,
                sortable: false,
                suppressMovable: true
              }"
              :rowData="filteredTableData"
              :suppressRowTransform="true"
              :suppressRowClickSelection="true"
              :enableCellTextSelection="true"
            ></ag-grid-vue>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" @click="$emit('changeStep', 'MappingStep')">
            {{ i18n.t('general.cancel') }}
          </button>
          <span :data-sn-tooltip="hasMandatoryErrors ? i18n.t('repositories.import_records.steps.step3.mandatory_columns_error') : null">
            <button type="button" class="btn btn-primary" :disabled="hasMandatoryErrors" @click="$emit('importRows')">
              {{ i18n.t('repositories.import_records.steps.step3.import') }}
            </button>
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { AgGridVue } from 'ag-grid-vue3';
import modalMixin from '../../../shared/modal_mixin';
import Loading from '../../../shared/loading.vue';
import HighlightRenderer from './renderers/highlight_renderer.vue';
import StatusRenderer from './renderers/status_renderer.vue';
import tooltipMixin from '../../../mixins/tooltipMixin.js';
import CustomHeader from '../../../shared/datatable/tableHeader';

export default {
  name: 'PreviewStep',
  mixins: [modalMixin, tooltipMixin],
  props: {
    params: {
      type: Object,
      required: true
    },
    loading: {
      type: Boolean,
      required: true
    }
  },
  components: {
    AgGridVue,
    Loading,
    agColumnHeader: CustomHeader
  },
  data() {
    return {
      activeTab: 'all'
    };
  },
  computed: {
    counters() {
      return {
        updated: this.filterRows('updated').length,
        created: this.filterRows('created').length,
        unchanged: this.filterRows('unchanged').length,
        duplicated: this.filterRows('duplicated').length,
        invalid: this.filterRows('invalid').length,
        archived: this.filterRows('archived').length
      };
    },
    tabs() {
      const t = (key) => this.i18n.t(`repositories.import_records.steps.step3.${key}`);
      const green = 'text-sn-alert-green';
      const red = 'text-sn-alert-passion';

      return [
        { status: 'all', label: t('all_items'), count: this.params.preview.data.length },
        { status: 'updated', label: t('updated_items'), count: this.counters.updated, countClass: green },
        { status: 'created', label: t('new_items'), count: this.counters.created, countClass: green },
        { status: 'unchanged', label: t('unchanged_items'), count: this.counters.unchanged },
        { status: 'duplicated', label: t('duplicated_items'), count: this.counters.duplicated, countClass: red },
        { status: 'invalid', label: t('invalid_items'), count: this.counters.invalid, countClass: red },
        { status: 'archived', label: t('archived_items'), count: this.counters.archived }
      ];
    },
    hasMandatoryErrors() {
      return this.params.preview.data.some((row) => row.attributes.import_mandatory_missing?.length > 0);
    },
    filteredTableData() {
      if (this.activeTab === 'all') return this.tableData;

      return this.tableData.filter((row) => row.import_status === this.activeTab);
    },
    columnDefs() {
      const columns = [
        {
          field: 'code',
          headerName: this.i18n.t('repositories.import_records.steps.step3.code'),
          cellRenderer: HighlightRenderer,
          cellRendererParams: { columnKey: 'code' }
        },
        {
          field: 'name',
          headerName: this.i18n.t('repositories.import_records.steps.step3.name'),
          cellRenderer: HighlightRenderer,
          cellRendererParams: { columnKey: 'name' }
        }
      ];

      this.params.attributes.repository_columns.forEach((col) => {
        columns.push({
          field: `col_${col[0]}`,
          headerName: col[1],
          cellRenderer: HighlightRenderer,
          cellRendererParams: { columnKey: String(col[0]) },
          headerComponentParams: { isMandatory: () => !!col[3] }
        });
      });

      columns.push({
        field: 'import_status',
        headerName: this.i18n.t('repositories.import_records.steps.step3.status'),
        cellRenderer: StatusRenderer,
        pinned: 'right'
      });

      return columns;
    },
    tableData() {
      const data = this.params.preview.data.map((row) => {
        const rowFormated = row.attributes;
        row.relationships.repository_cells.data.forEach((c) => {
          const cell = this.params.preview.included.find((c1) => c1.id === c.id);
          if (cell) {
            rowFormated[`col_${cell.attributes.repository_column_id}`] = cell.attributes.formatted_value;
          }
        });
        return rowFormated;
      });
      return data;
    }
  },
  methods: {
    selectTab(tab) {
      if (tab.count === 0) return;

      this.activeTab = tab.status;
    },
    filterRows(status) {
      return this.params.preview.data.filter((r) => r.attributes.import_status === status);
    }
  }
};
</script>
