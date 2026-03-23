/* global HelperModule */

export default {
  methods: {
    duplicateElement() {
      this.$emit('component:adding-content', true);
      axios.post(this.element.attributes.orderable.urls.duplicate_url)
        .then((result) => {
          this.$emit('component:insert', result.data.data);
          HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.component_duplicated'), 'success');
        })
        .catch(() => {
          HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.component_duplication_failed'), 'danger');
        })
        .finally(() => {
          this.$emit('component:adding-content', false);
        });
    }
  }
};
