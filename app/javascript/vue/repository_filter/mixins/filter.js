export default {
  props: {
    filter: Object,
    my_modules: Array
  },
  data() {
    return {
      parameters: {}
    };
  },
  created() {
    this.operator = this.operator || this.filter.data.operator;
    this.parameters = this.parameters || this.filter.data.parameters;

    // load value from parameters
    const keys = Object.keys(this.parameters);
    this.value = keys.length <= 1 ? this.parameters[keys[0]] : { ...this.parameters };
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
            parameters: this.parameters
          }
        }
      );
    }
  }
}
