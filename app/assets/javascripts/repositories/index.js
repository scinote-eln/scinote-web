//= require repositories/import/records_importer.js
(function(global) {
  'use strict';

  global.pageReload = function() {
    animateSpinner();
    location.reload();
  }
  
  $(document).ready(function() {
    $('#create-new-repository').initializeModal('#create-repo-modal');
  });
})(window);
