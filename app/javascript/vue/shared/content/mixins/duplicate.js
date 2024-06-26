/* global HelperModule */

export default {
  methods: {
    duplicateElement() {
      this.$emit('component:adding-content', true);
      $.post(this.element.attributes.orderable.urls.duplicate_url, (result) => {
        this.$emit('component:insert', result.data);
        HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.component_duplicated'), 'success');
      }).fail(() => {
        HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.component_duplication_failed'), 'danger');
      }).always(() => {
        this.$emit('component:adding-content', false);
      });
    }
  }
};
