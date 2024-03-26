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

      range[`start_${this.timeType}`] = this.formattedDate(start);
      range[`end_${this.timeType}`] = this.formattedDate(end);

      return range;
    },
    dateTimeFromTimeString(timeString) {
      let dateTime = new Date();

      dateTime.setHours(timeString.split(':')[0]);
      dateTime.setMinutes(timeString.split(':')[1]);

      return dateTime;
    },
    initDateTimeFromParameters() {
      if (this.parameters && this.parameters[`${this.timeType}`]) {
        this.date = new Date(this.parameters[`${this.timeType}`]);
      } else if (this.parameters && this.parameters[`start_${this.timeType}`]) {
        this.date = new Date(this.parameters[`start_${this.timeType}`]);
        this.dateTo = new Date(this.parameters[`end_${this.timeType}`]);
      }
    },
    initTimeFromParameters() {
      if (this.parameters && this.parameters.time) {
        this.date = this.dateTimeFromTimeString(this.parameters.time);
      } else if (this.parameters && this.parameters.start_time) {
        this.date = this.dateTimeFromTimeString(this.parameters.start_time);
        this.dateTo = this.dateTimeFromTimeString(this.parameters.end_time);
      }
    },
    updateDate(date) {
      if (this.date && date && (this.date.setSeconds(0, 0) === date.setSeconds(0, 0))) {
        return;
      }
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
        valueObject[this.timeType] = this.formattedDate(this.date);
        this.value = valueObject;
      }
    }
  }
}
