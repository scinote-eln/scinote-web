<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
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
          <div class="flex items-center justify-between text-sn-dark-gray text-sm">
            <div>
              <div v-html="i18n.t('repositories.import_records.steps.step3.updated_items')"></div>
              <hr class="my-1">
              <h2 class="m-0 text-sn-alert-green">{{ counters.updated }}</h2>
            </div>
            <div>
              <div v-html="i18n.t('repositories.import_records.steps.step3.new_items')"></div>
              <hr class="my-1">
              <h2 class="m-0 text-sn-alert-green">{{ counters.created }}</h2>
            </div>
            <div>
              <div v-html="i18n.t('repositories.import_records.steps.step3.unchanged_items')"></div>
              <hr class="my-1">
              <h2 class="m-0 ">{{ counters.unchanged }}</h2>
            </div>
            <div>
              <div v-html="i18n.t('repositories.import_records.steps.step3.duplicated_items')"></div>
              <hr class="my-1">
              <h2 class="m-0 text-sn-alert-passion">{{ counters.duplicated }}</h2>
            </div>
            <div>
              <div v-html="i18n.t('repositories.import_records.steps.step3.invalid_items')"></div>
              <hr class="my-1">
              <h2 class="m-0 text-sn-alert-passion">{{ counters.invalid }}</h2>
            </div>
            <div>
              <div v-html="i18n.t('repositories.import_records.steps.step3.archived_items')"></div>
              <hr class="my-1">
              <h2 class="m-0">{{ counters.archived }}</h2>
            </div>
          </div>
          <div class="my-6">
            {{ i18n.t('repositories.import_records.steps.step2.importedFileText') }} {{ params.file_name }}
          </div>
          <div class="h-80">
            <ag-grid-vue
              class="ag-theme-alpine w-full flex-grow h-full z-10"
              :columnDefs="columnDefs"
              :defaultColDef="{
                resizable: true,
                sortable: false,
                suppressMovable: true
              }"
              :rowData="tableData"
              :suppressRowTransform="true"
              :suppressRowClickSelection="true"
              :enableCellTextSelection="true"
            ></ag-grid-vue>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" @click="$emit('changeStep', 'MappingStep')">
            {{ i18n.t('general.back') }}
          </button>
          <button type="button" class="btn btn-primary" @click="$emit('importRows')">
            {{ i18n.t('repositories.import_records.steps.step3.confirm') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { AgGridVue } from 'ag-grid-vue3';
import modalMixin from '../../../shared/modal_mixin';


export default {
  name: 'PreviewStep',
  mixins: [modalMixin],
  props: {
    params: {
      type: Object,
      required: true
    }
  },
  components: {
    AgGridVue
  },
  data() {
    return {
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
    columnDefs() {
      const columns = [
        {
          field: 'code',
          headerName: this.i18n.t('repositories.import_records.steps.step3.code')
        },
        {
          field: 'name',
          headerName: this.i18n.t('repositories.import_records.steps.step3.name')
        }
      ];

      this.params.attributes.repository_columns.forEach((col) => {
        columns.push({
          field: `col_${col[0]}`,
          headerName: col[1]
        });
      });

      columns.push({
        field: 'import_status',
        headerName: this.i18n.t('repositories.import_records.steps.step3.status'),
        cellRenderer: this.statusRenderer,
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
    filterRows(status) {
      return this.params.preview.data.filter((r) => r.attributes.import_status === status);
    },
    statusRenderer(params) {
      const { import_status: importStatus, import_message: importMessage } = params.data;

      let message = '';
      let color = '';
      let icon = '';

      if (importStatus === 'created' || importStatus === 'updated') {
        message = this.i18n.t(`repositories.import_records.steps.step3.status_message.${importStatus}`);
        color = 'text-sn-alert-green';
        icon = 'check';
      } else if (importStatus === 'unchanged' || importStatus === 'archived') {
        message = this.i18n.t(`repositories.import_records.steps.step3.status_message.${importStatus}`);
        icon = 'hamburger';
      } else if (importStatus === 'duplicated' || importStatus === 'invalid') {
        message = this.i18n.t(`repositories.import_records.steps.step3.status_message.${importStatus}`);
        color = 'text-sn-alert-passion';
        icon = 'close';
      }

      if (importMessage) {
        message = importMessage;
      }

      return `
        <div class="flex items-center ${color} gap-2.5">
          <i class="sn-icon sn-icon-${icon} "></i>
          <span>${message}</span>
        </div>
      `;
    }
  }
};
</script>
