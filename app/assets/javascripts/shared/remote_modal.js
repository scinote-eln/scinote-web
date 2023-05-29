/* global animateSpinner ProtocolsIndex ProjectsIndex ShareModal */
(function() {
  'use strict';

  function initRemoteModalListeners() {
    $(document).on('click', 'a[data-action="remote-modal"]', function(ev) {
      ev.stopImmediatePropagation();
      ev.stopPropagation();
      ev.preventDefault();

      animateSpinner();
      $.get(ev.currentTarget.getAttribute('href')).then(function({ modal, html }) {
        $(modal || html)
          .on('shown.bs.modal', function() {
            if ($(this).hasClass('project-assignments-modal')) {
              $(this).on('ajax:success', 'form', function() {
                ProjectsIndex.loadCardsView();
              });
            }
            if ($(this).hasClass('protocol-assignments-modal')) {
              $(this).on('ajax:success', 'form', function() {
                ProtocolsIndex.reloadTable();
              });
            }
            if ($(this).hasClass('share-repo-modal')) {
              animateSpinner(null, false);
              ShareModal.init();
            }
            $(this).find('.selectpicker').selectpicker();
          })
          .on('hidden.bs.modal', function() {
            $(this).remove();
          })
          .modal('show');
        animateSpinner(null, false);
      });
    });
  }

  $(document).one('turbolinks:load', initRemoteModalListeners);
}());
