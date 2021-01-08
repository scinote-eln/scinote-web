(function() {
  'use strict';

  $('.delete-repo-option').initSubmitModal('#delete-repo-modal', 'repository');
  $('.rename-repo-option').initSubmitModal('#rename-repo-modal', 'repository');
  $('.share-repo-option').initSubmitModal('.share-repo-modal', 'repository');
  $('.copy-repo-option').initSubmitModal('#copy-repo-modal', 'repository');
})();
