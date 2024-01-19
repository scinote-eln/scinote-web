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
    <div v-if="operator !== 'between'" class="sci-input-container">
      <input
        class="sci-input-field"
        type="text"
        name="value"
        v-model="value"
        :data-e2e="`e2e-IF-invInventoryFilterCO-input${this.filter.column.id}`"
        :placeholder= "this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryNumberValue.input_placeholder',{name: this.filter.column.name})"
      />
    </div>
    <div v-else class="number-range-selector">
      <div class="sci-input-container">
        <input
          class="sci-input-field"
          type="text"
          name="from"
          v-model="from"
          :data-e2e="`e2e-IF-invInventoryFilterCO-inputFrom${this.filter.column.id}`"
          :placeholder= "this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryNumberValue.from_placeholder')"
        />
      </div>
      <span class="between-delimiter">—</span>
      <div class="sci-input-container">
        <input
          class="sci-input-field"
          type="text"
          name="to"
          v-model="to"
          :data-e2e="`e2e-IF-invInventoryFilterCO-inputTo${this.filter.column.id}`"
          :placeholder= "this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryNumberValue.to_placeholder')"
        />
      </div>
    </div>
  </div>
</template>

<script>
import FilterMixin from '../mixins/filter.js';
import DropdownSelector from '../../shared/legacy/dropdown_selector.vue';

export default {
  name: 'RepositoryNumberValue',
  mixins: [FilterMixin],
  data() {
    return {
      operators: [
        { value: 'equal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.equal_to') },
        { value: 'unequal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.unequal_to') },
        { value: 'greater_than', label: this.i18n.t('repositories.show.repository_filter.filters.operators.greater_than') },
        { value: 'greater_than_or_equal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.greater_than_or_equal_to') },
        { value: 'less_than', label: this.i18n.t('repositories.show.repository_filter.filters.operators.less_than') },
        { value: 'less_than_or_equal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.less_than_or_equal_to') },
        { value: 'between', label: this.i18n.t('repositories.show.repository_filter.filters.operators.between') }
      ],
      operator: 'equal_to',
      value: '',
      from: '',
      to: ''
    };
  },
  components: {
    DropdownSelector
  },
  methods: {
    validateNumber(number) {
      return number.replace(/[^0-9.]/g, '').match(/^\d*(\.\d{0,10})?/)[0];
    }
  },
  watch: {
    value() {
      this.value = this.validateNumber(this.value);
      this.parameters = { number: this.value };
      this.updateFilter();
    },
    to() {
      this.to = this.validateNumber(this.to);
      this.parameters = { from: this.from, to: this.to };
      this.updateFilter();
    },
    from() {
      this.from = this.validateNumber(this.from);
      this.parameters = { from: this.from, to: this.to };
      this.updateFilter();
    }
  },
  computed: {
    isBlank() {
      return (!this.value && this.operator !== 'between')
               || ((!this.to || !this.from) && this.operator === 'between');
    }
  }
};
</script>
