<template>
  <div class="filter-attributes stock-filter-attributes">
    <div class="operator-selector">
      <SelectDropdown
        :searchable="false"
        :options="this.operators"
        :value="this.operator"
        :e2eValue="`e2e-DD-invInventoryFilterCO-option${this.filter.column.id}`"
        @change="updateOperator"
      />
    </div>
    <div v-if="operator !== 'between'" class="sci-input-container-v2">
      <input
        class="sci-input-field"
        type="text"
        name="value"
        v-model="value"
        :data-e2e="`e2e-IF-invInventoryFilterCO-input${this.filter.column.id}`"
        :placeholder= "this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryStockValue.input_placeholder')"
      />
    </div>
    <div v-else class="number-range-selector">
      <div class="sci-input-container-v2">
        <input
          class="sci-input-field"
          type="text"
          name="from"
          v-model="from"
          :data-e2e="`e2e-IF-invInventoryFilterCO-inputFrom${this.filter.column.id}`"
          :placeholder= "this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryStockValue.from_placeholder')"
        />
      </div>
      <span class="between-delimiter">—</span>
      <div class="sci-input-container-v2">
        <input
          class="sci-input-field"
          type="text"
          name="to"
          v-model="to"
          :data-e2e="`e2e-IF-invInventoryFilterCO-inputTo${this.filter.column.id}`"
          :placeholder= "this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryStockValue.to_placeholder')"
        />
      </div>
    </div>
    <div class="stock-unit-filter-dropdown">
      <SelectDropdown
        :value="this.stock_unit"
        :options="this.prepareUnitOptions()"
        :e2eValue="`e2e-DD-invInventoryFilterCO-unit${this.filter.column.id}`"
        @change="updateStockUnit"
      />
    </div>
  </div>
</template>

<script>
import FilterMixin from '../mixins/filter.js';
import SelectDropdown from '../../shared/select_dropdown.vue';

export default {
  name: 'RepositoryStockValue',
  mixins: [FilterMixin],
  data() {
    return {
      operators: [
        [ 'equal_to', this.i18n.t('repositories.show.repository_filter.filters.operators.equal_to') ],
        [ 'unequal_to', this.i18n.t('repositories.show.repository_filter.filters.operators.unequal_to') ],
        [ 'greater_than', this.i18n.t('repositories.show.repository_filter.filters.operators.greater_than') ],
        [ 'greater_than_or_equal_to', this.i18n.t('repositories.show.repository_filter.filters.operators.greater_than_or_equal_to') ],
        [ 'less_than', this.i18n.t('repositories.show.repository_filter.filters.operators.less_than') ],
        [ 'less_than_or_equal_to', this.i18n.t('repositories.show.repository_filter.filters.operators.less_than_or_equal_to') ],
        [ 'between', this.i18n.t('repositories.show.repository_filter.filters.operators.between') ]
      ],
      operator: 'equal_to',
      value: '',
      from: '',
      to: '',
      stock_unit: 'all'
    };
  },
  components: {
    SelectDropdown
  },
  methods: {
    validateNumber(number) {
      return number.replace(/[^0-9.]/g, '').match(/^\d*(\.\d{0,10})?/)[0];
    },

    prepareUnitOptions() {
      return [
        ['all', this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryStockValue.all_units')],
        ['none', this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryStockValue.no_unit')]
      ].concat(this.filter.column.items.map((i) => [i.id, i.name]));
    },

    updateStockUnit(value) {
      this.stock_unit = value;
    }

  },
  created() {
    if (this.parameters) {
      this.value = this.parameters.value || '';
      this.from = this.parameters.from || '';
      this.to = this.parameters.to || '';
      this.stock_unit = this.parameters.stock_unit || 'all';
    }
  },
  watch: {
    stock_unit() {
      this.parameters.stock_unit = this.stock_unit;
      this.updateFilter();
    },
    value() {
      this.value = this.validateNumber(this.value);
      this.parameters = { value: this.value, stock_unit: this.stock_unit };
      this.updateFilter();
    },
    to() {
      this.to = this.validateNumber(this.to);
      this.parameters = { from: this.from, to: this.to, stock_unit: this.stock_unit };
      this.updateFilter();
    },
    from() {
      this.from = this.validateNumber(this.from);
      this.parameters = { from: this.from, to: this.to, stock_unit: this.stock_unit };
      this.updateFilter();
    }
  },
  computed: {
    isBlank() {
      return (!this.value && this.operator != 'between')
               || ((!this.to || !this.from) && this.operator == 'between');
    }
  }
};
</script>
