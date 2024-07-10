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
      <SelectDropdown
        :options="dropdownOptions"
        @change="changeSelected"
        :clearable="true"
        :size="'sm'"
        class="max-w-96"
        :searchable="true"
        :class="{
          'outline-sn-alert-brittlebush outline-1 outline rounded': computeMatchNotFound
        }"
        :placeholder="computeMatchNotFound ?
        i18n.t('repositories.import_records.steps.step2.table.tableRow.placeholders.matchNotFound') :
        i18n.t('repositories.import_records.steps.step2.table.tableRow.placeholders.doNotImport')"
        :title="this.selectedColumnType?.value"
        :value="this.selectedColumnType?.key"
      ></SelectDropdown>
      <template v-if="false">
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
      <i v-if="differentMapingName" :title="i18n.t('repositories.import_records.steps.step2.table.tableRow.importedColumnTitle')"
         class="sn-icon sn-icon-info text-sn-science-blue"></i>
      <i v-else-if="columnMapped" :title="i18n.t('repositories.import_records.steps.step2.table.tableRow.importedColumnTitle')" class="sn-icon sn-icon-check"></i>
      <i v-else-if="matchNotFound && !isSystemColumn(item)" :title="i18n.t('repositories.import_records.steps.step2.table.tableRow.matchNotFoundColumnTitle')"
         class="sn-icon sn-icon-close text-sn-alert-brittlebush"></i>
      <i v-else  :title="i18n.t('repositories.import_records.steps.step2.table.tableRow.doNotImportColumnTitle')" class="sn-icon sn-icon-close text-sn-sleepy-grey"></i>
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
    value: Object
  },
  data() {
    return {
      selectedColumnType: null,
      newColumn: {
        type: 'Text',
        name: ''
      },
      systemColumns: [
        this.i18n.t('repositories.import_records.steps.step2.systemColumns.added_by'),
        this.i18n.t('repositories.import_records.steps.step2.systemColumns.created_on'),
        this.i18n.t('repositories.import_records.steps.step2.systemColumns.updated_by'),
        this.i18n.t('repositories.import_records.steps.step2.systemColumns.updated_on'),
        this.i18n.t('repositories.import_records.steps.step2.systemColumns.archived_by'),
        this.i18n.t('repositories.import_records.steps.step2.systemColumns.archived_on'),
        this.i18n.t('repositories.import_records.steps.step2.systemColumns.parents'),
        this.i18n.t('repositories.import_records.steps.step2.systemColumns.children')
      ],
      newColumnTypes: [
        ['Text', this.i18n.t('repositories.import_records.steps.step2.table.tableRow.newColumnType.text')],
        ['List', this.i18n.t('repositories.import_records.steps.step2.table.tableRow.newColumnType.list')]
      ]
    };
  },
  watch: {
    selected() {
      if (this.value?.key === null) {
        this.selectedColumnType = null;
      }
    },
    autoMapping(newVal) {
      if (newVal === true) {
        this.autoMap();
      } else {
        this.clearAutoMap();
      }
    }
  },
  computed: {
    computeMatchNotFound() {
      return this.autoMapping && !this.isSystemColumn(this.item) && ((this.selectedColumnType && !this.selectedColumnType.key) || !this.selectedColumnType);
    },
    selected() {
      return !!this.value?.key;
    },
    differentMapingName() {
      return this.columnMapped && this.selectedColumnType?.value !== this.item;
    },
    matchNotFound() {
      return this.autoMapping && !this.selectedColumnType?.key;
    },
    columnMapped() {
      return this.selectedColumnType?.key;
    }
  },
  methods: {
    isSystemColumn(column) {
      return this.systemColumns.includes(column);
    },
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
      const value = this.params.import_data.available_fields[e];
      this.selectedColumnType = { index: this.index, key: e, value };
      this.$emit('selection:changed', this.selectedColumnType);
    }
  },
  mounted() {
    if (this.autoMapping) {
      this.autoMap();
    } else {
      this.selectedColumnType = this.value;
    }
  }
};
</script>
