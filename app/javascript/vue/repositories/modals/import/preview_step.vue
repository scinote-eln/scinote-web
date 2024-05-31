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
              <h2 class="m-0 text-sn-alert-green">0</h2>
            </div>
            <div>
              <div v-html="i18n.t('repositories.import_records.steps.step3.new_items')"></div>
              <hr class="my-1">
              <h2 class="m-0 text-sn-alert-green">0</h2>
            </div>
            <div>
              <div v-html="i18n.t('repositories.import_records.steps.step3.unchanged_items')"></div>
              <hr class="my-1">
              <h2 class="m-0 ">0</h2>
            </div>
            <div>
              <div v-html="i18n.t('repositories.import_records.steps.step3.duplicated_items')"></div>
              <hr class="my-1">
              <h2 class="m-0 ">0</h2>
            </div>
            <div>
              <div v-html="i18n.t('repositories.import_records.steps.step3.invalid_items')"></div>
              <hr class="my-1">
              <h2 class="m-0 text-sn-alert-passion">0</h2>
            </div>
            <div>
              <div v-html="i18n.t('repositories.import_records.steps.step3.invalid_items')"></div>
              <hr class="my-1">
              <h2 class="m-0 text-sn-alert-passion">0</h2>
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
            {{ i18n.t('repositories.import_records.steps.step3.cancel') }}
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
        field: 'status',
        headerName: this.i18n.t('repositories.import_records.steps.step3.status'),
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
  }
};
</script>
