<template>
  <div class="filter-attributes">
    <DropdownSelector
      :options="this.operators"
      :selectorId="`OperatorSelector${this.filter.id}`"
    />
    <div class="sci-input-container">
      <input
        class="sci-input-field"
        type="text"
        name="value"
        v-model="value"
        :placeholder= "'Enter value'"
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
        operator: 'contain',
        value: ''
      }
    },
    components: {
      DropdownSelector
    }
  }
</script>
