export default {
  props: {
    field: Object,
    marked_as_na: Boolean,
    disabled: Boolean
  },
  computed: {
    fieldDisabled() {
      return this.marked_as_na || this.disabled;
    }
  }
};
