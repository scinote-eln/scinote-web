<template>
  <div class="filter-attributes">
    <div class="operator-selector">
      <SelectDropdown
        :searchable="false"
        :options="this.operators"
        :value="this.operator"
        :e2eValue="`e2e-DD-invInventoryFilterCO-option${this.filter.column.id}`"
        @change="updateOperator"
      />
    </div>
    <SelectDropdown
      :multiple="true"
      :withCheckboxes="true"
      :value="this.value"
      :options="this.filter.column.items.map((i) => [i.value, i.label])"
      :fewOptionsPlaceholder="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryListValue.multiple_selected')"
      :allOptionsPlaceholder="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryListValue.all_selected')"
      :placeholder="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryListValue.select_placeholder', {name: this.filter.column.name})"
      :e2eValue="`e2e-DC-invInventoryFilterCO-input${this.filter.column.id}`"
      @change="updateValue"
    />
  </div>
</template>

<script>
import FilterMixin from '../mixins/filter.js';
import SelectDropdown from '../../shared/select_dropdown.vue';

export default {
  name: 'RepositoryListValue',
  mixins: [FilterMixin],
  data() {
    return {
      operators: [
        [ 'any_of', this.i18n.t('repositories.show.repository_filter.filters.operators.any_of') ],
        [ 'none_of', this.i18n.t('repositories.show.repository_filter.filters.operators.none_of') ]
      ],
      operator: 'any_of',
      value: []
    };
  },
  components: {
    SelectDropdown
  },
  watch: {
    value() {
      this.parameters = { item_ids: this.value };
      this.updateFilter();
    }
  },
  methods: {
    updateValue(value) {
      this.value = value;
    }
  },
  computed: {
    isBlank() {
      return this.operator == 'any_of' && this.value.length == 0;
    }
  }
};
</script>
