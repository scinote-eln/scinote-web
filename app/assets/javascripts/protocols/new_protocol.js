/* global dropdownSelector HelperModule GLOBAL_CONSTANTS */
(function() {
  const protocolModal = '#newProtocolModal';
  const submitButton = $('.create-protocol-button');

  $(protocolModal)
    .on('input', '#protocol_name', function() {
      if ($(this).val().length >= GLOBAL_CONSTANTS.NAME_MIN_LENGTH) {
        submitButton.removeAttr('disabled');
      } else {
        submitButton.attr('disabled', 'disabled');
      }
    })
    .on('submit', function() {
      submitButton.attr('disabled', 'disabled');
    })
    .on('shown.bs.modal', function() {
      $(`${protocolModal} #protocol_name`).parent().removeClass('error');
      $(`${protocolModal} #protocol_name`).val('');
      const protocolName = $(`a[data-target="${protocolModal}"]`).attr('data-protocol-name');
      if (protocolName) {
        $(this).find('.sci-input-field').val(protocolName);
      }
      $(this).find('.sci-input-field').focus();
    })
    .on('ajax:error', 'form', function(e, error) {
      let msg = error.responseJSON.error;
      submitButton.attr('disabled', false);
      $(`${protocolModal} #protocol_name`).parent().addClass('error').attr('data-error-text', msg);
    })
    .on('ajax:success', 'form', function(e, data) {
      if (data.message) {
        HelperModule.flashAlertMsg(data.message, 'success');
      }
      $(`${protocolModal} #protocol_name`).parent().removeClass('error');
      submitButton.attr('disabled', false);
      $(protocolModal).modal('hide');
    });
}());
