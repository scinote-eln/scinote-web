/* global GLOBAL_CONSTANTS */

export default {
  data() {
    return {
      options: this.field.attributes.data.options?.join('\n')
    };
  },
  computed: {
    validField() {
      return !this.editField.attributes.data.options || this.editField.attributes.data.options.length <= GLOBAL_CONSTANTS.NAME_MAX_LENGTH;
    },
    optionFieldErrors() {
      if (!this.validField) {
        return this.i18n.t('forms.show.options_too_many_error');
      }

      return '';
    }
  },
  watch: {
    options() {
      const newOptions = this.options.split('\n')
        .filter((option) => option.trim() !== '')
        .map((option) => option.trim());
      // remove duplicates
      const uniqueOptions = [...new Set(newOptions)];

      this.editField.attributes.data.options = uniqueOptions;
    }
  }
};
