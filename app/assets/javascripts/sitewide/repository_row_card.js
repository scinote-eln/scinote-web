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
  $(document).on('click', '.manage-repository-stock-value-link', (e) => {
    e.preventDefault();

    window.initManageStockValueModalComponent();
    if (window.manageStockModalComponent) {
      const $link = $(e.target).parents('a')[0] ? $(e.target).parents('a') : $(e.target);
      const stockValueUrl = $link.data('manage-stock-url');
      let updateCallback;
      if (stockValueUrl) {
        updateCallback = (data) => {
          if (!data?.value) return;
          reloadTableRow(data);
          // update item card stock column
          window.manageStockCallback && window.manageStockCallback(data.value);
          $link.data('manageStockUrl', data.value.stock_url)
        };
        window.manageStockModalComponent.showModal(stockValueUrl, updateCallback);
      }
    }
  });
}());

const reloadTableRow = function(data) {
  const row = $('.dataTable').find(`tr#${data.row_id}`);
  let rowData = $('.dataTable').DataTable().row(row).data();

  if (data.name) {
    // handle assigned repositories
    if ($('.dataTable').parents('.assigned-repository-container').length) {
      rowData['0'] = data.name;
    } else {
      rowData['3'] = data.name;
    }
    $('.dataTable').DataTable().row(row).data(rowData);
    return;
  }
  const reminder = Object.entries(rowData).find(([, attr]) => attr === 'hasActiveReminders');
  const column = Object.entries(rowData).find(([_idx, { value_type }]) => value_type === data.value_type);

  if (!column) return;
  if (reminder) rowData[reminder[0]] = data.hasActiveReminders;
  rowData[column[0]] = { ...rowData[column[0]], value: data.value };

  $('.dataTable').DataTable().row(row).data(rowData);
}
