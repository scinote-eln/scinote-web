<template>
  <div v-if="updateUrl" class="mt-0.5">
    <SelectDropdown :value="value.id"  @change="updateValue" :options="options" size="xs" />
  </div>
  <div v-else>
    {{ value.text }}
  </div>
</template>

<script>

import SelectDropdown from '../../shared/select_dropdown.vue';
import rendersMixin from './renders_mixin.js';
import axios from '../../../packs/custom_axios.js';

export default {
  name: 'ListValue',
  computed: {
    options() {
      return this.params.colDef.columnItems.map((item) => [item.id, item.label]);
    }
  },
  mixins: [rendersMixin],
  components: {
    SelectDropdown
  },
  mounted() {
    if (this.params.value) {
      this.value = this.params.value.value;
    }
  },
  data() {
    return {
      value: {}
    };
  },
  methods: {
    updateValue(newValue) {
      this.value.id = newValue;
      this.updateCell();
    },
    updateCell() {
      const params = { repository_cells: {} };
      params.repository_cells[this.params.colDef.columnId] = this.value.id;
      axios.put(updateUrl, params).then((response) => {

      });
    }
  }
};
</script>
