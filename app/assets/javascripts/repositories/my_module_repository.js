(function() {
  'use strict';

  // initialze repository datatable
  $(document).ready(function() {
    RepositoryDatatable.destroy()
    RepositoryDatatable.init($('#content').attr('data-repo-id'));
    onClickToggleAssignedRecords();
  });
})();
