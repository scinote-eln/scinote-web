<template>
  <div class="filter-attributes">
    <DropdownSelector
      :disableSearch="true"
      :options="this.operators"
      :selectorId="`OperatorSelector${this.filter.id}`"
      @dropdown:changed="updateOperator"
    />
    <div class="sci-input-container">
      <input
        @input="updateFilter"
        class="sci-input-field"
        type="text"
        name="value"
        v-model="value"
        :placeholder= "this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryNumberValue.input_placeholder',{name: this.filter.column.name})"
      />
    </div>
  </div>
</template>

<script>
  import FilterMixin from 'vue/repository_filter/mixins/filter.js'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'
  export default {
    name: 'RepositoryTextValue',
    mixins: [FilterMixin],
    data() {
      return {
        operators: [
          { value: 'contains', label: this.i18n.t('repositories.show.repository_filter.filters.operators.contain') },
          { value: 'doesnt_contain', label: this.i18n.t('repositories.show.repository_filter.filters.operators.not_contain') },
          { value: 'empty', label: this.i18n.t('repositories.show.repository_filter.filters.operators.empty') }
        ],
        operator: 'contains',
        value: ''
      }
    },
    components: {
      DropdownSelector
    },
    computed: {
      isBlank(){
        return this.operator == 'contains' && !this.value;
      }
    }
  }
</script>
