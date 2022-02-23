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
  methods: {
    rangeObject(start, end) {
      const range = {};

      range[`start_${this.timeType}`] = this.formattedDate(start);
      range[`end_${this.timeType}`] = this.formattedDate(end);

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
