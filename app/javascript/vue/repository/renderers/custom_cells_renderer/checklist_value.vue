<template>
  <div>
    <div v-if="canManage" :title="mandatoryErrorTitle" class="relative flex items-center gap-2">
      <SelectDropdown
        class="h-10 flex w-full"
        :searchable="true"
        :options="options"
        :borderless="!params.inSidebar"
        :multiple="true"
        :withCheckboxes="true"
        :clearable="true"
        :error="showError"
        size="sm"
        :value="checkListValue"
        @change="changeValue"
        @close="touch"
      />
      <MandatoryError :show="params.inSidebar && showError" />
    </div>
    <div v-else>
      <template v-if="selectedOptions.length == 0">
        <span>—</span>
      </template>
      <template v-else-if="selectedOptions.length == 1">
        <span>{{ selectedOptions[0][1] }}</span>
      </template>
      <GeneralDropdown v-else>
        <template v-slot:field>
          <span class="text-sn-blue hover:underline cursor-pointer">
            {{ selectedOptions.length }}
            {{ i18n.t('libraries.manange_modal_column.checklist_type.multiple_options') }}
          </span>
        </template>
        <template v-slot:flyout>
          <div v-for="option in selectedOptions" :key="option[0]" class="px-2 py-1">
            {{ option[1] }}
          </div>
        </template>
      </GeneralDropdown>
    </div>
  </div>
</template>

<script>
import GeneralDropdown from '../../../shared/general_dropdown.vue';
import SelectDropdown from '../../../shared/select_dropdown.vue';
import MandatoryError from './shared/mandatory_error.vue';
import mandatoryCellMixin from './mixins/mandatory_cell.js';

export default {
  name: 'ChecklistValue',
  props: {
    params: {
      required: true
    }
  },
  mixins: [mandatoryCellMixin],
  components: {
    MandatoryError,
    GeneralDropdown,
    SelectDropdown
  },
  computed: {
    isEmpty() {
      return !this.checkListValue?.length;
    },
    options() {
      return this.params.colDef.cellRendererParams.columnItems.map(item => ([
        item.id, item.label
      ]));
    },
    selectedOptions() {
      return this.options.filter(option => this.checkListValue.includes(option[0]));
    },
    canManage() {
      return this.params?.data?.permissions?.manage || false;
    }
  },
  created() {
    this.checkListValue = this.params?.value?.value?.map(item => item.value) || [];
  },
  data: () => ({
    checkListValue: []
  }),
  methods: {
    changeValue(newValue) {
      this.checkListValue = newValue;
      if (this.blockedByMandatory()) return;

      this.params.dtComponent.$emit(
        'updateCell',
        this.params.data,
        this.params.colDef,
        newValue
      );
    }
  }
};
</script>
