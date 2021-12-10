<template>
  <div class="filter-attributes">
    <div class="filter-operator-select">
      <DropdownSelector
      :disableSearch="true"
      :options="operators"
      :selectorId="`OperatorSelector${filter.id}`"
      :selectedValue="operator"
      @dropdown:changed="updateOperator" />
    </div>
    <template v-if="!isPreset">
      <div class="filter-datepicker-input">
        <DateTimePicker @change="updateDate" :selectorId="`DateTimePicker${filter.id}`" />
      </div>
      <div class="filter-datepicker-to-input">
        <DateTimePicker @change="updateDateTo" v-if="operator == 'between'" :selectorId="`DateTimePickerTo${filter.id}`" />
      </div>
    </template>
  </div>
</template>

<script>
  import FilterMixin from 'vue/repository_filter/mixins/filter.js'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'
  import DateTimePicker from 'vue/shared/date_time_picker.vue'

  export default {
    name: 'RepositoryAssetValue',
    mixins: [FilterMixin],
    props: {
      filter: Object
    },
    data() {
      return {
        operators: [
          { value: 'today', label: this.i18n.t('repositories.show.repository_filter.filters.operators.today') },
          { value: 'yesterday', label: this.i18n.t('repositories.show.repository_filter.filters.operators.yesterday') },
          { value: 'last_week', label: this.i18n.t('repositories.show.repository_filter.filters.operators.last_week') },
          { value: 'this_month', label: this.i18n.t('repositories.show.repository_filter.filters.operators.this_month') },
          { value: 'this_year', label: this.i18n.t('repositories.show.repository_filter.filters.operators.this_year') },
          { value: 'last_year', label: this.i18n.t('repositories.show.repository_filter.filters.operators.last_year') },
          { value: 'equal', label: this.i18n.t('repositories.show.repository_filter.filters.operators.equal_to') },
          { value: 'not_equal', label: this.i18n.t('repositories.show.repository_filter.filters.operators.unequal_to') },
          { value: 'greater_than', label: this.i18n.t('repositories.show.repository_filter.filters.operators.greater_than') },
          { value: 'greater_than_or_equal', label: this.i18n.t('repositories.show.repository_filter.filters.operators.greater_than_or_equal_to') },
          { value: 'less_than', label: this.i18n.t('repositories.show.repository_filter.filters.operators.less_than') },
          { value: 'less_than_or_equal', label: this.i18n.t('repositories.show.repository_filter.filters.operators.less_than_or_equal_to') },
          { value: 'between', label: this.i18n.t('repositories.show.repository_filter.filters.operators.between') }
        ],
        operator: 'equal',
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
      operator() {
        if(this.operator != 'between') {
          this.dateTo = null;
        }

        let date = null;
        let dateTo = null;

        let today = new Date();

        switch(this.operator) {
          case "today":
            date = today;
            break;
          case "yesterday":
            date = new Date(new Date().setDate(today.getDate() - 1));
            break;
          case "last_week":
            let monday = new Date(new Date().setDate(
              today.getDate() - today.getDay() - (today.getDay() === 0 ? 6 : -1))
            );
            let lastWeekEnd = new Date(new Date().setDate(monday.getDate() - 1));
            let lastWeekStart = new Date(new Date().setDate(monday.getDate() - 7));
            date = lastWeekStart;
            dateTo = lastWeekEnd;
            break;
          case "this_month":
            date = new Date(today.getFullYear(), today.getMonth(), 1);
            dateTo = today;
            break;
          case "this_year":
            date = new Date(new Date().getFullYear(), 0, 1);
            dateTo = today;
            break;
          case "last_year":
            date = new Date(new Date().getFullYear() - 1, 0, 1);
            dateTo = new Date(new Date().getFullYear() - 1, 11, 31);
            break;
        }

        date && this.updateDate(date);
        dateTo && this.updateDateTo(dateTo);
      }
    },
    computed: {
      isBlank(){
        return !this.value;
      },
      isPreset() {
        return [
          "today",
          "yesterday",
          "last_week",
          "this_month",
          "this_year",
          "last_year"
        ].indexOf(this.operator) != -1
      }
    },
    methods: {
      formattedDate(date) {
        return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`
      },
      updateDate(date) {
        date = date && this.formattedDate(date);
        this.date = date;
        if(this.dateTo) {
          this.value = {
            from_date: date,
            to_date: this.dateTo
          }
        } else {
          this.value = date
        }

        this.updateFilter();
      },
      updateDateTo(date) {
        date = date && this.formattedDate(date);
        this.dateTo = date;
        this.value = {
          from_date: this.date,
          to_date: date
        }

        this.updateFilter();
      }
    }
  }
</script>
