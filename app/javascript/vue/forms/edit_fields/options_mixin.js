export default {
  data() {
    return {
      options: this.field.attributes.data.options?.join('\n')
    };
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
