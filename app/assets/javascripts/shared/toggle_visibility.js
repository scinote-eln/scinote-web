(function() {
  'use strict';

  function initToggleVisibilityListeners() {
    $(document).on('change', 'input[data-action="toggle-visibility"]', function({ currentTarget }) {
      let toggleId = currentTarget.getAttribute('data-target');
      let element = document.getElementById(toggleId);

      if (currentTarget.checked) {
        element.classList.remove('hidden');
      } else {
        element.classList.add('hidden');
      }
    });
  }

  $(document).one('turbolinks:load', initToggleVisibilityListeners);
}());
