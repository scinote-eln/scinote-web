(function() {
  'use strict';

  function initAutosaveListeners() {
    $(document).on('change', 'form[data-action*="autosave-form"]', function({ currentTarget }) {
      $.rails.fire($(currentTarget), 'submit');
    });
  }

  $(document).one('turbolinks:load', initAutosaveListeners);
}());
