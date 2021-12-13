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
        <TimePicker :selectorId="`TimePicker${filter.id}`" @change="updateTime" />
      </div>
    </template>
    <template v-if="operator == 'between'">
      <div class="filter-timepicker-input">
        <TimePicker :selectorId="`TimeFromPicker${filter.id}`" @change="updateTimeRange" />
      </div>
      -
      <div class="filter-timepicker-input">
        <TimePicker :selectorId="`TimeToPicker${filter.id}`" @change="updateTimeRange" />
      </div>
    </template>
  </div>
</template>

<script>
  import FilterMixin from 'vue/repository_filter/mixins/filter.js'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'
  import TimePicker from 'vue/shared/time_picker.vue'

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
        value: ''
      }
    },
    components: {
      DropdownSelector,
      TimePicker
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
        console.log(value)
        this.value = value
        this.updateFilter()
      },
      updateTimeRange() {
        this.value = {
          from: $(`#TimeFromPicker${this.filter.id}`).val(),
          to: $(`#TimeToPicker${this.filter.id}`).val()
        }
        this.updateFilter()
      }
    }
  }
</script>
