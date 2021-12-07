<template>
  <div class="filter-attributes">
    <DropdownSelector
      :disableSearch="true"
      :options="this.operators"
      :selectorId="`OperatorSelector${this.filter.id}`"
      @dropdown:changed="updateOperator"
    />
    <DropdownSelector
      :optionClass="'checkbox-icon'"
      :dataCombineTags="true"
      :noEmptyOption="false"
      :singleSelect="false"
      :groupSelector="true"
      :options="this.my_modules"
      :dataSelectMultipleName="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryMyModuleValue.multiple_selected')"
      :dataSelectMultipleAllSelected="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryMyModuleValue.all_selected')"
      :selectorId="`MyModulesSelector${this.filter.id}`"
      :placeholder="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryMyModuleValue.select_placeholder')"
      @dropdown:changed="updateValue"
    />
  </div>
</template>

<script>
  import FilterMixin from 'vue/repository_filter/mixins/filter.js'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'
  export default {
    name: 'RepositoryMyModuleValue',
    mixins: [FilterMixin],
    data() {
      return {
        operators: [
          { value: 'any_of', label: this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryMyModuleValue.operators.any_of') },
          { value: 'all_of', label: this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryMyModuleValue.operators.all_of') },
          { value: 'none_of', label: this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryMyModuleValue.operators.none_of') }
        ],
        operator: 'any_of',
        value: ''
      }
    },
    components: {
      DropdownSelector
    },
    methods: {
      updateValue(value) {
        this.value = value
        this.updateFilter();
      }
    },
    computed: {
      isBlank(){
        return this.operator == 'any_of' && !this.value;
      }
    }
  }
</script>
