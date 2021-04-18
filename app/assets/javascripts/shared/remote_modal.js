(function () {
  'use strict';

  function initRemoteModalListeners() {
    $(document).on('click', 'a[data-action="remote-modal"]', function(el) {
      el.stopPropagation();
      el.preventDefault();
      $.get(el.target.getAttribute('href')).then(function({modal}) {
        $(modal).modal('show')
                .on("shown.bs.modal", function() {
          $(this).find(".selectpicker").selectpicker();
        })
      })
    })
  }

  $(document).on('turbolinks:load', initRemoteModalListeners);
})();
