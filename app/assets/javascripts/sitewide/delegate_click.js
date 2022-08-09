$(document).on('click', '[data-click-target]', function() {
  $($(this).data('clickTarget')).click();
});
