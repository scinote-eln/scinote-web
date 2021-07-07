(function() {
  'use strict';

  function initReplaceFormListeners() {
    $(document).on('ajax:success', 'form[data-action*="replace-form"]', function(_, { form, flash }) {
      let newForm = $(form);
      let target = this.getAttribute('data-target');

      if (target) {
        $(target).replaceWith(newForm);
      } else {
        $(this).replaceWith(newForm);
      }

      newForm.find('.selectpicker').selectpicker();

      if (flash) {
        HelperModule.flashAlertMsg(flash, 'success');
      }
    });
  }

  $(document).one('turbolinks:load', initReplaceFormListeners);
}());
