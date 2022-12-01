(function() {
  function initNewMyModuleModal() {
    let experimentWrapper = '.experiment-new-my_module';
    let newMyModuleModal = '#new-my-module-modal';

    // Modal's submit handler function
    $(experimentWrapper)
      .on('ajax:success', newMyModuleModal, function() {
        $(newMyModuleModal).modal('hide');
      })
      .on('ajax:error', newMyModuleModal, function(ev, data) {
        $(this).renderFormErrors('my_module', data.responseJSON);
      });

    $(experimentWrapper)
      .on('ajax:success', '.new-my-module-button', function(ev, data) {
        // Add and show modal
        $(experimentWrapper).append($.parseHTML(data.html));
        $(newMyModuleModal).modal('show');
        $(newMyModuleModal).find("input[type='text']").focus();

        // Remove modal when it gets closed
        $(newMyModuleModal).on('hidden.bs.modal', function() {
          $(newMyModuleModal).remove();
        });
      });
  }

  initNewMyModuleModal();
}());
