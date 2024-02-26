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
    <DropdownSelector
      :optionClass="'checkbox-icon'"
      :dataCombineTags="true"
      :noEmptyOption="false"
      :singleSelect="false"
      :groupSelector="true"
      :selectedValue="this.value"
      :options="this.my_modules"
      :optionLabel="renderOption"
      :closeOnSelect="false"
      :dataSelectMultipleName="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryMyModuleValue.multiple_selected')"
      :dataSelectMultipleAllSelected="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryMyModuleValue.all_selected')"
      :selectorId="`MyModulesSelector${this.filter.id}`"
      :placeholder="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryMyModuleValue.select_placeholder')"
      :data-e2e="`e2e-DC-invInventoryFilterCO-input${this.filter.column.id}`"
      @dropdown:changed="updateValue"
    />
  </div>
</template>

<script>
import FilterMixin from '../mixins/filter.js';
import DropdownSelector from '../../shared/legacy/dropdown_selector.vue';

export default {
  name: 'RepositoryMyModuleValue',
  mixins: [FilterMixin],
  data() {
    return {
      operators: [
        { value: 'any_of', label: this.i18n.t('repositories.show.repository_filter.filters.operators.any_of') },
        { value: 'all_of', label: this.i18n.t('repositories.show.repository_filter.filters.operators.all_of') },
        { value: 'none_of', label: this.i18n.t('repositories.show.repository_filter.filters.operators.none_of') }
      ],
      operator: 'any_of',
      value: []
    };
  },
  components: {
    DropdownSelector
  },
  watch: {
    value() {
      this.parameters = { my_module_ids: this.value };
      this.updateFilter();
    }
  },
  methods: {
    updateValue(value) {
      this.value = value;
    },
    renderOption(data) {
      return `<span class="task-option">
                  ${data.label}
                </span>`;
    }
  },
  computed: {
    isBlank() {
      return this.operator == 'any_of' && this.value.length == 0;
    }
  }
};
</script>
