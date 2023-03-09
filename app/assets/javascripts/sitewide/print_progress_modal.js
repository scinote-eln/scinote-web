var PrintProgressModal = (function() {
  'use strict';

  function updateProgressModal() {
    var modal = $('.label-printing-progress-modal');

    if (modal.length === 0) return;

    $(document).on('click', '.label-printing-progress-modal .close', function() {
      $(this).closest('.label-printing-progress-modal').remove();
    });

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

  function initialize(data) {
    var modal = $('.label-printing-progress-modal');
    if (modal.length) {
      modal.replaceWith(data.html);
    } else {
      $('body').append($(data.html));
    }

    setTimeout(updateProgressModal, 3000);
  }

  return Object.freeze({
    init: initialize
  });
}());
