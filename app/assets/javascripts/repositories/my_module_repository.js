(function() {
  'use strict';

  function initTable() {
    RepositoryDatatable.destroy()
    RepositoryDatatable.init($('#content').attr('data-repo-id'));
    RepositoryDatatable.redrawTableOnSidebarToggle();
    onClickToggleAssignedRecords();
  }

  // initialze repository datatable
  initTable();
}());
