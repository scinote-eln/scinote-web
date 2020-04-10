/* eslint-disable no-param-reassign */
/* global DataTableHelpers PerfectScrollbar FilePreviewModal */

var MyModuleRepositories = (function() {
  var SIMPLE_TABLE;
  var FULL_VIEW_TABLE;
  var FULL_VIEW_TABLE_SCROLLBAR;

  function tableColumnPreparation(tableContainer, skipCheckbox = false) {
    var columns = $(tableContainer).data('default-table-columns');
    var customColumns = $(tableContainer).find('thead th[data-type]');
    for (let i = 0; i < columns.length; i += 1) {
      columns[i].data = String(i);
      columns[i].defaultContent = '';
      if (skipCheckbox && i === 0) columns[i].visible = false;
    }
    customColumns.each((i, column) => {
      columns.push({
        visible: true,
        searchable: true,
        data: String(columns.length),
        defaultContent: $.fn.dataTable.render['default' + column.dataset.type](column.id)
      });
    });
    return columns;
  }

  function renderSimpleTable(tableContainer) {
    if (SIMPLE_TABLE) SIMPLE_TABLE.destroy();
    SIMPLE_TABLE = $(tableContainer).DataTable({
      dom: "Rt<'pagination-row'<'pagination-actions'p>>",
      processing: true,
      serverSide: true,
      responsive: true,
      pageLength: 5,
      order: [[3, 'asc']],
      sScrollY: '100%',
      sScrollX: '100%',
      sScrollXInner: '100%',
      destroy: true,
      ajax: {
        url: $(tableContainer).data('source'),
        data: function(d) {
          d.assigned = 'assigned';
          d.view_mode = true;
          d.skip_custom_columns = true;
        },
        global: false,
        type: 'GET'
      },
      columns: tableColumnPreparation(tableContainer),
      columnDefs: [{
        targets: 3,
        render: function(data, type, row) {
          return "<a href='" + row.recordInfoUrl + "'"
                 + "class='record-info-link'>" + data + '</a>';
        }
      }],
      drawCallback: function() {
        var repositoryContainer = $(this).closest('.assigned-repository-container');
        repositoryContainer.find('.table.dataTable').removeClass('hidden');
        SIMPLE_TABLE.columns.adjust();
      }
    });
  }

  function renderFullViewTable(tableContainer) {
    if (FULL_VIEW_TABLE) FULL_VIEW_TABLE.destroy();
    FULL_VIEW_TABLE_SCROLLBAR = false;
    FULL_VIEW_TABLE = $(tableContainer).DataTable({
      dom: "R<'main-actions hidden'<'toolbar'><'filter-container'f>>t<'pagination-row hidden'<'pagination-info'li><'pagination-actions'p>>",
      processing: true,
      stateSave: true,
      serverSide: true,
      order: $(tableContainer).data('default-order'),
      pageLength: 25,
      sScrollX: '100%',
      sScrollXInner: '100%',
      destroy: true,
      ajax: {
        url: $(tableContainer).data('source'),
        data: function(d) {
          d.assigned = 'assigned';
          d.view_mode = true;
        },
        global: false,
        type: 'GET'
      },
      columns: tableColumnPreparation(tableContainer, true),
      columnDefs: [{
        targets: 0,
        visible: false
      }, {
        targets: 1,
        searchable: false,
        className: 'assigned-column',
        sWidth: '1%'
      }, {
        targets: 3,
        render: function(data, type, row) {
          return "<a href='" + row.recordInfoUrl + "'"
                 + "class='record-info-link'>" + data + '</a>';
        }
      }, {
        targets: '_all',
        render: function(data) {
          if (typeof data === 'object' && $.fn.dataTable.render[data.value_type]) {
            return $.fn.dataTable.render[data.value_type](data);
          }
          return data;
        }
      }],

      fnInitComplete: function() {
        var dataTableWrapper = $(tableContainer).closest('.dataTables_wrapper');
        DataTableHelpers.initLengthApearance(dataTableWrapper);
        DataTableHelpers.initSearchField(dataTableWrapper);
        dataTableWrapper.find('.main-actions, .pagination-row').removeClass('hidden');
      },

      drawCallback: function() {
        FULL_VIEW_TABLE.columns.adjust();
        FilePreviewModal.init();
        if (FULL_VIEW_TABLE_SCROLLBAR) {
          FULL_VIEW_TABLE_SCROLLBAR.update();
        } else {
          FULL_VIEW_TABLE_SCROLLBAR = new PerfectScrollbar(
            $(tableContainer).closest('.dataTables_scrollBody')[0],
            {
              wheelSpeed: 0.5,
              minScrollbarLength: 20
            }
          );
        }
      },
      stateLoadCallback: function(settings, callback) {
        var loadStateUrl = $(tableContainer).data('load-state-url');
        $.post(loadStateUrl, function(json) {
          json.state.columns[0].visible = false;
          callback(json.state);
        });
      }
    });
  }

  function initSimpleTable() {
    $('#assigned-items-container').on('show.bs.collapse', '.assigned-repository-container', function() {
      var repositoryContainer = $(this);
      var repositoryTemplate = $($('#my-module-repository-simple-template').html());
      repositoryTemplate.attr('data-source', $(this).data('repository-url'));
      repositoryContainer.html(repositoryTemplate);
      renderSimpleTable(repositoryTemplate);
    });
  }

  function initRepositoryFullView() {
    $('#assigned-items-container').on('click', '.action-buttons .full-screen', function(e) {
      var fullViewModal = $('#my-module-repository-full-view-modal');
      var repositoryNameObject = $(this).closest('.assigned-repository-caret')
        .find('.assigned-repository-title')
        .clone();

      fullViewModal.find('.repository-name').html(repositoryNameObject);
      fullViewModal.modal('show');
      $.get($(this).data('table-url'), (data) => {
        fullViewModal.find('.modal-body').html(data.html);
        renderFullViewTable(fullViewModal.find('.table'));
      });
      e.stopPropagation();
    });
  }

  return {
    init: () => {
      initSimpleTable();
      initRepositoryFullView();
    }
  };
}());

MyModuleRepositories.init();
