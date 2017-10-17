(function() {
  'use strict';

  $(document).ready(function() {
    $("[data-trigger='about-modal']").on('click', function() {
      $('[data-role=about-modal]').modal('show');
    });
  });
})();
