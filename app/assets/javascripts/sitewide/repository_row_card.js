/* global PrintModalComponent RepositoryDatatable HelperModule MyModuleRepositories */

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
        $('#modal-info-repository-row').modal('hide');
        PrintModalComponent.repository_id = $(this).data('repositoryId');
        PrintModalComponent.row_ids = selectedRows;
      } else {
        PrintModalComponent.repository_id = RepositoryDatatable.repositoryId();
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
          const row = data?.data;
          const stock = row?.attributes?.stock;
          if (!stock?.value) return;
          // reload dataTable
          if ($('.dataTable.repository-dataTable')[0]) $('.dataTable.repository-dataTable').DataTable().ajax.reload(null, false);
          // update table stock and reminders count
          const updatedRow = { id: row.id, stock };
          if (row.attributes.active_reminders_count != null) {
            updatedRow.active_reminders_count = row.attributes.active_reminders_count;
          }
          window.repositoryTable?.updateRowData?.(updatedRow);
          // update item card stock column
          window.manageStockCallback && window.manageStockCallback(stock.value);
          $link.data('manageStockUrl', stock.value.stock_url);
        };
        window.manageStockModalComponent.showModal(stockValueUrl, updateCallback);
      }
    }
  });
}());
