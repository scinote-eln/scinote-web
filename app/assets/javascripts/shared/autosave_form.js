(function () {
  'use strict';

  function initAutosaveListeners() {
    $(document).on('change', 'form[data-action="autosave-form"]', function({ currentTarget }) {
      currentTarget.submit()
    })
  }

  $(document).on('turbolinks:load', initAutosaveListeners);
})();
