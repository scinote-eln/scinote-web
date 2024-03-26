<template>
  <div class="filter-attributes">
    <div class="operator-selector">
      <DropdownSelector
        :disableSearch="true"
        :options="operators"
        :selectedValue="this.operator"
        :selectorId="`OperatorSelector${filter.id}`"
        :data-e2e="`e2e-DD-invInventoryFilterCO-option${this.filter.column.id}`"
        @dropdown:changed="updateOperator"
      />
    </div>
    <div class="sci-input-container">
      <input v-if="operator === 'file_contains'"
        class="sci-input-field"
        type="text"
        name="value"
        v-model="value"
        :data-e2e="`e2e-IF-invInventoryFilterCO-input${this.filter.column.id}`"
        :placeholder="i18n.t('repositories.show.repository_filter.filters.types.RepositoryAssetValue.input_placeholder')"
      />
    </div>
  </div>
</template>

<script>
  import FilterMixin from '../mixins/filter.js';
  import DropdownSelector from '../../shared/legacy/dropdown_selector.vue';

export default {
  name: 'RepositoryAssetValue',
  mixins: [FilterMixin],
  props: {
    filter: Object
  },
  data() {
    return {
      operators: [
        { value: 'file_contains', label: this.i18n.t('repositories.show.repository_filter.filters.operators.file_contains') },
        { value: 'file_attached', label: this.i18n.t('repositories.show.repository_filter.filters.operators.file_attached') },
        { value: 'file_not_attached', label: this.i18n.t('repositories.show.repository_filter.filters.operators.file_not_attached') }
      ],
      operator: 'file_contains',
      value: ''
    };
  },
  watch: {
    operator() {
      if (this.operator !== 'file_contains') this.value = '';
    },
    value() {
      this.parameters = this.operator === 'file_contains' ? { text: this.value } : {};
      this.updateFilter();
    }
  },
  components: {
    DropdownSelector
  },
  computed: {
    isBlank() {
      return this.operator == 'file_contains' && !this.value;
    }
  }
};
</script>
