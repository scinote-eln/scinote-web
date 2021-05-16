(function() {
  'use strict';

  function initModalCloseListeners() {
    $(document).on('hidden.bs.modal', '[data-action*="modal-close"]', function({ currentTarget }) {
      let targetPath = currentTarget.getAttribute('data-target');
      animateSpinner();
      Turbolinks.visit(targetPath);
    });
  }

  $(document).one('turbolinks:load', initModalCloseListeners);
}());
