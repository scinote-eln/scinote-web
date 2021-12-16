export default {
  props: {
    filter: Object
  },
  watch: {
    operator() {
      if(this.operator !== 'between') {
        this.dateTo = null;
      }

      let date = null;
      let dateTo = null;

      let today = new Date();

      switch (this.operator) {
        case 'today':
          date = today;
          dateTo = today;
          break;
        case 'yesterday':
          date = new Date(new Date().setDate(today.getDate() - 1));
          dateTo = date;
          break;
        case 'last_week':
          let monday = new Date(new Date().setDate(
            today.getDate() - today.getDay() - (today.getDay() === 0 ? 6 : -1))
          );
          let lastWeekEnd = new Date(new Date().setDate(monday.getDate() - 1));
          let lastWeekStart = new Date(new Date().setDate(monday.getDate() - 7));
          date = lastWeekStart;
          dateTo = lastWeekEnd;
          break;
        case 'this_month':
          date = new Date(today.getFullYear(), today.getMonth(), 1);
          dateTo = today;
          break;
        case 'this_year':
          date = new Date(new Date().getFullYear(), 0, 1);
          dateTo = today;
          break;
        case 'last_year':
          date = new Date(new Date().getFullYear() - 1, 0, 1);
          dateTo = new Date(new Date().getFullYear() - 1, 11, 31);
          break;
      }

      date && this.updateDate(new Date(date.setHours(0, 0, 0)));
      dateTo && this.updateDateTo(new Date(dateTo.setHours(23, 59, 59)));
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
