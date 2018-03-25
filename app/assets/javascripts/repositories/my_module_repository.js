(function() {
  'use strict';

  // initialze repository datatable
  RepositoryDatatable.destroy();
  RepositoryDatatable.init($('#content').attr('data-repo-id'));
  onClickToggleAssignedRecords();
})();
