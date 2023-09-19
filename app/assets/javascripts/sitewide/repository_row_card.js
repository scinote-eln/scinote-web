/* global PrintModalComponent RepositoryDatatable HelperModule MyModuleRepositories */

(function() {
  'use strict';

  $(document).on('click', '.record-info-link', function(e) {
    e.stopPropagation();
    e.preventDefault();

    window.repositoryItemSidebarComponent.toggleShowHideSidebar($(this).attr('href'));
  });

  $(document).on('click', '.print-label-button', function(e) {
    var selectedRows = $(this).data('rows');

    e.preventDefault();
    e.stopPropagation();

    if (typeof PrintModalComponent !== 'undefined') {
      PrintModalComponent.showModal = true;
      if (selectedRows && selectedRows.length) {
        $('#modal-info-repository-row').modal('hide');
        PrintModalComponent.row_ids = selectedRows;
      } else {
        PrintModalComponent.row_ids = [...RepositoryDatatable.selectedRows()];
      }
    }
  });

  $(document).on('click', '.assign-inventory-button', function(e) {
    e.preventDefault();
    let assignUrl = $(this).data('assignUrl');
    let repositoryRowId = $(this).data('repositoryRowId');

    $.ajax({
      url: assignUrl,
      type: 'POST',
      data: { repository_row_id: repositoryRowId },
      dataType: 'json',
      success: function(data) {
        HelperModule.flashAlertMsg(data.flash, 'success');
        $('#modal-info-repository-row').modal('hide');
        if (typeof MyModuleRepositories !== 'undefined') {
          MyModuleRepositories.reloadRepositoriesList(repositoryRowId);
        }
      },
      error: function(error) {
        HelperModule.flashAlertMsg(error.responseJSON.flash, 'danger');
      }
    });
  });
}());
