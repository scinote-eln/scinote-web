export default {
  props: {
    field: Object,
    marked_as_na: Boolean,
    disabled: Boolean,
    assignableMyModuleId: {
      type: Number,
      default: null
    }
  },
  watch: {
    validValue() {
      this.$emit('validChanged');
    }
  },
  computed: {
    fieldDisabled() {
      return this.marked_as_na || this.disabled;
    }
  }
};
