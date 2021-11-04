(function() {
  'use strict';

  function initModalCloseListeners() {
    $(document).on('hidden.bs.modal', '[data-action*="modal-close"]', function({ currentTarget }) {
      let targetPath = currentTarget.getAttribute('data-target');

      if (targetPath) {
        animateSpinner();
        Turbolinks.visit(targetPath);
      }
    });

    $(document).on('ajax:success', 'form[data-action*="modal-close"]', function(_, { form, flash }) {
      $(this).closest('.modal').modal('hide');
      if (flash) {
        HelperModule.flashAlertMsg(flash, 'success');
      }
    });
  }

  $(document).one('turbolinks:load', initModalCloseListeners);
}());
