<template>
  <div>
    <div v-if="canManage" :title="mandatoryErrorTitle" class="relative">
      <SelectDropdown
        class="h-10 flex w-full"
        :searchable="true"
        :options="options"
        :borderless="!params.inSidebar"
        :clearable="true"
        :error="showError"
        size="sm"
        :value="listValue"
        @change="changeValue"
        @close="touch"
      />
      <MandatoryError :show="params.inSidebar && showError" />
    </div>
    <div v-else>
      {{ selectedOption ? selectedOption[1] : '' }}
    </div>
  </div>
</template>

<script>
import SelectDropdown from '../../../shared/select_dropdown.vue';
import MandatoryError from './shared/mandatory_error.vue';
import mandatoryCellMixin from './mixins/mandatory_cell.js';

export default {
  name: 'ListValue',
  props: {
    params: {
      required: true
    }
  },
  mixins: [mandatoryCellMixin],
  components: {
    MandatoryError,
    SelectDropdown
  },
  computed: {
    isEmpty() {
      return this.listValue === null || this.listValue === undefined;
    },
    options() {
      return this.params.colDef.cellRendererParams.columnItems.map(item => ([
        item.id, item.label
      ]));
    },
    selectedOption() {
      return this.options.find(option => option[0] === this.listValue);
    },
    canManage() {
      return this.params?.data?.permissions?.manage || false;
    }
  },
  created() {
    this.listValue = this.params?.value?.value?.id;
  },
  data: () => ({
    listValue: null
  }),
  methods: {
    changeValue(newValue) {
      this.listValue = newValue;
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
