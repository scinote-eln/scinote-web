<template>
  <div class="filter-attributes">
    <div class="operator-selector">
      <DropdownSelector
      :disableSearch="true"
      :options="operators"
      :selectorId="`OperatorSelector${filter.id}`"
      :selectedValue="operator"
      @dropdown:changed="updateOperator" />
    </div>
    <template v-if="!isPreset">
      <div class="filter-datepicker-input">
        <DateTimePicker @change="updateDate" :selectorId="`DatePicker${filter.id}`" :onlyDate="true" />
      </div>
      <div class="filter-datepicker-to-input" v-if="operator == 'between'">
        <DateTimePicker @change="updateDateTo" :selectorId="`DatePickerTo${filter.id}`" :onlyDate="true" />
      </div>
    </template>
  </div>
</template>

<script>
  import FilterMixin from 'vue/repository_filter/mixins/filter.js'
  import DateTimeFilterMixin from 'vue/repository_filter/mixins/filters/date_time_filter.js'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'
  import DateTimePicker from 'vue/shared/date_picker.vue'

  export default {
    name: 'RepositoryDateValue',
    mixins: [FilterMixin, DateTimeFilterMixin],
    data() {
      return {
        timeType: 'date',
        operators: [
          { value: 'today', label: this.i18n.t('repositories.show.repository_filter.filters.operators.today') },
          { value: 'yesterday', label: this.i18n.t('repositories.show.repository_filter.filters.operators.yesterday') },
          { value: 'last_week', label: this.i18n.t('repositories.show.repository_filter.filters.operators.last_week') },
          { value: 'this_month', label: this.i18n.t('repositories.show.repository_filter.filters.operators.this_month') },
          { value: 'this_year', label: this.i18n.t('repositories.show.repository_filter.filters.operators.this_year') },
          { value: 'last_year', label: this.i18n.t('repositories.show.repository_filter.filters.operators.last_year') },
          { value: 'equal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.equal_to') },
          { value: 'unequal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.unequal_to') },
          { value: 'greater_than', label: this.i18n.t('repositories.show.repository_filter.filters.operators.greater_than') },
          { value: 'greater_than_or_equal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.greater_than_or_equal_to') },
          { value: 'less_than', label: this.i18n.t('repositories.show.repository_filter.filters.operators.less_than') },
          { value: 'less_than_or_equal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.less_than_or_equal_to') },
          { value: 'between', label: this.i18n.t('repositories.show.repository_filter.filters.operators.between') }
        ],
        operator: 'equal_to',
        date: null,
        dateTo: null,
        value: null
      }
    },
    components: {
      DropdownSelector,
      DateTimePicker
    },
    watch: {
      value() {
        this.parameters = this.value;
        this.updateFilter();
      }
    },
    methods: {
      formattedDate(date) {
        return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`
      }
    }
  }
</script>
