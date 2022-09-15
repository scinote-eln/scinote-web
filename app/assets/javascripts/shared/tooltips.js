function initBSTooltips() {
  $('[data-toggle="tooltip"]').each(function() {
    $(this).tooltip();
  });
}

(function() {
  $(document).on('turbolinks:load', initBSTooltips);
}());
