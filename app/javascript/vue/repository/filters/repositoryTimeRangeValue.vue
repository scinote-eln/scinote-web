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
                      :data-e2e="`e2e-TP-invInventoryFilterCO-inputFrom${this.filter.column.id}`"
                      :selectorId="`TimePicker${filter.id}`"
                      :mode="'time'"
                      :defaultValue="date" />
    </div>
    <span class="between-delimiter">—</span>
    <div class="filter-datepicker-to-input">
      <DateTimePicker @change="updateDateTo"
                      :data-e2e="`e2e-TP-invInventoryFilterCO-inputTo${this.filter.column.id}`"
                      :selectorId="`TimePickerTo${filter.id}`"
                      :mode="'time'"
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
  name: 'RepositoryTimeRangeValue',
  mixins: [FilterMixin, RangeDateTimeFilterMixin],
  data() {
    return {
      timeType: 'time',
      operators: [
        [ 'equal_to', this.i18n.t('repositories.show.repository_filter.filters.operators.equal_to') ],
        [ 'unequal_to', this.i18n.t('repositories.show.repository_filter.filters.operators.unequal_to') ],
        [ 'greater_than', this.i18n.t('repositories.show.repository_filter.filters.operators.greater_than') ],
        [ 'greater_than_or_equal_to', this.i18n.t('repositories.show.repository_filter.filters.operators.greater_than_or_equal_to') ],
        [ 'less_than', this.i18n.t('repositories.show.repository_filter.filters.operators.less_than') ],
        [ 'less_than_or_equal_to', this.i18n.t('repositories.show.repository_filter.filters.operators.less_than_or_equal_to') ],
        [ 'between', this.i18n.t('repositories.show.repository_filter.filters.operators.between') ]
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
  },
  methods: {
    formattedDate(date) {
      if (!date) return null;
      return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    }
  }
};
</script>
