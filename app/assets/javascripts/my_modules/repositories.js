/* eslint-disable no-param-reassign */
/* global DataTableHelpers PerfectScrollbar FilePreviewModal animateSpinner initAssignedTasksDropdown */

var MyModuleRepositories = (function() {
  const FULL_VIEW_MODAL = $('#myModuleRepositoryFullViewModal');
  var SIMPLE_TABLE;
  var FULL_VIEW_TABLE;
  var FULL_VIEW_TABLE_SCROLLBAR;

  function tableColumns(tableContainer, skipCheckbox = false) {
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

  function fullViewColumnDefs() {
    let columnDefs = [{
      targets: 0,
      visible: false
    }];

    if (FULL_VIEW_MODAL.find('.table').data('type') === 'live') {
      columnDefs.push({
        targets: 1,
        searchable: false,
        className: 'assigned-column',
        sWidth: '1%',
        render: function(data) {
          return $.fn.dataTable.render.AssignedTasksValue(data);
        }
      }, {
        targets: 3,
        render: function(data, type, row) {
          return "<a href='" + row.recordInfoUrl + "' class='record-info-link'>" + data + '</a>';
        }
      });
    }

    columnDefs.push(
      {
        targets: '_all',
        render: function(data) {
          if (typeof data === 'object' && $.fn.dataTable.render[data.value_type]) {
            return $.fn.dataTable.render[data.value_type](data);
          }
          return data;
        }
      }
    );

    return columnDefs;
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
        type: 'POST'
      },
      columns: tableColumns(tableContainer),
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
        type: 'POST'
      },
      columns: tableColumns(tableContainer, true),
      columnDefs: fullViewColumnDefs(),
      fnInitComplete: function() {
        var dataTableWrapper = $(tableContainer).closest('.dataTables_wrapper');
        DataTableHelpers.initLengthApearance(dataTableWrapper);
        DataTableHelpers.initSearchField(dataTableWrapper);
        dataTableWrapper.find('.main-actions, .pagination-row').removeClass('hidden');

        $('.table-container .toolbar').html($('#repositoryToolbarButtonsTemplate').html());
        initAssignedTasksDropdown(tableContainer);
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

  function setSelectedItem() {
    let versionsSidebar = FULL_VIEW_MODAL.find('.repository-versions-sidebar');
    let currentId = FULL_VIEW_MODAL.find('.table').data('id');
    versionsSidebar.find('.list-group-item').removeClass('active');
    versionsSidebar.find(`[data-id="${currentId}"]`).addClass('active');
  }

  function createDestroySnapshot(actionPath, requestType) {
    animateSpinner(null, true);
    $.ajax({
      url: actionPath,
      type: requestType,
      dataType: 'json',
      success: function(data) {
        FULL_VIEW_MODAL.find('.repository-versions-sidebar').html(data.html);
        setSelectedItem();
        animateSpinner(null, false);
      },
      error: function() {
        // TODO
      }
    });
  }

  function reloadTable(tableUrl) {
    animateSpinner(null, true);
    if (FULL_VIEW_TABLE) FULL_VIEW_TABLE.destroy();
    $.get(tableUrl, (data) => {
      FULL_VIEW_MODAL.find('.table-container').html(data.html);
      renderFullViewTable(FULL_VIEW_MODAL.find('.table'));
      setSelectedItem();
      animateSpinner(null, false);
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

  function initVersionsSidebarActions() {
    FULL_VIEW_MODAL.on('click', '#showVersionsSidebar', function(e) {
      $.get(FULL_VIEW_MODAL.find('.table').data('versions-sidebar-url'), (data) => {
        FULL_VIEW_MODAL.find('.repository-versions-sidebar').html(data.html);
        setSelectedItem();
        FULL_VIEW_MODAL.find('.table-container').addClass('collapsed');
        FULL_VIEW_MODAL.find('.repository-versions-sidebar').removeClass('collapsed');
      });
      e.stopPropagation();
    });

    FULL_VIEW_MODAL.on('click', '#createRepositorySnapshotButton', function(e) {
      createDestroySnapshot($(this).data('action-path'), 'POST');
      e.stopPropagation();
    });

    FULL_VIEW_MODAL.on('click', '.delete-snapshot-button', function(e) {
      let snapshotId = $(this).closest('.repository-snapshot-item').data('id');
      createDestroySnapshot($(this).data('action-path'), 'DELETE');
      if (snapshotId === FULL_VIEW_MODAL.find('.table').data('id')) {
        reloadTable(FULL_VIEW_MODAL.find('#selectLiveVersionButton').data('table-url'));
      }
      e.stopPropagation();
    });

    FULL_VIEW_MODAL.on('click', '.select-snapshot-button', function(e) {
      reloadTable($(this).data('table-url'));
      e.stopPropagation();
    });

    FULL_VIEW_MODAL.on('click', '#selectLiveVersionButton', function(e) {
      reloadTable(FULL_VIEW_MODAL.find('#selectLiveVersionButton').data('table-url'));
      e.stopPropagation();
    });

    FULL_VIEW_MODAL.on('click', '#collapseVersionsSidebar', function(e) {
      FULL_VIEW_MODAL.find('.repository-versions-sidebar').addClass('collapsed');
      FULL_VIEW_MODAL.find('.table-container').removeClass('collapsed');
      e.stopPropagation();
    });
  }

  function initRepositoryFullView() {
    $('#assigned-items-container').on('click', '.action-buttons .full-screen', function(e) {
      var repositoryNameObject = $(this).closest('.assigned-repository-caret')
        .find('.assigned-repository-title')
        .clone();

      FULL_VIEW_MODAL.find('.repository-name').html(repositoryNameObject);
      FULL_VIEW_MODAL.modal('show');
      $.get($(this).data('table-url'), (data) => {
        FULL_VIEW_MODAL.find('.table-container').html(data.html);
        renderFullViewTable(FULL_VIEW_MODAL.find('.table'));
      });
      e.stopPropagation();
    });
  }

  function initRepositoriesDropdown() {
    $('.repositories-assign-container').on('show.bs.dropdown', function() {
      var dropdownContainer = $(this);
      $.get(dropdownContainer.data('repositories-url'), function(result) {
        dropdownContainer.find('.repositories-dropdown-menu').html(result.html);
      });
    });
  }

  return {
    init: () => {
      initSimpleTable();
      initRepositoryFullView();
      initRepositoriesDropdown();
      initVersionsSidebarActions();
    }
  };
}());

MyModuleRepositories.init();
