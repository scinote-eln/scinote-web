<template>
  <div>
    <div v-if="canManage" class="relative flex items-center gap-2">
      <i class="sn-icon sn-icon-checkllist shrink-0"></i>
      <SelectDropdown
        class="h-10 flex w-full"
        :searchable="true"
        :options="options"
        :borderless="true"
        :multiple="true"
        :withCheckboxes="true"
        :clearable="true"
        size="sm"
        :value="checkListValue"
        @change="changeValue"
      />
    </div>
    <div v-else>
      <template v-if="selectedOptions.length == 1">
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

export default {
  name: 'ChecklistValue',
  props: {
    params: {
      required: true
    }
  },
  components: {
    GeneralDropdown,
    SelectDropdown
  },
  computed: {
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
