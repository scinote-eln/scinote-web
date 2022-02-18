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
    <div class="filter-datepicker-input">
      <DateTimePicker @change="updateDate" :selectorId="`TimePicker${filter.id}`" :timeOnly="true"  :defaultValue="currentDate()" />
    </div>
    <span class="between-delimiter">—</span>
    <div class="filter-datepicker-to-input">
      <DateTimePicker @change="updateDateTo" :selectorId="`TimePickerTo${filter.id}`" :timeOnly="true" :defaultValue="currentDate(7 * 24 * 60 * 60)" />
    </div>
  </div>
</template>

<script>
  import FilterMixin from 'vue/repository_filter/mixins/filter.js'
  import DateTimeFilterMixin from 'vue/repository_filter/mixins/filters/date_time_filter.js'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'
  import DateTimePicker from 'vue/shared/date_time_picker.vue'

  export default {
    name: 'RepositoryTimeRangeValue',
    mixins: [FilterMixin, DateTimeFilterMixin],
    data() {
      return {
        timeType: 'time',
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
        return `${date.getHours()}:${date.getMinutes()}`
      }
    }
  }
</script>
