/* global PrintModalComponent RepositoryDatatable HelperModule MyModuleRepositories */

(function() {
  'use strict';

  $(document).on('click', '.record-info-link', function(e) {
    const myModuleId = $('.my-module-content').data('task-id');
    const repositoryRowURL = $(this).attr('href');

    e.stopPropagation();
    e.preventDefault();

    window.repositoryItemSidebarComponent.toggleShowHideSidebar(repositoryRowURL, myModuleId);
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
    const assignUrl = $(this).attr('data-assign-url');
    const repositoryRowId = $(this).attr('data-repository-row-id');

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
        window.repositoryItemSidebarComponent.reload();
      },
      error: function(error) {
        HelperModule.flashAlertMsg(error.responseJSON.flash, 'danger');
      }
    });
  });

  $(document).on('click', '.export-consumption-button', function(e) {
    const selectedRows = $(this).data('rows') || RepositoryDatatable.selectedRows();

    e.preventDefault();

    window.initExportStockConsumptionModal();

    if (window.exportStockConsumptionModalComponent) {
      window.exportStockConsumptionModalComponent.fetchRepositoryData(
        selectedRows,
        { repository_id: $(this).data('objectId') },
      );
      $('#modal-info-repository-row').modal('hide');
    }
  });
}());
