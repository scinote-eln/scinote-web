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
      }
    }
  },
  computed: {
    isBlank() {
      return this.operator === 'equal_to' && !this.value;
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
  methods: {
    rangeObject(start, end) {
      let range = {};

      range['start_' + this.timeType] = start;
      range['end_' + this.timeType] = end;

      return range;
    },
    updateDate(date) {
      date = date && this.formattedDate(date);
      this.date = date;
      if (this.dateTo) {
        this.value = this.rangeObject(date, this.dateTo);
      } else {
        let valueObject = {};
        valueObject[this.timeType] = date;

        this.value = valueObject;
      }
    },
    updateDateTo(date) {
      date = date && this.formattedDate(date);
      this.dateTo = date;
      this.value = this.rangeObject(this.date, date);
    }
  }
}
