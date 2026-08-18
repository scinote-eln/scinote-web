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
  import SelectDropdown from '../../shared/select_dropdown.vue';

export default {
  name: 'RepositoryAssetValue',
  mixins: [FilterMixin],
  props: {
    filter: Object
  },
  data() {
    return {
      operators: [
        [ 'file_contains', this.i18n.t('repositories.show.repository_filter.filters.operators.file_contains') ],
        [ 'file_attached', this.i18n.t('repositories.show.repository_filter.filters.operators.file_attached') ],
        [ 'file_not_attached', this.i18n.t('repositories.show.repository_filter.filters.operators.file_not_attached') ]
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
    SelectDropdown
  },
  computed: {
    isBlank() {
      return this.operator == 'file_contains' && !this.value;
    }
  }
};
</script>
