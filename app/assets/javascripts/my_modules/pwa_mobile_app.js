(function() {
  $('.open-mobile-app-container').on('click', '.dismiss-mobile-app-container', function() {
    $('.open-mobile-app-container').hide();
  });

  // Show banner only on mobile devices
  if ('ontouchstart' in window) {
    $('.open-mobile-app-container').show();
  }
}());
