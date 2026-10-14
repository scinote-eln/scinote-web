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
    <div class="sci-input-container-v2">
      <input
        class="sci-input-field"
        :class="{ invisible: operator !== 'contains' }"
        type="text"
        name="value"
        v-model="value"
        :data-e2e="`e2e-IF-invInventoryFilterCO-input${this.filter.column.id}`"
        :placeholder= "i18n.t('repositories.show.repository_filter.filters.types.RepositoryRelationshipValue.input_placeholder')"
      />
    </div>
  </div>
</template>

<script>
import FilterMixin from '../mixins/filter.js';
import SelectDropdown from '../../shared/select_dropdown.vue';

export default {
  name: 'RepositoryRelationshipValue',
  mixins: [FilterMixin],
  data() {
    return {
      operators: [
        [ 'contains', this.i18n.t('repositories.show.repository_filter.filters.operators.contains') ],
        [ 'contains_relationship', this.i18n.t('repositories.show.repository_filter.filters.operators.contains_relationship') ],
        [ 'doesnt_contain_relationship', this.i18n.t('repositories.show.repository_filter.filters.operators.does_not_contain_relationship') ]
      ],
      operator: 'contains',
      value: ''
    };
  },
  components: {
    SelectDropdown
  },
  watch: {
    value() {
      this.parameters = { text: this.value };
      this.updateFilter();
    }
  },
  computed: {
    isBlank() {
      return !this.operator || (this.operator === 'contains' && !this.value);
    }
  }
};
</script>
