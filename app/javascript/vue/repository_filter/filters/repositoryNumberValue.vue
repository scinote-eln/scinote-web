<template>
  <div class="filter-attributes">
    <DropdownSelector
      :disableSearch="true"
      :options="this.operators"
      :selectedValue="this.operator"
      :selectorId="`OperatorSelector${this.filter.id}`"
      @dropdown:changed="updateOperator"
    />
    <div v-if="operator !== 'between'" class="sci-input-container">
      <input
        class="sci-input-field"
        type="number"
        name="value"
        v-model="value"
        :placeholder= "this.i18n.t('repositories.show.repository_filter.filters.types.RepositoryNumberValue.input_placeholder',{name: this.filter.column.name})"
      />
    </div>
    <div v-else class="range-selector">
      <div class="sci-input-container">
        <input
          @input="updateRange"
          class="sci-input-field"
          type="number"
          name="from"
          v-model="from"

        />
      </div>
      -
      <div class="sci-input-container">
        <input
          @input="updateRange"
          class="sci-input-field"
          type="number"
          name="to"
          v-model="to"
        />
      </div>
    </div>
  </div>
</template>

<script>
  import FilterMixin from 'vue/repository_filter/mixins/filter.js'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'
  export default {
    name: 'RepositoryNumberValue',
    mixins: [FilterMixin],
    data() {
      return {
        operators: [
          { value: 'equal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.equal_to')},
          { value: 'unequal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.unequal_to') },
          { value: 'greater_than', label: this.i18n.t('repositories.show.repository_filter.filters.operators.greater_than') },
          { value: 'greater_than_or_equal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.greater_than_or_equal_to') },
          { value: 'less_than', label: this.i18n.t('repositories.show.repository_filter.filters.operators.less_than') },
          { value: 'less_than_or_equal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.less_than_or_equal_to') },
          { value: 'between', label: this.i18n.t('repositories.show.repository_filter.filters.operators.between') }
        ],
        operator: 'equal_to',
        value: '',
        from: '',
        to: ''
      }
    },
    components: {
      DropdownSelector
    },
    methods: {
      updateRange() {
        this.value = {
          from: this.from,
          to: this.to
        };
      }
    },
    watch: {
      operator() {
        if(this.operator !== 'between' && !(typeof this.value === 'string')) this.value = '';
        if(this.operator === 'between') this.value = {to: '', from: ''};

      },
      value() {
        if (this.operator === 'between') {
          this.parameters = this.value;
        } else {
          this.parameters = { number: this.value }
        }
        this.updateFilter();
      }
    },
    computed: {
      isBlank(){
        return this.operator == 'equal' && !this.value;
      }
    }
  }
</script>
