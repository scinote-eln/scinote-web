<template>
  <div v-if="availablePositions" class="grid grid-cols-2 gap-4 mb-4">
    <div class="">
      <div class="sci-label">{{ i18n.t(`storage_locations.show.assign_modal.row`) }}</div>
      <SelectDropdown
        :options="availableRows"
        :value="selectedRow"
        @change="selectedRow = $event"
      ></SelectDropdown>
    </div>
    <div>
      <div class="sci-label">{{ i18n.t(`storage_locations.show.assign_modal.column`) }}</div>
      <SelectDropdown
        :disabled="!selectedRow"
        :options="availableColumns"
        :value="selectedColumn"
        @change="selectedColumn= $event"
      ></SelectDropdown>
    </div>
  </div>
</template>

<script>
import SelectDropdown from '../../../shared/select_dropdown.vue';
import axios from '../../../../packs/custom_axios.js';
import {
  available_positions_storage_location_path,
} from '../../../../routes.js';

export default {
  name: 'PositionSelector',
  components: {
    SelectDropdown
  },
  props: {
    selectedContainerId: Number
  },
  created() {
    axios.get(this.positionsUrl)
      .then((response) => {
        this.availablePositions = response.data.positions;
        if (this.availablePositions) {
          this.$nextTick(() => {
            [[this.selectedRow]] = this.availableRows;
            this.$nextTick(() => {
              [[this.selectedColumn]] = this.availableColumns;
            });
          });
        }
      });
  },
  watch: {
    selectedRow() {
      [[this.selectedColumn]] = this.availableColumns;
      this.$emit('change', [this.selectedRow, this.selectedColumn]);
    },
    selectedColumn() {
      this.$emit('change', [this.selectedRow, this.selectedColumn]);
    }
  },
  computed: {
    positionsUrl() {
      return available_positions_storage_location_path(this.selectedContainerId);
    },
    availableRows() {
      return Object.keys(this.availablePositions).map((row) => [row, this.convertNumberToLetter(row)]);
    },
    availableColumns() {
      return (this.availablePositions[this.selectedRow] || []).map((col) => [col, col]);
    }
  },
  data() {
    return {
      availablePositions: {},
      selectedRow: null,
      selectedColumn: null
    };
  },
  methods: {
    convertNumberToLetter(number) {
      const charCode = 96 + parseInt(number, 10);
      return String.fromCharCode(charCode).toUpperCase();
    }
  }
};
</script>
