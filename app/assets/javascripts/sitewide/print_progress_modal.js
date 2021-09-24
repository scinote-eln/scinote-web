(function() {
  function updateProgressModal() {
    var modal = $('.label-printing-progress-modal');

    if (modal.length === 0) return;

    $.getJSON(
      modal.data('progress-url'), function(data) {
        modal.replaceWith(data.html);
        let status = modal.data('label-printer-status');
        if (!['done', 'error'].includes(status)) {
          setTimeout(updateProgressModal, 3000);
        }
      }
    );
  }

  $(document).on('click', '.label-printing-progress-modal .close', function() {
    $(this).closest('.label-printing-progress-modal').remove();
  });

  $(document).on('ajax:success', '.print-label-form', function(e, data) {
    var modal = $('.label-printing-progress-modal');
    if (modal.length) {
      modal.replaceWith(data.html);
    } else {
      $('body').append($(data.html));
    }

    updateProgressModal();
    $('#modal-print-repository-row-label').modal('hide');
  });
}());
