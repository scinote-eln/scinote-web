(function() {
  'use strict';

  function initializeModuleTabSelector() {
    var parent = $('[data-role=module-tab-selector]');
    var ajaxUrl = parent.attr('data-url');

    // Disable checkboxes if neccesary
    parent.find('li.disabled input[type=checkbox]').attr('disabled');

    // Toggle tab functionality
    parent.find('li:not(.disabled) [data-tab]').on('click', function() {
      var $this = $(this);
      var tab = $this.attr('data-tab');

      // Enable spinner on dropdown
      animateSpinner();

      // Do the AJAX call onto server
      $.ajax({
        url: ajaxUrl,
        type: 'POST',
        dataType: 'json',
        data: {tab: tab},
        success: function(data) {
          // Reload page
          location.reload();
        },
        error: function(data) {
          // Disable spinner
          animateSpinner(null, false);
        }
      });
    });
  }

  // Only initialize module tab selector if it's actually
  // present on the page
  if ($('[data-role=module-tab-selector]').length) {
    initializeModuleTabSelector();
  }
})();
