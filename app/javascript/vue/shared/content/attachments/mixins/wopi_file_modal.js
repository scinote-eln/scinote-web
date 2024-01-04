/* global HelperModule animateSpinner renderFormError I18n */

const FILENAME_MAX_LENGTH = 100;

export default {
  methods: {
    initWopiFileModal(object, requestCallback) {
      // handle legacy wopi file modal
      let $wopiModal = $('#new-office-file-modal');
      $wopiModal.find('#element_id').val(object.id);
      $wopiModal.find('#element_type').val(object.attributes.type);
      $wopiModal.modal('show');
      $($wopiModal).find('#new-wopi-file-name').focus().val('');

      // Clear filename input error on input change if appropriate
      $wopiModal.on('input', '#new-wopi-file-name', (e) => {
        if (e.currentTarget.value.length <= FILENAME_MAX_LENGTH) {
          $wopiModal.clearFormErrors();
        }
      });

      $wopiModal.find('form').on('submit', () => {
        animateSpinner(null, true);
      })
        .on(
          'ajax:success',
          (e, data, status) => {
            animateSpinner(null, false);
            if (status === 'success') {
              $wopiModal.modal('hide');
              $wopiModal.find('form').off('submit');
              $wopiModal.find('form').off('ajax:success');
              window.open(data.data.attributes.urls.edit_asset, '_blank');
              window.focus();
            } else {
              HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
            }
            requestCallback(e, data, status);
          }
        )
        .on('ajax:error', function(ev, response) {
          let element;
          let msg;

          animateSpinner(null, false);
          $(this).clearFormErrors();

          if (response.status === 400) {
            element = $(this).find('#new-wopi-file-name');
            msg = response.responseJSON.message.file.toString();
          } else if (response.status === 403) {
            element = $(this).find('#other-wopi-errors');
            msg = I18n.t('assets.create_wopi_file.errors.forbidden');
          } else if (response.status === 404) {
            element = $(this).find('#other-wopi-errors');
            msg = I18n.t('assets.create_wopi_file.errors.not_found');
          }
          renderFormError(undefined, element, msg);
        });
    }
  }
};
