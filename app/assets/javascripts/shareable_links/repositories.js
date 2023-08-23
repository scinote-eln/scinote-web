/* eslint-disable no-param-reassign, no-use-before-define  */
/* global initReminderDropdown */

(function() {
  var SIMPLE_TABLE;

  function stockManagementColumns(withConsumption = true) {
    let columns = [
      {
        visible: true,
        searchable: false,
        data: 'stock'
      }
    ];
    if (withConsumption) {
      columns = columns.concat([{
        visible: true,
        searchable: false,
        data: 'consumedStock'
      }]);
    }
    return columns;
  }

  function stockManagementColumnDefs(withConsumption = true) {
    let columns = [
      {
        targets: 'row-stock',
        className: 'item-stock',
        sWidth: '1%',
        render: function(data) {
          return $.fn.dataTable.render.RepositoryStockValue(data);
        }
      }
    ];
    if (withConsumption) {
      columns = columns.concat([{
        targets: 'row-consumption',
        className: 'item-consumed-stock',
        sWidth: '1%',
        render: function(data) {
          if (!data.stock_present) {
            return '<span class="empty-consumed-stock-render"> - </span>';
          }
          return `<span class="empty-consumed-stock-render">${data.value.consumed_stock_formatted}</span>`;
        }
      }]);
    }

    return columns;
  }

  function simpleTableColumns(tableContainer) {
    let columns = [
      {
        visible: true,
        searchable: false,
        data: 0
      }
    ];

    if ($(tableContainer).data('stock-management')) {
      columns = columns.concat(stockManagementColumns());
    }

    return columns;
  }

  function simpleViewColumnDefs(tableContainer) {
    let columnDefs = [{
      targets: 0,
      className: 'item-name',
      render: function(data, type, row) {
        var recordName = data;
        if (row.hasActiveReminders) {
          recordName = `<div class="dropdown row-reminders-dropdown"
                          data-row-reminders-url="${row.rowRemindersUrl}" tabindex='-1'>
                          <i class="sn-icon sn-icon-notifications dropdown-toggle row-reminders-icon"
                             data-toggle="dropdown" id="rowReminders${row.DT_RowId}}"></i>
                          <ul class="dropdown-menu" role="menu" aria-labelledby="rowReminders${row.DT_RowId}">
                          </ul>
                        </div>` + recordName;
        } else {
          recordName = `<span class='inline-block my-2'>${recordName}</span>`;
        }
        return recordName;
      }
    }];

    if ($(tableContainer).data('stock-management')) {
      columnDefs = columnDefs.concat(stockManagementColumnDefs());
    }

    return columnDefs;
  }

  function renderSimpleTable(tableContainer) {
    if (SIMPLE_TABLE) SIMPLE_TABLE.destroy();
    SIMPLE_TABLE = $(tableContainer).DataTable({
      dom: "Rt<'pagination-row'<'version-label'><'pagination-actions'p>>",
      processing: true,
      serverSide: true,
      responsive: true,
      pageLength: 5,
      order: [[0, 'asc']],
      sScrollY: '100%',
      sScrollX: '100%',
      sScrollXInner: '100%',
      destroy: true,
      ajax: {
        url: $(tableContainer).data('source'),
        contentType: 'application/json',
        data: function(d) {
          d.assigned = 'assigned_simple';
          d.view_mode = true;
          d.simple_view = true;
          return JSON.stringify(d);
        },
        global: false,
        type: 'POST'
      },
      columns: simpleTableColumns(tableContainer),
      columnDefs: simpleViewColumnDefs(tableContainer),
      language: {
        paginate: {
          previous: "<span class='hidden'></span>",
          next: "<span class='hidden'></span>"
        }
      },
      drawCallback: function() {
        var repositoryContainer = $(this).closest('.assigned-repository-container');
        repositoryContainer.find('.table.dataTable').removeClass('hidden');
        repositoryContainer.find('.dataTables_scrollBody').css('overflow', 'initial');
        repositoryContainer.find('.version-label').text(tableContainer.data('version-label'));
        SIMPLE_TABLE.columns.adjust();
      },
      createdRow: function(row, data) {
        $(row).find('.item-name').attr('data-state', data.DT_RowAttr['data-state']);
      },
      fnInitComplete: function() {
        initReminderDropdown(tableContainer);
      }
    });
  }

  function initSimpleTable() {
    $('#assigned-items-container').on('shown.bs.collapse', '.assigned-repository-container', function() {
      var repositoryContainer = $(this);
      var repositoryTable = repositoryContainer.find('.table');
      var initializedTable = repositoryContainer.find('.dataTables_wrapper table');

      // do not try to re-initialized already initialized table
      if (initializedTable.length) {
        initializedTable.DataTable().columns.adjust();
        return;
      }

      repositoryTable.attr('data-source', $(this).data('repository-url'));
      repositoryTable.attr('data-version-label', $(this).data('footer-label'));
      repositoryTable.attr('data-name-column-id', $(this).data('name-column-id'));
      repositoryTable.attr('data-stock-management', $(this).data('data-stock-management'));
      repositoryContainer.html(repositoryTable);
      renderSimpleTable(repositoryTable);
    });

    $('#wrapper').on('sideBar::shown sideBar::hidden', function() {
      if (SIMPLE_TABLE) {
        SIMPLE_TABLE.columns.adjust();
      }
    });
  }

  initSimpleTable();
}());
