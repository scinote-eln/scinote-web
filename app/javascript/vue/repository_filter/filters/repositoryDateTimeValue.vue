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
    <template v-if="!isPreset">
      <div class="datetime-filter-attributes">
        <div class="filter-datepicker-input">
          <DateTimePicker @change="updateDate"
                          :data-e2e="`e2e-DP-invInventoryFilterCO-input${this.filter.column.id}`"
                          :selectorId="`DatePicker${filter.id}`"
                          :defaultValue="date" />
        </div>
        <div class="between-delimiter vertical" v-if="operator == 'between'"></div>
        <div class="filter-datepicker-to-input">
          <DateTimePicker @change="updateDateTo"
                          :data-e2e="`e2e-DP-invInventoryFilterCO-inputUpdate${this.filter.column.id}`"
                          v-if="operator == 'between'"
                          :selectorId="`DatePickerTo${filter.id}`"
                          :defaultValue="dateTo" />
        </div>
      </div>
    </template>
  </div>
</template>

<script>
import FilterMixin from '../mixins/filter.js';
import DateTimeFilterMixin from '../mixins/filters/date_time_filter.js';
import DropdownSelector from '../../shared/legacy/dropdown_selector.vue';
import DateTimePicker from '../../shared/date_time_picker.vue';

export default {
  name: 'RepositoryDateValue',
  mixins: [FilterMixin, DateTimeFilterMixin],
  data() {
    return {
      timeType: 'datetime',
      operators: [
        {
          value: 'today',
          label: this.i18n.t('repositories.show.repository_filter.filters.operators.today'),
          params: {
            tooltip: this.i18n.t('repositories.show.repository_filter.filters.operators.tooltips.today')
          }
        },
        {
          value: 'yesterday',
          label: this.i18n.t('repositories.show.repository_filter.filters.operators.yesterday'),
          params: {
            tooltip: this.i18n.t('repositories.show.repository_filter.filters.operators.tooltips.yesterday')
          }
        },
        {
          value: 'last_week',
          label: this.i18n.t('repositories.show.repository_filter.filters.operators.last_week'),
          params: {
            tooltip: this.i18n.t('repositories.show.repository_filter.filters.operators.tooltips.last_week')
          }
        },
        {
          value: 'this_month',
          label: this.i18n.t('repositories.show.repository_filter.filters.operators.this_month'),
          params: {
            tooltip: this.i18n.t('repositories.show.repository_filter.filters.operators.tooltips.this_month')
          }
        },
        {
          value: 'this_year',
          label: this.i18n.t('repositories.show.repository_filter.filters.operators.this_year'),
          params: {
            tooltip: this.i18n.t('repositories.show.repository_filter.filters.operators.tooltips.this_year')
          }
        },
        {
          value: 'last_year',
          label: this.i18n.t('repositories.show.repository_filter.filters.operators.last_year'),
          params: {
            tooltip: this.i18n.t('repositories.show.repository_filter.filters.operators.tooltips.last_year')
          }
        },
        { value: '', label: '', params: { delimiter: true } },
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
      return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    }
  }
};
</script>
