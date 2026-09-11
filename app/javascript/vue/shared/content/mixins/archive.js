import axios from '../../../../packs/custom_axios.js';

export default {
  methods: {
    archiveElement() {
      axios.post(this.archiveUrl || this.element.urls.archive_url)
        .then((result) => {
          this.$emit(
            'component:archive',
            { id: this.element.id, type: this.element.type }
          );
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response?.data?.error || this.i18n.t('general.archive_error'), 'danger');
        });;
    },
    restoreElement() {
      axios.post(this.restoreUrl || this.element.urls.restore_url)
        .then((result) => {
          this.$emit(
            'component:restore',
            { id: this.element.id, type: this.element.type }
          );

          if(result.data.message) {
            HelperModule.flashAlertMsg(result.data.message, 'success');
          } else {
            HelperModule.flashAlertMsg(this.i18n.t('protocols.steps.modals.restore_modal.restore_element_general',
                                       { content_type: this.element.type }), 'success');
          }
        }).catch((error) => {
          HelperModule.flashAlertMsg(error.response?.data?.error || this.i18n.t('protocols.steps.modals.restore_modal.restore_error'), 'danger');
        });
    }
  }
};
