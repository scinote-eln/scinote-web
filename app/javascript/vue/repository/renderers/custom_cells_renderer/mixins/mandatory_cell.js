export default {
  data() {
    return {
      touched: false
    };
  },
  computed: {
    mandatory() {
      const { isMandatory, mandatory } = this.params.colDef?.cellRendererParams || {};

      return isMandatory ? !!isMandatory() : !!mandatory;
    },
    showError() {
      return this.mandatory && this.touched && this.isEmpty;
    },
    mandatoryError() {
      return this.i18n.t('repositories.mandatory_column.field_error');
    },
    mandatoryErrorTitle() {
      return !this.params.inSidebar && this.showError ? this.mandatoryError : null;
    }
  },
  methods: {
    touch() {
      this.touched = true;
    },
    blockedByMandatory() {
      this.touch();

      return this.showError && !!this.params.data?.id;
    }
  }
};
