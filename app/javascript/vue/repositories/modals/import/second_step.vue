<template>
  <div ref="secondStep" class="flex flex-col gap-6 h-full">

    <!-- body -->
    <div class="flex flex-col gap-6 h-fit w-full">

      <!-- toggle section -->
      <div id="toggle-section" class="flex flex-row gap-6">
        <!-- auto-mapping -->
        <div id="auto-mapping-toggle" class="flex flex-row gap-1">
          <span class="sci-toggle-checkbox-container">
            <input type="checkbox"
              class="sci-toggle-checkbox"
              v-model="autoMapping"
              />
            <span class="sci-toggle-checkbox-label"></span>
          </span>
          <div class="flex my-auto w-32">
            {{ i18n.t('repositories.import_records.steps.step2.autoMappingText') }} {{ autoMapping ? 'ON' : 'OFF' }}
          </div>
        </div>
        <!-- update empty cells -->
        <div id="update-empty-cells" class="flex flex-row gap-1">
          <div class="sci-checkbox-container my-auto">
            <input
              type="checkbox"
              class="sci-checkbox"
              :checked="updateWithEmptyCells"
              @change="toggleUpdateWithEmptyCells"
            />
            <label class="sci-checkbox-label"></label>
          </div>
          <div class="flex my-auto">
            {{ i18n.t('repositories.import_records.steps.step2.updateEmptyCellsText') }}
          </div>
        </div>
        <!-- only add new items -->
        <div id="only-add-new-items" class="flex flex-row gap-1">
          <div class="sci-checkbox-container my-auto">
            <input
              type="checkbox"
              class="sci-checkbox"
              :checked="onlyAddNewItems"
              @change="toggleOnlyAddNewItems"
            />
            <label class="sci-checkbox-label"></label>
          </div>
          <div class="flex my-auto">
            {{ i18n.t('repositories.import_records.steps.step2.onlyAddNewItemsText') }}
          </div>
        </div>
      </div>

      <!-- imported file section -->
      <div class="flex flex-row text-sn-black">
        {{ i18n.t('repositories.import_records.steps.step2.importedFileText') }} {{ stepProps.fileName }}
      </div>

      <div id="table-section" class="flex flex-col w-full h-full gap-1">
        <!-- divider -->
        <div class="sci-divider"></div>

        <!-- table -->
        <div id="table" class="flex flex-col h-[28rem] w-full">
          <!-- labels -->
          <div id="column-labels" class="flex flex-row justify-between font-bold p-3">
            <div class="w-6">{{ i18n.t('repositories.import_records.steps.step2.table.columnLabels.number') }}</div>
            <div class="w-40">{{ i18n.t('repositories.import_records.steps.step2.table.columnLabels.importedColumns') }}</div>
            <div class="w-6"></div>
            <div class="w-60">{{ i18n.t('repositories.import_records.steps.step2.table.columnLabels.scinoteColumns') }}</div>
            <div class="w-14">{{ i18n.t('repositories.import_records.steps.step2.table.columnLabels.status') }}</div>
            <div class="w-56">{{ i18n.t('repositories.import_records.steps.step2.table.columnLabels.exampleData') }}</div>
          </div>

          <div id="table-rows" ref="tableRowsRef" class="w-full h-[28rem] flex flex-col py-4 overflow-auto gap-1">
            <!-- rows -->
            <div v-for="(item, index) in stepProps.columnNames" :key="item"
              class="flex flex-col gap-4 min-h-[56px] justify-center px-4 rounded shrink-0"
              :class="{'bg-sn-super-light-blue': this.selectedItemsIndexes.includes(index)}"
              >
              <SecondStepTableRow
                :key="item"
                :index="index"
                :item="item"
                :dropdownOptions="computedDropdownOptions"
                :stepProps="stepProps"
                @selection:changed="handleChange"
                :availableFields="this.availableFields"
                :autoMapping="this.autoMapping"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- divider -->
    <div class="sci-divider"></div>

    <!-- imported/ignored section -->
    <div class="flex flex-row">
      <b class="pr-1">{{ computedImportedIgnoredInfo.importedSum }}</b>
      <div class="pr-1">{{ i18n.t('repositories.import_records.steps.step2.importedIgnoredSection.columnsTo') }}</div>
      <b class="pr-1">{{ i18n.t('repositories.import_records.steps.step2.importedIgnoredSection.import') }}</b>
      <b class="pr-1">{{ computedImportedIgnoredInfo.ignoredSum }}</b>
      <div class="pr-1">{{ i18n.t('repositories.import_records.steps.step2.importedIgnoredSection.columns') }}</div>
      <b>{{ i18n.t('repositories.import_records.steps.step2.importedIgnoredSection.ignored') }}</b>
    </div>

    <!-- divider -->
    <div class="sci-divider"></div>

    <!-- footer -->
    <div class="flex justify-between">
      <div id="error" class="flex flex-row gap-3 text-sn-delete-red">
        <i v-if="error" class="sn-icon sn-icon-alert-warning my-auto"></i>
        <div class="my-auto">{{ error ? error : '' }}</div>
      </div>

      <div id="buttons" class="flex gap-4">
        <button class="btn btn-secondary" data-dismiss="modal" aria-label="Close">
          {{ i18n.t('repositories.import_records.steps.step2.cancelBtnText') }}
        </button>

        <button class="btn btn-primary" :disabled="!rowsIsValid" @click="importRecords">
          {{ i18n.t('repositories.import_records.steps.step2.confirmBtnText') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import axios from '../../../../packs/custom_axios';
import SelectDropdown from '../../../shared/select_dropdown.vue';
import SecondStepTableRow from './second_step_table_row.vue';

export default {
  name: 'SecondStep',
  emits: ['step:next'],
  components: {
    SelectDropdown,
    SecondStepTableRow
  },
  props: {
    stepProps: {
      type: Object,
      required: true
    },
    file: {
      type: File,
      required: false
    }
  },
  data() {
    return {
      autoMapping: true,
      updateWithEmptyCells: false,
      onlyAddNewItems: false,
      columnLabels: {
        0: this.i18n.t('repositories.import_records.steps.step2.table.columnLabels.number'),
        1: this.i18n.t('repositories.import_records.steps.step2.table.columnLabels.importedColumns'),
        2: this.i18n.t('repositories.import_records.steps.step2.table.columnLabels.scinoteColumns'),
        3: this.i18n.t('repositories.import_records.steps.step2.table.columnLabels.status'),
        4: this.i18n.t('repositories.import_records.steps.step2.table.columnLabels.exampleData')
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
      for (let i = 0; i < this.stepProps.columnNames.length; i++) {
        const foundItem = this.selectedItems.find((item) => item.index === i);
        if (foundItem) {
          mapping[foundItem.index] = (foundItem.key === 'new' ? foundItem.value : foundItem.key);
        } else {
          mapping[i] = '';
        }
      }
      return mapping;
    },
    async importRecords() {
      const selectedItemsKeys = new Set(this.selectedItems.map((item) => item.key));
      if (!selectedItemsKeys.has('-1')) {
        this.error = this.i18n.t('repositories.import_records.steps.step2.selectNamePropertyError');
        return '';
      }

      const mapping = this.generateMapping();

      const jsonData = {
        file_id: this.stepProps.tempFile.id,
        mappings: mapping,
        id: this.teamId,
        preview: true,
        should_overwrite_with_empty_cells: this.updateWithEmptyCells,
        can_edit_existing_items: !this.onlyAddNewItems
      };

      try {
        const response = await axios.post(this.importRecordsUrl, jsonData);
        if (!response.status === 200) {
          throw new Error('Network response was not ok');
        }
        return response;
      } catch (error) {
        console.error(error);
      }
      return '';
    },
    async fetchSerializedRepositoryData() {
      const url = window.location.pathname;
      try {
        const response = await axios.get(url);
        return response.data;
      } catch (error) {
        console.error(error);
      }
      return '';
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
      const ignoredSum = this.stepProps.columnNames.length - importedSum;
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
  async created() {
    // Fetch repository data and set it to state
    const repositoryData = await this.fetchSerializedRepositoryData();
    this.teamId = String(repositoryData.data.attributes.team_id);
    this.repositoryId = String(repositoryData.data.id);
    this.importRecordsUrl = repositoryData.data.attributes.urls.import_records;
    this.repositoryColumns = repositoryData.data.attributes.repository_columns;

    // Adding alreadySelected attribute for tracking
    const tempAvailableFields = [];
    Object.entries(this.stepProps.availableFields).forEach(([key, value]) => {
      const field = { key, value, alreadySelected: false };
      tempAvailableFields.push(field);
    });
    this.availableFields = tempAvailableFields;
    this.alwaysAvailableFields = tempAvailableFields;

    // Remove infoComponent if it's still present
    const infoComponent = this.$parent.$refs.infoPartRef;
    infoComponent.remove();
  }
};
</script>
