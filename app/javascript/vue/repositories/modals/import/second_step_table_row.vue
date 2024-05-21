<template>
  <!-- columns -->
  <div class="flex flex-row justify-between gap-6">
    <!-- number col -->
    <div class="w-6 h-10 flex items-center">{{ index + 1 }}</div>

    <div class="w-40 h-10 flex items-center truncate" :title="item">{{ item }}</div>

    <i class="sn-icon sn-icon-arrow-right w-6  h-10 flex items-center relative left-5"></i>

    <div class="w-60  min-h-10 flex items-center flex-col gap-2">

      <!-- system generated data -->
      <SelectDropdown v-if="systemGeneratedData.includes(item)"
        :disabled="true"
        :placeholder="String(item)"
      ></SelectDropdown>

      <SelectDropdown
        v-else
        :options="dropdownOptions"
        @change="changeSelected"
        @isOpen="handleIsOpen"
        :clearable="true"
        :size="'sm'"
        :placeholder="computeMatchNotFound ?
        i18n.t('repositories.import_records.steps.step2.table.tableRow.placeholders.matchNotFound') :
        i18n.t('repositories.import_records.steps.step2.table.tableRow.placeholders.doNotImport')"
        :title="this.selectedColumnType?.value"
        :value="this.selectedColumnType?.key"
      ></SelectDropdown>
      <template v-if="selectedColumnType?.key == 'new'">
        <SelectDropdown
          :options="newColumnTypes"
          @change="(v) => { newColumn.type = v }"
          :value="newColumn.type"
          size="sm"
          placeholder="Select column type"
        ></SelectDropdown>
        <div class="sci-input-container-v2 w-full">
          <input type="text" v-model="newColumn.name" class="sci-input" placeholder="Name">
        </div>
      </template>
    </div>

    <div class="w-14  h-10 flex items-center flex justify-center">
      <!-- import -->
      <i v-if="this.selectedColumnType?.key && this.selectedColumnType?.value === item && !systemGeneratedData.includes(item)"
        class="sn-icon sn-icon-check" :title="i18n.t('repositories.import_records.steps.step2.table.tableRow.importedColumnTitle')">
      </i>

      <!-- default column -->
      <i v-else-if="systemGeneratedData.includes(item)"
        class="sn-icon sn-icon-check text-sn-sleepy-grey" :title="i18n.t('repositories.import_records.steps.step2.table.tableRow.defaultColumnTitle')">
      </i>

      <!-- user defined this column -->
      <i v-else-if="this.selectedColumnType?.key && this.selectedColumnType?.value !== item"
      class="sn-icon sn-icon-info text-sn-science-blue"
      :title="`${i18n.t('repositories.import_records.steps.step2.table.tableRow.userDefinedColumnTitle')} ${this.selectedColumnType.value}`"></i>

      <!-- error: can not import -->
      <!-- <i v-else-if=""></i> -->

      <!-- match not found -->
      <i v-else-if="computeMatchNotFound"
        class="sn-icon sn-icon-close text-sn-alert-brittlebush" :title="i18n.t('repositories.import_records.steps.step2.table.tableRow.matchNotFoundColumnTitle')">
      </i>

      <!-- do not import -->
      <i v-else class="sn-icon sn-icon-close text-sn-sleepy-grey" :title="i18n.t('repositories.import_records.steps.step2.table.tableRow.doNotImportColumnTitle')"></i>
    </div>

    <div class="w-56 truncate  h-10 flex items-center" :title="stepProps.exampleData[index]">{{ stepProps.exampleData[index] }}</div>
  </div>
</template>

<script>
import SelectDropdown from '../../../shared/select_dropdown.vue';

export default {
  name: 'SecondStepTableRow',
  emits: ['selection:changed'],
  components: {
    SelectDropdown
  },
  props: {
    index: {
      type: Number,
      required: true
    },
    dropdownOptions: {
      type: Array,
      required: true
    },
    item: {
      type: String,
      required: true
    },
    stepProps: {
      type: Object,
      required: true
    },
    autoMapping: {
      type: Boolean,
      required: true
    }
  },
  watch: {
    newColumn() {
      this.selectedColumnType.value = this.newColumn;
      this.$emit('selection:changed', this.selectedColumnType);
    }
  },
  data() {
    return {
      selectedColumnType: null,
      newColumn: {
        type: 'Text',
        name: ''
      },
      newColumnTypes: [
        ['Text', this.i18n.t('repositories.import_records.steps.step2.table.tableRow.newColumnType.text')],
        ['List', this.i18n.t('repositories.import_records.steps.step2.table.tableRow.newColumnType.list')]
      ],
      systemGeneratedData: [
        this.i18n.t('repositories.import_records.steps.step2.table.tableRow.systemGeneratedData.itemId'),
        this.i18n.t('repositories.import_records.steps.step2.table.tableRow.systemGeneratedData.createdOn'),
        this.i18n.t('repositories.import_records.steps.step2.table.tableRow.systemGeneratedData.addedBy'),
        this.i18n.t('repositories.import_records.steps.step2.table.tableRow.systemGeneratedData.addedOn'),
        this.i18n.t('repositories.import_records.steps.step2.table.tableRow.systemGeneratedData.archivedBy'),
        this.i18n.t('repositories.import_records.steps.step2.table.tableRow.systemGeneratedData.archivedOn'),
        this.i18n.t('repositories.import_records.steps.step2.table.tableRow.systemGeneratedData.updatedBy'),
        this.i18n.t('repositories.import_records.steps.step2.table.tableRow.systemGeneratedData.updatedOn')]
    };
  },
  watch: {
    autoMapping(newVal, oldVal) {
      if (newVal === true) {
        this.autoMap();
      } else {
        this.clearAutoMap();
      }
    }
  },
  computed: {
    computeMatchNotFound() {
      return this.autoMapping && ((this.selectedColumnType && !this.selectedColumnType.key) || !this.selectedColumnType);
    }
  },
  methods: {
    autoMap() {
      Object.entries(this.stepProps.availableFields).forEach(([key, value]) => {
        if (this.item === value) {
          this.changeSelected(key);
        }
      });
    },
    clearAutoMap() {
      this.changeSelected(null);
    },
    changeSelected(e) {
      let value;
      if (e === 'new') {
        value = this.newColumn;
      } else {
        value = this.stepProps.availableFields[e];
      }
      const selectedColumnType = { index: this.index, key: e, value };
      this.selectedColumnType = selectedColumnType;
      this.$emit('selection:changed', selectedColumnType);
    },
    handleIsOpen(isOpen) {
      const tableRows = this.$parent.$refs.tableRowsRef;
      if (isOpen) {
        tableRows.style.overflow = 'hidden';
      } else tableRows.style.overflow = 'auto';
    }
  },
  mounted() {
    if (this.autoMapping) {
      this.autoMap();
    }
  }
};
</script>
