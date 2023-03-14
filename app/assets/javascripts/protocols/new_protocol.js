/* global dropdownSelector HelperModule */
(function() {
  const protocolModal = '#newProtocolModal';
  $(protocolModal)
    .on('change', '#protocol_visibility', function() {
      $('#roleSelectWrapper').toggleClass('hidden', !$(this)[0].checked);
    })
    .on('show.bs.modal', function() {
      $(`${protocolModal} #protocol_name`).parent().removeClass('error');
      $(`${protocolModal} #protocol_name`).val('');
      $(this).find('.sci-input-field').focus();
    });

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
    .on('shown.bs.modal', function() {
      $(this).find('.sci-input-field').focus();
    })
    .on('ajax:error', 'form', function(e, error) {
      let msg = error.responseJSON.error;
      $(`${protocolModal} #protocol_name`).parent().addClass('error').attr('data-error-text', msg);
    })
    .on('ajax:success', 'form', function(e, data) {
      if (data.message) {
        HelperModule.flashAlertMsg(data.message, 'success');
      }
      $(`${protocolModal} #protocol_name`).parent().removeClass('error');
      $(protocolModal).modal('hide');
    });
}());
