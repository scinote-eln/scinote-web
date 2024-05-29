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
            <div class="flex items-center gap-1">
              <div class="sci-checkbox-container">
                <input type="checkbox" class="sci-checkbox"  v-model="autoMapping" />
                <span class="sci-checkbox-label"></span>
              </div>
              {{ i18n.t('repositories.import_records.steps.step2.autoMappingText') }}
            </div>
            <div class="flex items-center gap-1">
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
          </div>

          {{ i18n.t('repositories.import_records.steps.step2.importedFileText') }} {{ params.file_name }}
          <hr class="m-0 mt-6">
          <div class="grid grid-cols-[3rem_auto_1.5rem_auto_5rem_auto] px-2">

            <div v-for="(column, key) in columnLabels" class="flex items-center px-2 py-2">{{ column }}</div>

            <template v-for="(item, index) in params.import_data.header" :key="item">
              <MappingStepTableRow
                :index="index"
                :item="item"
                :dropdownOptions="computedDropdownOptions"
                :params="params"
                :selected="this.selectedItemsIndexes.includes(index)"
                @selection:changed="handleChange"
                :availableFields="this.availableFields"
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
          <button class="btn btn-primary" :disabled="!rowsIsValid" @click="importRecords">
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
  emits: ['step:next'],
  mixins: [modalMixin],
  components: {
    SelectDropdown,
    MappingStepTableRow
  },
  props: {
    params: {
      type: Object,
      required: true
    },
  },
  data() {
    return {
      autoMapping: true,
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
      selectedItemsIndexes: [],
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
    toggleUpdateWithEmptyCells() {
      this.updateWithEmptyCells = !this.updateWithEmptyCells;
    },
    toggleOnlyAddNewItems() {
      this.onlyAddNewItems = !this.onlyAddNewItems;
    },
    handleChange(payload) {
      this.error = null;
      const { index, key, value } = payload;

      // checking if the mapping is already selected
      const foundItem = this.selectedItems.find((item) => item.index === index);

      // if it's not, add it
      if (!foundItem && key) {
        this.selectedItems = [...this.selectedItems, { index, key, value }];
        this.selectedItemsIndexes.push(index);
      }
      // if it is but the key is null then clear it
      if (foundItem && !key) {
        const indexToRemoveObj = this.selectedItems.findIndex((item) => item.index === index);
        const indexToRemoveStr = this.selectedItemsIndexes.indexOf(index);
        if ((indexToRemoveObj !== -1) && (indexToRemoveStr !== -1)) {
          this.selectedItems.splice(indexToRemoveObj, 1);
          this.selectedItemsIndexes.splice(indexToRemoveStr, 1);
        }
      }
      // if it is and the key is not null then update it
      if (foundItem && key) {
        const indexToRemoveObj = this.selectedItems.findIndex((item) => item.index === index);
        this.selectedItems.splice(indexToRemoveObj, 1);
        this.selectedItems = [...this.selectedItems, { index, key, value }];
      }

      this.updateAvailableItemsStatus();
    },
    // necessary for tracking which options are already selected
    updateAvailableItemsStatus() {
      let updatedAvailableFields = [];
      const selectedItemsKeys = new Set(this.selectedItems.map((item) => item.key));

      this.alwaysAvailableFields.forEach((field) => {
        if (selectedItemsKeys.has(field.key)) {
          const tempObj = { key: field.key, value: field.value, alreadySelected: true };
          updatedAvailableFields.push(tempObj);
        } else {
          updatedAvailableFields.push(field);
        }
      });

      this.availableFields = updatedAvailableFields;
      updatedAvailableFields = [];
    },
    generateMapping() {
      const mapping = {};
      for (let i = 0; i < this.params.import_data.header.length; i++) {
        const foundItem = this.selectedItems.find((item) => item.index === i);
        if (foundItem) {
          mapping[foundItem.index] = (foundItem.key === 'new' ? foundItem.value : foundItem.key);
        } else {
          mapping[i] = '';
        }
      }
      return mapping;
    },
    importRecords() {
      const selectedItemsKeys = new Set(this.selectedItems.map((item) => item.key));
      if (!selectedItemsKeys.has('-1')) {
        this.error = this.i18n.t('repositories.import_records.steps.step2.selectNamePropertyError');
        return '';
      }

      this.$emit(
        'generatePreview',
        this.generateMapping(),
        this.updateWithEmptyCells,
        this.onlyAddNewItems
      );
    }
  },
  computed: {
    computedDropdownOptions() {
      const columnKeyToLabelMapping = {};
      columnKeyToLabelMapping[-1] = this.i18n.t('repositories.import_records.steps.step2.computedDropdownOptions.name');

      if (this.repositoryColumns) {
        this.repositoryColumns.forEach((el) => {
          const [key, colName, colType] = el;
          columnKeyToLabelMapping[key] = this.i18n.t(`repositories.import_records.steps.step2.computedDropdownOptions.${colType}`);
        });
      }

      if (this.availableFields) {
        let options = this.availableFields.map((el) => [String(el.key), `${String(el.value)} (${columnKeyToLabelMapping[el.key]})`]);
        options = [['new', this.i18n.t('repositories.import_records.steps.step2.table.tableRow.importAsNewColumn')]].concat(options);
        return options;
      }
      return [];
    },
    computedImportedIgnoredInfo() {
      const importedSum = this.selectedItems.length;
      const ignoredSum = this.params.import_data.header.length - importedSum;
      return { importedSum, ignoredSum };
    },
    rowsIsValid() {
      let valid = true;
      this.selectedItems.forEach((v) => {
        if (v.key === 'new' && (!v.value.type || v.value.name.length < 2)) {
          valid = false;
        }
      });
      return valid;
    }
  },
  created() {
    this.repositoryColumns = this.params.attributes.repository_columns;

    // Adding alreadySelected attribute for tracking
    const tempAvailableFields = [];
    Object.entries(this.params.import_data.available_fields).forEach(([key, value]) => {
      const field = { key, value, alreadySelected: false };
      tempAvailableFields.push(field);
    });
    this.availableFields = tempAvailableFields;
    this.alwaysAvailableFields = tempAvailableFields;
  }
};
</script>
