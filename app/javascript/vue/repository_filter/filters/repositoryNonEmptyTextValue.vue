<template>
  <div class="filter-attributes">
    <div class="operator-selector">
      <DropdownSelector
        :disableSearch="true"
        :options="this.operators"
        :selectedValue="this.operator"
        :selectorId="`OperatorSelector${this.filter.id}`"
        :data-e2e="`e2e-DD-invInventoryFilterCO-option${this.filter.column.id}`"
        @dropdown:changed="updateOperator"
      />
    </div>
    <div class="sci-input-container">
      <input
        class="sci-input-field"
        type="text"
        name="value"
        v-model="value"
        :data-e2e="`e2e-IF-invInventoryFilterCO-input${this.filter.column.id}`"
        :placeholder= "this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryNonEmptyTextValue.input_placeholder', {name: this.filter.column.name})"
      />
    </div>
  </div>
</template>

<script>
import FilterMixin from '../mixins/filter.js';
import DropdownSelector from '../../shared/legacy/dropdown_selector.vue';

export default {
  name: 'RepositoryNonEmptyTextValue',
  mixins: [FilterMixin],
  data() {
    return {
      operators: [
        { value: 'contains', label: this.i18n.t('repositories.show.repository_filter.filters.operators.contains') },
        { value: 'doesnt_contain', label: this.i18n.t('repositories.show.repository_filter.filters.operators.does_not_contain') }
      ],
      operator: 'contains',
      value: ''
    };
  },
  components: {
    DropdownSelector
  },
  watch: {
    value() {
      this.parameters = { text: this.value };
      this.updateFilter();
    }
  },
  computed: {
    isBlank() {
      return this.operator == 'contains' && !this.value;
    }
  }
};
</script>
