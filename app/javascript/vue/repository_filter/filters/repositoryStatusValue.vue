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
      :closeOnSelect="false"
      :options="this.filter.column.items"
      :dataSelectMultipleName="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryStatusValue.multiple_selected')"
      :dataSelectMultipleAllSelected="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryStatusValue.all_selected')"
      :selectorId="`DropdownSelector${this.filter.id}`"
      :placeholder="this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryStatusValue.select_placeholder', {name: this.filter.column.name})"
      @dropdown:changed="updateValue"
    />
  </div>
</template>

<script>
  import FilterMixin from 'vue/repository_filter/mixins/filter.js'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'
  export default {
    name: 'RepositoryStatusValue',
    mixins: [FilterMixin],
    data() {
      return {
        operators: [
          { value: 'any_of', label: this.i18n.t('repositories.show.repository_filter.filters.operators.any_of') },
          { value: 'none_of', label: this.i18n.t('repositories.show.repository_filter.filters.operators.none_of') }
        ],
        operator: 'any_of',
        value: []
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
        return this.operator == 'any_of' && this.value.length == 0;
      }
    }
  }
</script>
