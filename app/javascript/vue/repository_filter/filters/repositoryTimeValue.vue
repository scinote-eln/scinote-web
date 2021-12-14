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
    <template v-if="operator !== 'between'" >
      <div class="filter-timepicker-input">
        <DateTimePicker :selectorId="`TimePicker${filter.id}`" @change="updateTime" :timeOnly="true" />
      </div>
    </template>
    <template v-if="operator == 'between'">
      <div class="filter-timepicker-input">
        <DateTimePicker :selectorId="`TimeFromPicker${filter.id}`" @change="updateTimeFrom" :timeOnly="true" />
      </div>
      -
      <div class="filter-timepicker-input">
        <DateTimePicker :selectorId="`TimeToPicker${filter.id}`" @change="updateTimeTo" :timeOnly="true" />
      </div>
    </template>
  </div>
</template>

<script>
  import FilterMixin from 'vue/repository_filter/mixins/filter.js'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'
  import DateTimePicker from 'vue/shared/date_time_picker.vue'

  export default {
    name: 'RepositoryTimeValue',
    mixins: [FilterMixin],
    props: {
      filter: Object
    },
    data() {
      return {
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
        value: '',
        from: '',
        to: '',
      }
    },
    components: {
      DropdownSelector,
      DateTimePicker
    },
    watch: {
      operator() {
        if(this.operator !== 'between' && !(typeof this.value === 'string')) this.value = '';
        if(this.operator === 'between') this.value = {to: '', from: ''};

      }
    },
    computed: {
      isBlank(){
        return this.operator == 'equal_to' && !this.value;
      }
    },
    methods: {
      updateTime(value) {
        this.value = value

        this.updateFilter()
      },
      updateTimeFrom(value) {
        this.from = value;
        this.updateTimeRange();
      },
      updateTimeTo(value) {
        this.to = value;
        this.updateTimeRange();
      },
      updateTimeRange() {
        this.value = {
          from: this.from,
          to: this.to
        }
        this.updateFilter()
      }
    }
  }
</script>
