/* global HelperModule */

export default {
  methods: {
    initWopiFileModal(step, requestCallback) {
      // handle legacy wopi file modal
      let $wopiModal = $('#new-office-file-modal');
      $wopiModal.find('#element_id').val(step.id);
      $wopiModal.find('#element_type').val('Step');
      $wopiModal.modal('show');

      $wopiModal.find('form').on(
        'ajax:success',
        (e, data, status) => {
          if (status === 'success') {
            $wopiModal.modal('hide');
            window.open(data.edit_url, '_blank');
            window.focus();
          } else {
            HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
          }
          requestCallback(e, data, status);
        }
      ).on(
        'ajax:error',
        (e, data, status) => requestCallback(e, data, status)
      );
    }
  }
};
