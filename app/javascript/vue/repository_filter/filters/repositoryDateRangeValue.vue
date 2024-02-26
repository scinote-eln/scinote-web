<template>
  <div class="filter-attributes">
    <div class="operator-selector">
      <DropdownSelector
      :disableSearch="true"
      :options="operators"
      :selectorId="`OperatorSelector${filter.id}`"
      :selectedValue="operator"
      :data-e2e="`e2e-DD-invInventoryFilterCO-option${this.filter.column.id}`"
      @dropdown:changed="updateOperator" />
    </div>
    <div class="filter-datepicker-input">
      <DateTimePicker @change="updateDate"
                       :data-e2e="`e2e-DP-invInventoryFilterCO-inputFrom${this.filter.column.id}`"
                       :selectorId="`DatePicker${filter.id}`"
                       :mode="'date'"
                       :defaultValue="date" />
    </div>
    <span class="between-delimiter">—</span>
    <div class="filter-datepicker-to-input">
      <DateTimePicker @change="updateDateTo"
                      :data-e2e="`e2e-DP-invInventoryFilterCO-inputTo${this.filter.column.id}`"
                      :selectorId="`DatePickerTo${filter.id}`"
                      :mode="'date'"
                      :defaultValue="dateTo" />
    </div>
  </div>
</template>

<script>
import FilterMixin from '../mixins/filter.js';
import RangeDateTimeFilterMixin from '../mixins/filters/range_date_time_filter.js';
import DropdownSelector from '../../shared/legacy/dropdown_selector.vue';
import DateTimePicker from '../../shared/date_time_picker.vue';

export default {
  name: 'RepositoryDateRangeValue',
  mixins: [FilterMixin, RangeDateTimeFilterMixin],
  data() {
    return {
      timeType: 'date',
      operators: [
        { value: 'equal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.date.on') },
        { value: 'greater_than_or_equal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.date.after') },
        { value: 'less_than', label: this.i18n.t('repositories.show.repository_filter.filters.operators.date.before') },
        { value: 'between', label: this.i18n.t('repositories.show.repository_filter.filters.operators.between') },
        { value: 'unequal_to', label: this.i18n.t('repositories.show.repository_filter.filters.operators.date.not_on') }
      ],
      operator: 'equal_to',
      date: null,
      dateTo: null,
      value: null
    };
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
      if (!date) return null;
      return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
    }
  }
};
</script>
