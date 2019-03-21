// Opens create wopi modal on the click of the button
function applyCreateWopiFileCallback()  {
  $(".create-wopi-file-btn").off().on('click', function(e){
    var $modal = $('#new-office-file-modal');
    $($modal).find('form').clearFormErrors();
    $($modal).find('#new-wopi-file-name').val('');

    // Append element info to which the new file will be attached
    $modal.find('#element_id').val($(this).data('id'));
    $modal.find('#element_type').val($(this).data('type'));
    $modal.modal('show');

    return false;
  });
}

// Show errors on create wopi modal
function initCreateWopiFileModal() {
  // Ajax actions
  $("#new-office-file-modal form")
    .on('ajax:success', function(ev, data) {
      window.open(data.edit_url, '_blank');
      $('#new-office-file-modal').modal('hide');

      //location.reload();
    })
    .on('ajax:error', function(ev, response) {
      $(this).clearFormErrors();
      var element, msg;

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

function applyImageChangeOnButtons() {
  var modal = $('#new-office-file-modal');
  modal.find('.btn-group label').off().click(function() {
    modal.find('img.act').hide();
    modal.find('img.inactive').show();

    $(this).find('img.act').show();
    $(this).find('img.inactive').hide();
  });

  // Set default value
  modal.find('label#word-btn').click();
}

$(document).ready(function() {
  initCreateWopiFileModal();
  applyImageChangeOnButtons();
});
