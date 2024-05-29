<template>
    <!-- number col -->
    <div class="py-1 min-h-12 px-2 flex items-center" :class="{
      'bg-sn-super-light-blue': selected
    }">{{ index + 1 }}</div>

    <div class="py-1 truncate min-h-12 px-2 flex items-center" :title="item" :class="{
      'bg-sn-super-light-blue': selected
    }">{{ item }}</div>

    <div class="py-1 min-h-12 flex items-center justify-center text-sn-grey" :class="{
      'bg-sn-super-light-blue': selected
    }">
      <i class="sn-icon sn-icon-arrow-right text-sn-gray"></i>
    </div>

    <div class="py-1 min-h-12 flex items-center flex-col gap-2 px-2" :class="{
      'bg-sn-super-light-blue': selected
    }">

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

    <div class="py-1 min-h-12 px-2 flex items-center" :class="{
      'bg-sn-super-light-blue': selected
    }">
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

    <div class="py-1 min-h-12 px-2 flex items-center" :title="params.import_data.columns[index]" :class="{
      'bg-sn-super-light-blue': selected
    }">{{ params.import_data.columns[index] }}</div>
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
    params: {
      type: Object,
      required: true
    },
    autoMapping: {
      type: Boolean,
      required: true
    },
    selected: {
      type: Boolean,
      required: false
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
    newColumn() {
      this.selectedColumnType.value = this.newColumn;
      this.$emit('selection:changed', this.selectedColumnType);
    },
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
      Object.entries(this.params.import_data.available_fields).forEach(([key, value]) => {
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
        value = this.params.import_data.available_fields[e];
      }
      const selectedColumnType = { index: this.index, key: e, value };
      this.selectedColumnType = selectedColumnType;
      this.$emit('selection:changed', selectedColumnType);
    }
  },
  mounted() {
    if (this.autoMapping) {
      this.autoMap();
    }
  }
};
</script>
