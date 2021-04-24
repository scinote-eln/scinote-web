(function () {
  'use strict';

  function initReplaceFormListeners() {
    $(document).on('ajax:success', 'form[data-action="replace-form"]', function({ form }) {
      let newForm = $(form)
      $(this).replaceWith(newForm);
      newForm.find('.selectpicker').selectpicker();
    })
  }

  $(document).one('turbolinks:load', initReplaceFormListeners);
})();
