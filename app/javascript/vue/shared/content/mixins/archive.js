import axios from '../../../../packs/custom_axios.js';

export default {
  methods: {
    archiveElement() {
      axios.post(this.archiveUrl || this.element.attributes.orderable.urls.archive_url)
        .then((result) => {
          this.$emit(
            'component:archive',
            this.element.id
          );
        });
    },
    restoreElement() {
      axios.post(this.restoreUrl || this.element.attributes.orderable.urls.restore_url)
        .then((result) => {
          this.$emit(
            'component:restore',
            this.element.id
          );
          HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.modals.restore_modal.restore_element', { content_type: this.element.attributes.orderable_type }),'success');
        }).catch((error) => {
          HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.modals.restore_modal.restore_error'), 'danger');
        });
    }
  }
};
