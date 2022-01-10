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
    this.operator = this.filter.data.operator || this.operator;
    this.parameters = this.filter.data.parameters || this.parameters;

    // load value from parameters
    const keys = Object.keys(this.parameters);
    if (keys.length) {
      this.value = keys.length == 1 ? this.parameters[keys[0]] : { ...this.parameters };
    }
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
