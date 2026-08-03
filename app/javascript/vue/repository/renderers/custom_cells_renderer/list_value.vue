<template>
  <div>
    <div v-if="params.data.permissions.manage" class="relative">
      <SelectDropdown
        class="h-10 flex w-full"
        :searchable="true"
        :options="options"
        :borderless="true"
        :clearable="true"
        size="sm"
        :value="listValue"
        @change="changeValue"
      />
    </div>
    <div v-else>
      {{ selectedOption ? selectedOption[1] : '' }}
    </div>
  </div>
</template>

<script>
import SelectDropdown from '../../../shared/select_dropdown.vue';

export default {
  name: 'ListValue',
  props: {
    params: {
      required: true
    }
  },
  components: {
    SelectDropdown
  },
  computed: {
    options() {
      return this.params.colDef.cellRendererParams.columnItems.map(item => ([
        item.id, item.label
      ]));
    },
    selectedOption() {
      return this.options.find(option => option[0] === this.listValue);
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
