/* global dropdownSelector HelperModule */
(function() {
  const protocolModal = '#newProtocolModal';
  const submitButton = $('.create-protocol-button');

  let roleSelector = `${protocolModal} #protocol_role_selector`;
  dropdownSelector.init(roleSelector, {
    noEmptyOption: true,
    singleSelect: true,
    closeOnSelect: true,
    selectAppearance: 'simple',
    onChange: function() {
      $('#protocol_default_public_user_role_id').val(dropdownSelector.getValues(roleSelector));
    }
  });

  $(protocolModal)
    .on('change', '#protocol_visibility', function() {
      let checked = $(this)[0].checked;
      $('#roleSelectWrapper').toggleClass('hidden', !checked);
      $('#protocol_default_public_user_role_id').prop('disabled', !checked);
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
