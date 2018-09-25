(function() {
  'use strict';

  function initTable() {
    RepositoryDatatable.destroy()
    RepositoryDatatable.init($('#content').attr('data-repo-id'));
    RepositoryDatatable.redrawTableOnSidebarToggle();
  }

  // initialze repository datatable
  $(document).ready(function() {
    initTable()
    onClickToggleAssignedRecords();
  });
})();
