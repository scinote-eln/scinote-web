$(document).on('click', '.label-printing-progress-modal .close', function() {
  $(this).parent().parent().remove();
});

$(document).on('turbolinks:load', function() {
  var modal = $(document).find('.label-printing-progress-modal');
  if (modal.length > 0) {
    window.printerModalReloadInterval = setInterval(function() {
      modal = $(document).find('.label-printing-progress-modal');

      if (modal.length === 0) {
        clearInterval(window.printerModalReloadInterval);
        return;
      }
      $.getJSON(
        `/label_printers/${modal.data('labelPrinterId')}/update_progress_modal`
        + `?starting_item_count=${modal.data('startingItemCount')}`,
        function(data) { modal.replaceWith(data.html); }
      );
    }, 3000);
  } else if (window.printerModalReloadInterval) {
    clearInterval(window.printerModalReloadInterval);
  }
});
