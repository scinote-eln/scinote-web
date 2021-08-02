function updateProgressModal() {
  var status;
  var modal = $(document).find('.label-printing-progress-modal');

  if (modal.length === 0) {
    return;
  }

  $.getJSON(
    `/label_printers/${modal.data('labelPrinterId')}/update_progress_modal`
    + `?starting_item_count=${modal.data('startingItemCount')}`,
    function(data) {
      modal.replaceWith(data.html);

      status = modal.data('label-printer-status');
      if (status !== 'done' && status !== 'error') {
        setTimeout(updateProgressModal, 3000);
      }
    }
  );
}

$(document).on('click', '.label-printing-progress-modal .close', function() {
  $(this).closest('.label-printing-progress-modal').remove();
});

$(document).on('turbolinks:load', function() {
  var modal = $(document).find('.label-printing-progress-modal');
  if (modal.length > 0) {
    updateProgressModal();
  }
});
