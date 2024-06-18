<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-newInventoryModal-close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate" id="edit-project-modal-label" data-e2e="e2e-TX-newInventoryModal-title">
            {{ i18n.t('repositories.import_records.steps.step2.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <p class="text-sn-dark-grey">
            {{ this.i18n.t('repositories.import_records.steps.step2.subtitle') }}
          </p>
          <div class="flex gap-6 items-center my-6">
            <div class="flex items-center gap-2" :title="i18n.t('repositories.import_records.steps.step2.autoMappingTooltip')">
              <div class="sci-checkbox-container">
                <input type="checkbox" class="sci-checkbox"  v-model="autoMapping" />
                <span class="sci-checkbox-label"></span>
              </div>
              {{ i18n.t('repositories.import_records.steps.step2.autoMappingText') }}
            </div>
          <!--
            <div  class="flex items-center gap-1">
              <div class="sci-checkbox-container my-auto">
                <input type="checkbox" class="sci-checkbox" :checked="updateWithEmptyCells" @change="toggleUpdateWithEmptyCells"/>
                <span class="sci-checkbox-label"></span>
              </div>
              {{ i18n.t('repositories.import_records.steps.step2.updateEmptyCellsText') }}
            </div>
            <div class="flex items-center gap-1">
              <div class="sci-checkbox-container my-auto">
                <input type="checkbox" class="sci-checkbox" :checked="onlyAddNewItems"  @change="toggleOnlyAddNewItems" />
                <span class="sci-checkbox-label"></span>
              </div>
              {{ i18n.t('repositories.import_records.steps.step2.onlyAddNewItemsText') }}
            </div>
          -->
          </div>

          {{ i18n.t('repositories.import_records.steps.step2.importedFileText') }} {{ params.file_name }}
          <hr class="m-0 mt-6">
          <div class="grid grid-cols-[3rem_auto_1.5rem_auto_5rem_auto] px-2">

            <div v-for="(column, key) in columnLabels" class="flex items-center px-2 py-2 font-bold">{{ column }}</div>

            <template v-for="(item, index) in params.import_data.header" :key="item">
              <MappingStepTableRow
                :index="index"
                :item="item"
                :dropdownOptions="computedDropdownOptions"
                :params="params"
                :value="this.selectedItems.find((item) => item.index === index)"
                @selection:changed="handleChange"
                :autoMapping="this.autoMapping"
              />
            </template>
          </div>

          <!-- imported/ignored section -->
          <div class="flex gap-1 mt-6"
            v-html="i18n.t('repositories.import_records.steps.step2.importedIgnoredSection', {
              imported: computedImportedIgnoredInfo.importedSum,
              ignored: computedImportedIgnoredInfo.ignoredSum
            })"
          >
          </div>
        </div>

        <!-- footer -->
        <div class="modal-footer">
          <div id="error" class="flex flex-row gap-3 text-sn-delete-red">
            <i v-if="error" class="sn-icon sn-icon-alert-warning my-auto"></i>
            <div class="my-auto">{{ error ? error : '' }}</div>
          </div>
          <button class="btn btn-secondary ml-auto" @click="close" aria-label="Close">
            {{ i18n.t('repositories.import_records.steps.step2.cancelBtnText') }}
          </button>
          <button class="btn btn-primary" @click="importRecords">
            {{ i18n.t('repositories.import_records.steps.step2.confirmBtnText') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from '../../../../packs/custom_axios';
import SelectDropdown from '../../../shared/select_dropdown.vue';
import MappingStepTableRow from './mapping_step_table_row.vue';
import modalMixin from '../../../shared/modal_mixin';

export default {
  name: 'MappingStep',
  emits: ['close', 'generatePreview'],
  mixins: [modalMixin],
  components: {
    SelectDropdown,
    MappingStepTableRow
  },
  props: {
    params: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      autoMapping: false,
      updateWithEmptyCells: false,
      onlyAddNewItems: false,
      columnLabels: {
        0: this.i18n.t('repositories.import_records.steps.step2.table.columnLabels.number'),
        1: this.i18n.t('repositories.import_records.steps.step2.table.columnLabels.importedColumns'),
        2: '',
        3: this.i18n.t('repositories.import_records.steps.step2.table.columnLabels.scinoteColumns'),
        4: this.i18n.t('repositories.import_records.steps.step2.table.columnLabels.status'),
        5: this.i18n.t('repositories.import_records.steps.step2.table.columnLabels.exampleData')
      },
      selectedItems: [],
      importRecordsUrl: null,
      teamId: null,
      repositoryId: null,
      availableFields: [],
      alwaysAvailableFields: [],
      repositoryColumns: null,
      error: null
    };
  },
  methods: {
    handleChange(payload) {
      this.error = null;
      const { index, key, value } = payload;

      const item = this.selectedItems.find((i) => i.index === index);
      const usedBeforeItem = this.selectedItems.find((i) => i.key === key && i.index !== index);

      if (usedBeforeItem) {
        usedBeforeItem.key = null;
        usedBeforeItem.value = null;
      }

      item.key = key;
      item.value = value;
    },
    generateMapping() {
      return this.selectedItems.reduce((obj, item) => {
        obj[item.index] = item.key || '';
        return obj;
      }, {});
    },
    importRecords() {
      if (!this.selectedItems.find((item) => item.key === '-1')) {
        this.error = this.i18n.t('repositories.import_records.steps.step2.selectNamePropertyError');
        return '';
      }

      this.$emit(
        'generatePreview',
        this.generateMapping()
      );
      return true;
    }
  },
  computed: {
    computedDropdownOptions() {
      return this.availableFields
        .map((el) => [String(el.key), `${String(el.value)} (${el.typeName})`]);
      // options = [['new', this.i18n.t('repositories.import_records.steps.step2.table.tableRow.importAsNewColumn')]].concat(options);
    },
    computedImportedIgnoredInfo() {
      const importedSum = this.selectedItems.filter((i) => i.key).length;
      const ignoredSum = this.selectedItems.length - importedSum;
      return { importedSum, ignoredSum };
    }
  },
  created() {
    this.repositoryColumns = this.params.attributes.repository_columns;
    // Adding alreadySelected attribute for tracking
    this.availableFields = [];

    this.selectedItems = this.params.import_data.header.map((item, index) => { return { index, key: null, value: null }; });

    Object.entries(this.params.import_data.available_fields).forEach(([key, value]) => {
      let columnTypeName = '';
      if (key === '-1') {
        columnTypeName = this.i18n.t('repositories.import_records.steps.step2.computedDropdownOptions.name');
      } else if (key === '0') {
        columnTypeName = this.i18n.t('repositories.import_records.steps.step2.computedDropdownOptions.id');
      } else {
        const column = this.repositoryColumns.find((el) => el[0] === parseInt(key, 10));
        columnTypeName = this.i18n.t(`repositories.import_records.steps.step2.computedDropdownOptions.${column[2]}`);
      }
      const field = {
        key, value, alreadySelected: false, typeName: columnTypeName
      };
      this.availableFields.push(field);
    });
  },
  mounted() {
    this.autoMapping = true;
  }
};
</script>
