(function() {
  'use strict';

  $(document).ready(function() {
    $("[data-trigger='about-modal']").on('click', function(ev) {
      $('[data-role=about-modal]').modal('show');
      ev.preventDefault();
    });
  });
})();
