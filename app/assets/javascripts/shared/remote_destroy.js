(function () {
  'use strict';

  function initRemoteDestroyListeners() {
    $(document).on('ajax:success', 'a[data-action*="remote-destroy"]', function({ currentTarget }) {
      let target = currentTarget.getAttribute('data-target')
      document.querySelector(target).remove()
    })

    $(document).on('ajax:error', 'a[data-action*="remote-destroy"]', function(_, data) {
      HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
    })
  }

  $(document).one('turbolinks:load', initRemoteDestroyListeners);
})();
