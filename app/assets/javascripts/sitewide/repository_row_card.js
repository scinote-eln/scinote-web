/* global PrintModalComponent RepositoryDatatable */

(function() {
  'use strict';

  $(document).on('click', '.relationships-info-link', (e) => {
    const myModuleId = $('.my-module-content').data('task-id');
    const repositoryRowURL = $(e.target).attr('href');

    e.stopPropagation();
    e.preventDefault();

    window.repositoryItemSidebarComponent.toggleShowHideSidebar(repositoryRowURL, myModuleId, 'relationships-section');
  });

  $(document).on('click', '.record-info-link', function (e) {
    const myModuleId = $('.my-module-content').data('task-id');
    const repositoryRowURL = $(this).attr('href');

    e.stopPropagation();
    e.preventDefault();

    window.repositoryItemSidebarComponent.toggleShowHideSidebar(repositoryRowURL, myModuleId, null);
  });

  $(document).on('click', '.print-label-button', function(e) {
    $.removeData($(this)[0], 'rows');

    var selectedRows = $(this).data('rows');

    e.preventDefault();
    e.stopPropagation();

    if (typeof PrintModalComponent !== 'undefined') {
      PrintModalComponent.openModal();
      if (selectedRows && selectedRows.length) {
        PrintModalComponent.repository_id = $(this).data('repositoryId');
        PrintModalComponent.row_ids = selectedRows;
      } else {
        PrintModalComponent.repository_id = RepositoryDatatable.repositoryId();
        PrintModalComponent.row_ids = [...RepositoryDatatable.selectedRows()];
      }
    }
  });
}());
