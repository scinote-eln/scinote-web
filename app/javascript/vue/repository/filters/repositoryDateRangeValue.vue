<template>
  <div class="filter-attributes">
    <div class="operator-selector">
      <SelectDropdown
        :searchable="false"
        :options="this.operators"
        :value="this.operator"
        :e2eValue="`e2e-DD-invInventoryFilterCO-option${this.filter.column.id}`"
        @change="updateOperator"
      />
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
import SelectDropdown from '../../shared/select_dropdown.vue';
import DateTimePicker from '../../shared/date_time_picker.vue';

export default {
  name: 'RepositoryDateRangeValue',
  mixins: [FilterMixin, RangeDateTimeFilterMixin],
  data() {
    return {
      timeType: 'date',
      operators: [
        [ 'equal_to', this.i18n.t('repositories.show.repository_filter.filters.operators.date.on') ],
        [ 'greater_than_or_equal_to', this.i18n.t('repositories.show.repository_filter.filters.operators.date.after') ],
        [ 'less_than', this.i18n.t('repositories.show.repository_filter.filters.operators.date.before') ],
        [ 'between', this.i18n.t('repositories.show.repository_filter.filters.operators.between') ],
        [ 'unequal_to', this.i18n.t('repositories.show.repository_filter.filters.operators.date.not_on') ]
      ],
      operator: 'equal_to',
      date: null,
      dateTo: null,
      value: null
    };
  },
  components: {
    SelectDropdown,
    DateTimePicker
  },
  watch: {
    value() {
      this.parameters = this.value;
      this.updateFilter();
    }
  }
};
</script>
