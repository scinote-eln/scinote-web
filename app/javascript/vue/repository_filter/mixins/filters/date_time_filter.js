export default {
  props: {
    filter: Object
  },
  watch: {
    operator() {
      if(this.operator !== 'between') {
        this.dateTo = null;
      }

      if(this.isPreset) {
        this.date = null;
        this.dateTo = null;
        this.value = {}
      } else {
        this.updateValue();
      }
    }
  },
  computed: {
    isBlank() {
      return ((this.operator !== 'between' && !this.isPreset) && (!this.value || !this.value[this.timeType])) ||
             (this.operator === 'between' && (!this.value || (!this.value[`start_${this.timeType}`] || !this.value[`end_${this.timeType}`]))) ||
             (this.filter.column.id === 'archived_on' && $('.repository-show').hasClass('active'));
    },
    isPreset() {
      return [
        'today',
        'yesterday',
        'last_week',
        'this_month',
        'this_year',
        'last_year'
      ].indexOf(this.operator) !== -1;
    }
  },
  created() {
    if (this.timeType === 'time') {
      this.initTimeFromParameters();
    } else {
      this.initDateTimeFromParameters();
    }
  },
  methods: {
    rangeObject(start, end) {
      const range = {};

      range[`start_${this.timeType}`] = start;
      range[`end_${this.timeType}`] = end;

      return range;
    },
    initDateTimeFromParameters() {
      if (this.parameters && this.parameters[`${this.timeType}`]) {
        this.date = this.parameters[`${this.timeType}`];
      } else if (this.parameters && this.parameters[`start_${this.timeType}`]) {
        this.date = this.parameters[`start_${this.timeType}`];
        this.dateTo = this.parameters[`end_${this.timeType}`];
      }
    },
    initTimeFromParameters() {
      if (this.parameters && this.parameters.time) {
        this.date = this.parameters.time;
      } else if (this.parameters && this.parameters.start_time) {
        this.date = this.parameters.start_time;
        this.dateTo = this.parameters.end_time;
      }
    },
    updateDate(date) {
      this.date = date;
      this.updateValue();
    },
    updateDateTo(date) {
      this.dateTo = date;
      this.updateValue();
    },
    updateValue() {
      if (this.dateTo) {
        this.value = this.rangeObject(this.date, this.dateTo);
      } else {
        const valueObject = {};
        valueObject[this.timeType] = this.date;
        this.value = valueObject;
      }
    }
  }
}
