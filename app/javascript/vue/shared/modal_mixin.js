export default {
  mounted() {
    if (!this.startHidden) {
      $(this.$refs.modal).modal('show');
    }

    this.$refs.input?.focus();
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.$emit('close');
    });
  },
  beforeUnmount() {
    $(this.$refs.modal).modal('hide');
  },
  methods: {
    close() {
      this.$emit('close');
      $(this.$refs.modal).modal('hide');
    },
    open() {
      this.$emit('open');
      $(this.$refs.modal).modal('show');
    }
  },
}
