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
    <div class="datetime-filter-attributes">
      <div class="filter-datepicker-input">
        <DateTimePicker @change="updateDate" :selectorId="`DatePicker${filter.id}`" />
      </div>
      <div class="between-delimiter vertical"></div>
      <div class="filter-datepicker-to-input">
        <DateTimePicker @change="updateDateTo" :selectorId="`DatePickerTo${filter.id}`" />
      </div>
    </div>
  </div>
</template>

<script>
  import FilterMixin from 'vue/repository_filter/mixins/filter.js'
  import DateTimeFilterMixin from 'vue/repository_filter/mixins/filters/date_time_filter.js'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'
  import DateTimePicker from 'vue/shared/date_time_picker.vue'

  export default {
    name: 'RepositoryDateRangeValue',
    mixins: [FilterMixin, DateTimeFilterMixin],
    data() {
      return {
        timeType: 'datetime',
        operators: [
          { value: 'greater_than_or_equal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.date.after') },
          { value: 'less_than', label: this.i18n.t('repositories.show.repository_filter.filters.operators.date.before') },
          { value: 'equal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.date.on') },
          { value: 'between', label: this.i18n.t('repositories.show.repository_filter.filters.operators.between') },
          { value: 'unequal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.date.not_on') }
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
        return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()} ${date.getHours()}:${date.getMinutes()}`
      }
    }
  }
</script>
