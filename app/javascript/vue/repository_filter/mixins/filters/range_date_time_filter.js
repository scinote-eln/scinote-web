export default {
  props: {
    filter: Object
  },
  watch: {
    operator() {
      this.updateValue();
    }
  },
  computed: {
    isBlank() {
      return !this.value || !this.value[`start_${this.timeType}`] || !this.value[`end_${this.timeType}`];
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
      if (this.parameters && this.parameters[`start_${this.timeType}`]) {
        this.date = new Date(this.parameters[`start_${this.timeType}`]);
        this.dateTo = new Date(this.parameters[`end_${this.timeType}`]);
      }
    },
    initTimeFromParameters() {
      if (this.parameters && this.parameters.start_time) {
        this.date = this.dateTimeFromTimeString(this.parameters.start_time);
        this.dateTo = this.dateTimeFromTimeString(this.parameters.end_time);
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
      this.value = this.rangeObject(this.date, this.dateTo);
    }
  }
}
