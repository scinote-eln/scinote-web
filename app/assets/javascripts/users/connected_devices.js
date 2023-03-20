/* global I18n */

(function() {
  let connectedDeviceDescription = $('.connected-devices-description');
  let revocationModal = $('.device-revocation-modal');
  let deleteButtonModal = $('#confirm-device-remove');

  $('.x-button').on('click', function() {
    deleteButtonModal.attr('href', $(this).data('url'));
    deleteButtonModal.data('id', $(this).closest('.table-row').data('id'));
  });

  deleteButtonModal
    .on('ajax:success', function() {
      $(`.table-row[data-id=${deleteButtonModal.data('id')}]`).remove();

      // Show correct representation if user does not have any connected device anymore
      if (connectedDeviceDescription.find('.table-row').length === 0) {
        $('.connected-devices-container').remove();
        connectedDeviceDescription.append(`<p>${I18n.t('users.registrations.edit.connected_devices.empty_state')}</p>`);
      }

      revocationModal.modal('hide');
    });
}());
