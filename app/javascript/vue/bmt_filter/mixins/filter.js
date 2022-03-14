export default {
  props: {
    currentData: Object
  },
  data() {
    return {
      type: this.$options.name
    }
  },
  created() {
    // load existing filter data
    Object.keys(this.currentData).forEach((key) => { this[key] = this.currentData[key] });
  },
  methods: {
    updateFilterData() {
      this.$emit('filter:updateData', this.$data);
    }
  }
}
