/* global animateSpinner */

(function() {
  $('#statusFlowModal').on('show.bs.modal', function() {
    var $modalBody = $(this).find('.modal-body');
    animateSpinner($modalBody);
    $.get($(this).data('status-flow-url'), function(result) {
      animateSpinner($modalBody, false);
      $modalBody.html(result.html);
    });
  });
}());
