/* global dropdownSelector HelperModule */
(function() {
  $('#newProtocolModal').on('change', '#protocol_visibility', function() {
    $('#roleSelectWrapper').toggleClass('hidden', !$(this)[0].checked);
  });

  let roleSelector = '#newProtocolModal #protocol_role_selector';
  dropdownSelector.init(roleSelector, {
    noEmptyOption: true,
    singleSelect: true,
    closeOnSelect: true,
    selectAppearance: 'simple',
    onChange: function() {
      $('#protocol_default_public_user_role_id').val(dropdownSelector.getValues(roleSelector));
    }
  });

  $('#newProtocolModal')
    .on('ajax:error', 'form', function(e, error) {
      let msg = error.responseJSON.error;
      $('#newProtocolModal #protocol_name').parent().addClass('error').attr('data-error-text', msg);
    })
    .on('ajax:success', 'form', function(e, data) {
      if (data.message) {
        HelperModule.flashAlertMsg(data.message, 'success');
      }
      $('#newProtocolModal #protocol_name').parent().removeClass('error');
      $('#newProtocolModal').modal('hide');
    });
}());
