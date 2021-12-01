<template>
  <div class="filter-attributes">
    <DropdownSelector
      :options="this.operators"
      :selectorId="`OperatorSelector${this.filter.id}`"
      @dropdown:changed="updateOperator"
    />
    <div class="sci-input-container">
      <input
        @input="updateInput"
        class="sci-input-field"
        type="text"
        name="value"
        v-model="value"
        :placeholder= "'Enter ' + this.filter.column.name"
      />
    </div>
  </div>
</template>

<script>
  //import FilterMixin from 'vue/bmt_filter/mixins/filter.js'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'
  export default {
    name: 'RepositoryTextValue',
    //mixins: [FilterMixin],
    props: {
      filter: Object
    },
    data() {
      return {
        operators: [
          { value: 'contain', label: 'Contains' },
          { value: 'not_contain', label: 'Doesn\'t contain' },
          { value: 'empty', label: 'Is empty' }
        ],
        operator: this.filter.data.operator,
        value: this.filter.data.value
      }
    },
    components: {
      DropdownSelector
    },
    methods: {
      updateOperator(operator)  {
        this.operator = operator;
        this.updateFilter();
      },
      updateFilter() {
        this.$emit('filter:updateData', {
          operator: this.operator,
          value: this.value
        })
      }
    }
  }
</script>
