export default {
  props: {
    field: Object
  },
  watch: {
    editField: {
      handler() {
        if (this.validField) {
          this.$emit('syncField', this.editField);
        }
      },
      deep: true
    }
  },
  computed: {
    validField() {
      return true;
    }
  },
  data() {
    return {
      editField: { ...this.field }
    };
  }
};
