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
      return (this.operator === 'equal_to' && !this.value) ||
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
  methods: {
    rangeObject(start, end) {
      let range = {};

      range['start_' + this.timeType] = start;
      range['end_' + this.timeType] = end;

      return range;
    },
    currentDate(customOffset = 0) {
      const d = new Date();
      const utc = d.getTime() + (d.getTimezoneOffset() * 60000);
      const offset = $('#filterContainer').data('user-utc-offset');
      const tz = new Date(utc + (1000 * offset) + (1000 * customOffset));
      return tz;
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
