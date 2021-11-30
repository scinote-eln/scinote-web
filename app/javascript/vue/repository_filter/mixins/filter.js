export default {
  props: {
    filter: Object
  },
  created() {
    this.operator = this.operator || this.filter.data.operator;
    this.value = this.value || this.filter.data.value;
  },
  methods: {
    updateOperator(operator) {
      this.operator = operator;
      this.updateFilter();
    },
    updateFilter() {
      this.$emit(
        'filter:update',
        {
          id: this.filter.id,
          isBlank: this.isBlank,
          data: {
            operator: this.operator,
            value: this.value
          }
        }
      );
    }
  }
}
