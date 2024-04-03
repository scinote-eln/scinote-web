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
      <div class="filter-datepicker-input">
        <DateTimePicker @change="updateDate"
                        :data-e2e="`e2e-TP-invInventoryFilterCO-input${this.filter.column.id}`"
                        :selectorId="`TimePicker${filter.id}`"
                        :mode="'time'"
                        :defaultValue="date" />
      </div>
      <span class="between-delimiter" v-if="operator == 'between'">—</span>
      <div class="filter-datepicker-to-input" v-if="operator == 'between'">
        <DateTimePicker @change="updateDateTo"
                        :data-e2e="`e2e-TP-invInventoryFilterCO-inputUpdate${this.filter.column.id}`"
                        :selectorId="`TimePickerTo${filter.id}`"
                        :mode="'time'"
                        :defaultValue="dateTo" />
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
  name: 'RepositoryTimeValue',
  mixins: [FilterMixin, DateTimeFilterMixin],
  data() {
    return {
      timeType: 'time',
      operators: [
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
      return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    }
  }
};
</script>
