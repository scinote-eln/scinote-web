(function () {
  'use strict';

  function initRemoteModalListeners() {
    $(document).on('click', 'a[data-action="remote-modal"]', function(ev) {
      ev.stopImmediatePropagation();
      ev.stopPropagation();
      ev.preventDefault();
      $.get(ev.currentTarget.getAttribute('href')).then(function({modal}) {
        $(modal).modal('show')
                .on("shown.bs.modal", function() {
          $(this).find(".selectpicker").selectpicker();
        });
      });
    });
  }

  $(document).one('turbolinks:load', initRemoteModalListeners);
}());
