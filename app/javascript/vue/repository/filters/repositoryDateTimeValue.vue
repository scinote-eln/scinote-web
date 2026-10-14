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
import SelectDropdown from '../../shared/select_dropdown.vue';
import DateTimePicker from '../../shared/date_time_picker.vue';

export default {
  name: 'RepositoryDateValue',
  mixins: [FilterMixin, DateTimeFilterMixin],
  data() {
    return {
      timeType: 'datetime',
      operators: [
        [
          'today',
          this.i18n.t('repositories.show.repository_filter.filters.operators.today'),
          {
            tooltip: this.i18n.t('repositories.show.repository_filter.filters.operators.tooltips.today')
          }
        ],
        [
          'yesterday',
          this.i18n.t('repositories.show.repository_filter.filters.operators.yesterday'),
          {
            tooltip: this.i18n.t('repositories.show.repository_filter.filters.operators.tooltips.yesterday')
          }
        ],
        [
          'last_week',
          this.i18n.t('repositories.show.repository_filter.filters.operators.last_week'),
          {
            tooltip: this.i18n.t('repositories.show.repository_filter.filters.operators.tooltips.last_week')
          }
        ],
        [
          'this_month',
          this.i18n.t('repositories.show.repository_filter.filters.operators.this_month'),
          {
            tooltip: this.i18n.t('repositories.show.repository_filter.filters.operators.tooltips.this_month')
          }
        ],
        [
          'this_year',
          this.i18n.t('repositories.show.repository_filter.filters.operators.this_year'),
          {
            tooltip: this.i18n.t('repositories.show.repository_filter.filters.operators.tooltips.this_year')
          }
        ],
        [
          'last_year',
          this.i18n.t('repositories.show.repository_filter.filters.operators.last_year'),
          {
            tooltip: this.i18n.t('repositories.show.repository_filter.filters.operators.tooltips.last_year')
          }
        ],
        [
          'equal_to',
          this.i18n.t('repositories.show.repository_filter.filters.operators.date.on')
        ],
        [
          'greater_than_or_equal_to',
          this.i18n.t('repositories.show.repository_filter.filters.operators.date.after')
        ],
        [
          'less_than',
          this.i18n.t('repositories.show.repository_filter.filters.operators.date.before')
        ],
        [
          'between',
          this.i18n.t('repositories.show.repository_filter.filters.operators.between')
        ],
        [
          'unequal_to',
          this.i18n.t('repositories.show.repository_filter.filters.operators.date.not_on')
        ]
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
