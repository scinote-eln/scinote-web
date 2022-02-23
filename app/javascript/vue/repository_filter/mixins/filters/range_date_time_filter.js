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
      if (this.date && this.dateTo) {
        this.value = this.rangeObject(this.date, this.dateTo);
      }
    }
  }
}
