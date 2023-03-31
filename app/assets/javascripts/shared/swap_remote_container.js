(function() {
  'use strict';

  function initSwapRemoteContainerListeners() {
    $(document).on('click', 'a[data-action="swap-remote-container"]', function(ev) {
      let element = ev.currentTarget;
      ev.stopImmediatePropagation();
      ev.stopPropagation();
      ev.preventDefault();

      $.get(element.getAttribute('href')).then(function({ html, flash }) {
        let targetID = element.getAttribute('data-target');
        let targetElement = $(element).closest(targetID);
        let newContainer = $(html).find(targetID).length ? $(html).find(targetID) : $(html);
        targetElement.replaceWith(newContainer);
        newContainer.find('.selectpicker').selectpicker();
        newContainer.find('.new-assignment-user-search').focus();

        if (flash) {
          HelperModule.flashAlertMsg(flash, 'success');
        }
      });
    });
  }

  $(document).one('turbolinks:load', initSwapRemoteContainerListeners);
}());
