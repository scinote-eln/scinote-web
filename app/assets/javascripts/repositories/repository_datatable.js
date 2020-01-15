/*
  globals I18n _ SmartAnnotation FilePreviewModal animateSpinner Promise
  HelperModule animateLoading hideAssignUnasignModal RepositoryDatatableRowEditor
*/

//= require jquery-ui/widgets/sortable
//= require repositories/row_editor.js


var RepositoryDatatable = (function(global) {
  'use strict';

  var TABLE_ID = '';
  var TABLE_WRAPPER_ID = '.repository-table';
  var TABLE = null;
  var EDITABLE = false;

  var rowsSelected = [];

  // Tells whether we're currently viewing or editing table
  var currentMode = 'viewMode';

  // var selectedRecord;

  // Tells whether to filter only assigned repository records
  var viewAssigned;

  // Extend datatables API with searchable options
  // (http://stackoverflow.com/questions/39912395/datatables-dynamically-set-columns-searchable)
  $.fn.dataTable.Api.register('isColumnSearchable()', function(colSelector) {
    var idx = this.column(colSelector).index();
    return this.settings()[0].aoColumns[idx].bSearchable;
  });
  $.fn.dataTable.Api
    .register('setColumnSearchable()', function(colSelector, value) {
      if (value !== this.isColumnSearchable(colSelector)) {
        let idx = this.column(colSelector).index();
        this.settings()[0].aoColumns[idx].bSearchable = value;
        if (value === true) {
          this.rows().invalidate();
        }
      }
      return value;
    });

  // Enable/disable edit button
  function updateButtons() {
    if (currentMode === 'viewMode') {
      $(TABLE_WRAPPER_ID).removeClass('editing');
      $('#saveCancel').hide();
      $('#editDeleteCopy').show();
      $('#addRepositoryRecord').prop('disabled', false);
      $('.dataTables_length select').prop('disabled', false);
      $('#repository-acitons-dropdown').prop('disabled', false);
      $('#repository-columns-dropdown').find('.dropdown-toggle').prop('disabled', false);
      $('th').removeClass('disable-click');
      $('.repository-row-selector').prop('disabled', false);
      if (rowsSelected.length === 0) {
        $('#exportRepositoriesButton').addClass('disabled');
        $('#copyRepositoryRecords').prop('disabled', true);
        $('#editRepositoryRecord').prop('disabled', true);
        $('#deleteRepositoryRecordsButton').prop('disabled', true);
        $('#assignRepositoryRecords').prop('disabled', true);
        $('#unassignRepositoryRecords').prop('disabled', true);
      } else {
        if (rowsSelected.length === 1) {
          $('#editRepositoryRecord').prop('disabled', false);
        } else {
          $('#editRepositoryRecord').prop('disabled', true);
        }
        $('#exportRepositoriesButton').removeClass('disabled');
        $('#deleteRepositoryRecordsButton').prop('disabled', false);
        $('#copyRepositoryRecords').prop('disabled', false);
        $('#assignRepositoryRecords').prop('disabled', false);
        $('#unassignRepositoryRecords').prop('disabled', false);
      }
    } else if (currentMode === 'editMode') {
      $(TABLE_WRAPPER_ID).addClass('editing');
      $('#editDeleteCopy').hide();
      $('#saveCancel').show();
      $('#repository-acitons-dropdown').prop('disabled', true);
      $('.dataTables_length select').prop('disabled', true);
      $('#addRepositoryRecord').prop('disabled', true);
      $('#editRepositoryRecord').prop('disabled', true);
      $('#deleteRepositoryRecordsButton').prop('disabled', true);
      $('#assignRepositoryRecords').prop('disabled', true);
      $('#unassignRepositoryRecords').prop('disabled', true);
      $('#repository-columns-dropdown').find('.dropdown-toggle').prop('disabled', true);
      $('th').addClass('disable-click');
      $('.repository-row-selector').prop('disabled', true);
    }
  }

  function clearRowSelection() {
    $('.dt-body-center .repository-row-selector').prop('checked', false);
    $('.dt-body-center .repository-row-selector').closest('tr').removeClass('selected');
    rowsSelected = [];
  }

  function changeToViewMode() {
    currentMode = 'viewMode';
    // Table specific stuff
    TABLE.button(0).enable(true);
    FilePreviewModal.init();
    updateButtons();
  }

  function changeToEditMode() {
    currentMode = 'editMode';
    // Table specific stuff
    TABLE.button(0).enable(false);
    clearRowSelection();
    updateButtons();
  }

  // Updates "Select all" control in a data table
  function updateDataTableSelectAllCtrl() {
    var $table = TABLE.table().node();
    var $header = TABLE.table().header();
    var $chkboxAll = $('.repository-row-selector', $table);
    var $chkboxChecked = $('.repository-row-selector:checked', $table);
    var chkboxSelectAll = $('input[name="select_all"]', $header).get(0);

    // If none of the checkboxes are checked
    if ($chkboxChecked.length === 0) {
      chkboxSelectAll.checked = false;
      if ('indeterminate' in chkboxSelectAll) {
        chkboxSelectAll.indeterminate = false;
      }

    // If all of the checkboxes are checked
    } else if ($chkboxChecked.length === $chkboxAll.length) {
      chkboxSelectAll.checked = true;
      if ('indeterminate' in chkboxSelectAll) {
        chkboxSelectAll.indeterminate = false;
      }

    // If some of the checkboxes are checked
    } else {
      chkboxSelectAll.checked = true;
      if ('indeterminate' in chkboxSelectAll) {
        chkboxSelectAll.indeterminate = true;
      }
    }
  }

  function initRowSelection() {
    // Handle clicks on checkbox
    $('.dt-body-center .repository-row-selector').change(function(ev) {
      var $row;
      var data;
      var rowId;
      var index;

      if (currentMode !== 'viewMode') {
        return;
      }
      // Get row ID
      $row = $(this).closest('tr');
      data = TABLE.row($row).data();
      rowId = data.DT_RowId;

      // Determine whether row ID is in the list of selected row IDs
      index = $.inArray(rowId, rowsSelected);

      // If checkbox is checked and row ID is not in list of selected row IDs
      if (this.checked && index === -1) {
        rowsSelected.push(rowId);
      // Otherwise, if checkbox is not checked and row ID is in list of selected row IDs
      } else if (!this.checked && index !== -1) {
        rowsSelected.splice(index, 1);
      }

      if (this.checked) {
        $row.addClass('selected');
      } else {
        $row.removeClass('selected');
      }

      updateDataTableSelectAllCtrl();

      ev.stopPropagation();
      updateButtons();
      // Update number of selected records info
      $('#selected_info').html(' (' + rowsSelected.length + ' entries selected)');
    });

    // Handle click on "Select all" control
    $('.dataTables_scrollHead input[name="select_all"]').change(function(ev) {
      if (this.checked) {
        $('.repository-row-selector:not(:checked)').trigger('click');
      } else {
        $('.repository-row-selector:checked').trigger('click');
      }
      // Prevent click event from propagating to parent
      ev.stopPropagation();
    });
  }

  function checkAvailableColumns() {
    $.ajax({
      url: $(TABLE_ID).data('available-columns'),
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        var columnsIds = data.columns;
        var presentColumns = $(TABLE_ID).data('repository-columns-ids');
        if (!_.isEqual(columnsIds.sort(), presentColumns.sort())) {
          alert($(TABLE_ID).data('columns-changed'));
          animateSpinner();
          location.reload();
        }
      },
      error: function() {
        location.reload();
      }
    });
  }

  function initItemEditIcon() {
    $(TABLE_ID).on('click', '.repository-row-edit-icon', function(ev) {
      let rowId = $(ev.target).closest('tr').attr('id');
      let row = TABLE.row(`#${rowId}`);

      $(row.node()).find('.repository-row-selector').trigger('click');

      checkAvailableColumns();

      $(TABLE_ID).find('.repository-row-edit-icon').remove();

      RepositoryDatatableRowEditor.switchRowToEditMode(row);
      changeToEditMode();
    });
  }

  function initSaveButton() {
    $(TABLE_WRAPPER_ID).on('click', '#saveRecord', function() {
      var $table = $(TABLE_ID);
      RepositoryDatatableRowEditor.validateAndSubmit($table);
    });
  }

  function resetTableView() {
    if ($('#assigned').text().length === 0) {
      TABLE.column(1).visible(false);
    }
    TABLE.ajax.reload(function() {
      initRowSelection();
    }, false);
    changeToViewMode();
    SmartAnnotation.closePopup();
    animateSpinner(null, false);
  }

  function initCancelButton() {
    $(TABLE_WRAPPER_ID).on('click', '#cancelSave', function() {
      resetTableView();
    });
  }

  function appendInput(form, val, name) {
    $(form).append(
      $('<input>').attr('type', 'hidden').attr('name', name).val(val)
    );
  }

  function initHeaderTooltip() {
    // Fix compatibility of fixed table header and column names modal-tooltip
    $('.modal-tooltip').off();
    $('.modal-tooltip').hover(function() {
      var $tooltip = $(this).find('.modal-tooltiptext');
      var offsetLeft = $tooltip.offset().left;
      var offsetTop = $tooltip.offset().top;
      if ((offsetLeft + 200) > $(window).width()) {
        offsetLeft -= 150;
      }
      $('body').append($tooltip);
      $tooltip.css('background-color', '#d2d2d2');
      $tooltip.css('border-radius', '6px');
      $tooltip.css('color', '#333');
      $tooltip.css('display', 'block');
      $tooltip.css('left', offsetLeft + 'px');
      $tooltip.css('padding', '5px');
      $tooltip.css('position', 'absolute');
      $tooltip.css('text-align', 'center');
      $tooltip.css('top', offsetTop + 'px');
      $tooltip.css('visibility', 'visible');
      $tooltip.css('width', '200px');
      $tooltip.css('word-wrap', 'break-word');
      $(this).data('dropdown-tooltip', $tooltip);
    }, function() {
      $(this).append($(this).data('dropdown-tooltip'));
      $(this).data('dropdown-tooltip').removeAttr('style');
    });
  }

  function bindExportActions() {
    $('#export-repositories').on('click', function() {
      animateSpinner(null, true);
    });

    $('#exportRepositoriesButton').on('click', function() {
      $('#exportRepositoryModal').modal('show');
    });


    $('form#form-export').submit(function() {
      var form = this;
      if (currentMode === 'viewMode') {
        // Remove all hidden fields
        $(form).find('input[name=row_ids\\[\\]]').remove();
        $(form).find('input[name=header_ids\\[\\]]').remove();

        // Append visible column information
        $('table' + TABLE_ID + ' thead tr th').each(function() {
          var th = $(this);
          var val;
          switch ($(th).attr('id')) {
            case 'checkbox':
              val = -1;
              break;
            case 'assigned':
              val = -2;
              break;
            case 'row-id':
              val = -3;
              break;
            case 'row-name':
              val = -4;
              break;
            case 'added-by':
              val = -5;
              break;
            case 'added-on':
              val = -6;
              break;
            default:
              val = th.attr('id');
          }

          if (val) {
            appendInput(form, val, 'header_ids[]');
          }
        });

        // Append records
        $.each(rowsSelected, function(index, rowId) {
          appendInput(form, rowId, 'row_ids[]');
        });
      }
    })
      .on('ajax:beforeSend', function() {
        animateSpinner(null, true);
      })
      .on('ajax:complete', function() {
        $('#exportRepositoryModal').modal('hide');
        animateSpinner(null, false);
      })
      .on('ajax:success', function(ev, data) {
        HelperModule.flashAlertMsg(data.message, 'success');
      })
      .on('ajax:error', function(ev, data) {
        HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
      });
  }

  function disableCheckboxToggleOnAssetDownload() {
    $('.file-preview-link').on('click', function(ev) {
      ev.stopPropagation();
    });
  }

  // Adjust columns width in table header
  function adjustTableHeader() {
    TABLE.columns.adjust();
    $('.dropdown-menu').parent()
      .on('shown.bs.dropdown hidden.bs.dropdown', function() {
        TABLE.columns.adjust();
      });
  }

  function dataTableInit() {
    viewAssigned = 'assigned';
    TABLE = $(TABLE_ID).DataTable({
      dom: "R<'main-actions'<'toolbar'><'filter-container'f>>t<'pagination-row'<'pagination-info'li><'pagination-actions'p>>",
      stateSave: true,
      processing: true,
      serverSide: true,
      sScrollX: '100%',
      sScrollXInner: '100%',
      order: $(TABLE_ID).data('default-order'),
      colReorder: {
        fixedColumnsLeft: 2,
        realtime: false
      },
      destroy: true,
      ajax: {
        url: $(TABLE_ID).data('source'),
        data: function(d) {
          d.assigned = viewAssigned;
        },
        global: false,
        type: 'POST'
      },
      columnDefs: [{
        // Checkbox column needs special handling
        targets: 0,
        visible: true,
        searchable: false,
        orderable: false,
        className: 'dt-body-center',
        sWidth: '1%',
        render: function() {
          return "<input class='repository-row-selector' type='checkbox'>";
        }
      }, {
        // Assigned column is not searchable
        targets: 1,
        visible: true,
        searchable: false,
        orderable: true,
        className: 'assigned-column',
        sWidth: '1%',
        render: function(data) {
          let content = data;
          if (EDITABLE) {
            content = '<i class="repository-row-edit-icon fas fa-pencil-alt"></i>' + content;
          }
          return content;
        }
      }, {
        // Name column is clickable
        targets: 3,
        visible: true,
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
      oLanguage: {
        sSearch: I18n.t('general.filter_dots')
      },
      rowCallback: function(row, data) {
        // Get row ID
        let rowId = data.DT_RowId;
        // If row ID is in the list of selected row IDs
        if ($.inArray(rowId, rowsSelected) !== -1) {
          $(row).find('input[type="checkbox"]').prop('checked', true);
          $(row).addClass('selected');
        }
      },
      columns: (function() {
        var columns = $(TABLE_ID).data('default-table-columns');
        var customColumns = $(TABLE_ID).find('thead th[data-type]');
        for (let i = 0; i < columns.length; i += 1) {
          columns[i].data = String(i);
          columns[i].defaultContent = '';
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
      }()),
      drawCallback: function() {
        animateSpinner(this, false);
        changeToViewMode();
        updateDataTableSelectAllCtrl();
        FilePreviewModal.init();
        // Prevent row toggling when selecting user smart annotation link
        SmartAnnotation.preventPropagation('.atwho-user-popover');

        // Show number of selected rows near pages info
        $('#repository-table_info').append('<span id="selected_info"></span>');
        $('#selected_info').html(' (' + rowsSelected.length + ' entries selected)');
        initRowSelection();
      },
      preDrawCallback: function() {
        animateSpinner(this);
        $('.record-info-link').off('click');
      },
      stateLoadCallback: function(settings, callback) {
        var repositoryId = $(TABLE_ID).data('repository-id');
        $.ajax({
          url: '/repositories/' + repositoryId + '/state_load',
          data: {},
          dataType: 'json',
          type: 'POST',
          success: function(json) {
            callback(json.state);
          }
        });
      },
      stateSaveCallback: function(settings, data) {
        // Send an Ajax request to the server with the state object
        let repositoryId = $(TABLE_ID).data('repository-id');

        $.ajax({
          url: '/repositories/' + repositoryId + '/state_save',
          contentType: 'application/json',
          data: JSON.stringify({ state: data }),
          dataType: 'json',
          type: 'POST'
        });
      },
      fnInitComplete: function() {
        initRowSelection();
        bindExportActions();
        disableCheckboxToggleOnAssetDownload();
        FilePreviewModal.init();
        initHeaderTooltip();

        // Append button to inner toolbar in table
        $('div.toolbarButtonsDatatable').appendTo('div.toolbar');
        $('div.toolbarButtonsDatatable').show();

        // Append buttons for task inventory
        $('div.toolbarButtons').appendTo('div.toolbar');
        $('div.toolbarButtons').show();

        if (EDITABLE) {
          RepositoryDatatableRowEditor.initFormSubmitAction(TABLE);
          initItemEditIcon();
          initSaveButton();
          initCancelButton();
        }

        $('.dataTables_scrollBody, .dataTables_scrollHead').css('overflow', '');
      }
    });

    // hack to replace filter placeholder
    $('.dataTables_filter .form-control').attr('placeholder', $('.dataTables_filter label').text());
    $('.dataTables_filter label').contents().filter(function() {
      return this.nodeType === 3;
    }).remove();

    // Handle click on table cells with checkboxes
    $(TABLE_ID).on('click', 'tbody td', function(ev) {
      // Skip if clicking on selector checkbox, edit icon or link
      if ($(ev.target).is('.repository-row-selector, .repository-row-edit-icon, a')) return;

      $(this).parent().find('.repository-row-selector').trigger('click');
    });

    TABLE.on('column-reorder', function() {
      initRowSelection();
    });

    $('#assignRepositories, #unassignRepositories').click(function() {
      animateLoading();
    });

    return TABLE;
  }

  global.onClickAddRecord = function() {
    checkAvailableColumns();
    RepositoryDatatableRowEditor.addNewRow(TABLE);
    changeToEditMode();
  };

  global.onClickToggleAssignedRecords = function() {
    $('.repository-assign-group > .btn').click(function() {
      $('.btn-group > .btn').removeClass('active btn-toggle');
      $('.btn-group > .btn').addClass('btn-default');
      $(this).addClass('active btn-toggle');
    });

    $('#assigned-repo-records').on('click', function() {
      var promiseReload;
      viewAssigned = 'assigned';
      promiseReload = new Promise(function(resolve) {
        resolve(TABLE.ajax.reload());
      });
      promiseReload.then(function() {
        initRowSelection();
      });
    });
    $('#all-repo-records').on('click', function() {
      var promiseReload;
      viewAssigned = 'all';
      promiseReload = new Promise(function(resolve) {
        resolve(TABLE.ajax.reload());
      });
      promiseReload.then(function() {
        initRowSelection();
      });
    });
  };

  global.openAssignRecordsModal = function() {
    $.post(
      $('#assignRepositoryRecords').data('assign-url-modal'),
      { selected_rows: rowsSelected }
    ).done(
      function(data) {
        $(data.html).appendTo('body').promise().done(function() {
          $('#assignRepositoryRecordModal').modal('show');
        });
      }
    );
  };

  global.hideAssignUnasignModal = function(id) {
    $(id).modal('hide').promise().done(
      function() {
        $(id).remove();
      }
    );
  };

  global.submitAssignRepositoryRecord = function(option) {
    animateSpinner();
    $.ajax({
      url: $('#assignRepositoryRecordModal').data('assign-url'),
      type: 'POST',
      dataType: 'json',
      data: { selected_rows: rowsSelected, downstream: (option === 'downstream') },
      success: function(data) {
        hideAssignUnasignModal('#assignRepositoryRecordModal');
        HelperModule.flashAlertMsg(data.flash, 'success');
        resetTableView();
        clearRowSelection();
      },
      error: function(data) {
        hideAssignUnasignModal('#assignRepositoryRecordModal');
        HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
        resetTableView();
        clearRowSelection();
      }
    });
  }

  global.openUnassignRecordsModal = function() {
    $.post(
      $('#unassignRepositoryRecords').data('unassign-url'),
      { selected_rows: rowsSelected }
    ).done(
      function(data) {
        $(data.html).appendTo('body').promise().done(function() {
          $('#unassignRepositoryRecordModal').modal('show');
        });
      }
    );
  };

  global.submitUnassignRepositoryRecord = function(option) {
    animateSpinner();
    $.ajax({
      url: $('#unassignRepositoryRecordModal').data('unassign-url'),
      type: 'POST',
      dataType: 'json',
      data: { selected_rows: rowsSelected, downstream: (option === 'downstream') },
      success: function(data) {
        hideAssignUnasignModal('#unassignRepositoryRecordModal');
        HelperModule.flashAlertMsg(data.flash, 'success');
        resetTableView();
        clearRowSelection();
      },
      error: function(data) {
        hideAssignUnasignModal('#unassignRepositoryRecordModal');
        HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
        resetTableView();
        clearRowSelection();
      }
    });
  }

  global.onClickDeleteRecord = function() {
    animateSpinner();
    $.ajax({
      url: $('table' + TABLE_ID).data('delete-record'),
      type: 'POST',
      dataType: 'json',
      data: { selected_rows: rowsSelected },
      success: function(data) {
        HelperModule.flashAlertMsg(data.flash, data.color);
        rowsSelected = [];
        resetTableView();
      },
      error: function(ev) {
        if (ev.status === 403) {
          HelperModule.flashAlertMsg(
            I18n.t('repositories.js.permission_error'), ev.responseJSON.style
          );
        }
      }
    });
  }

  global.onClickCopyRepositoryRecords = function() {
    animateSpinner();
    $.ajax({
      url: $('table' + TABLE_ID).data('copy-records'),
      type: 'POST',
      dataType: 'json',
      data: { selected_rows: rowsSelected },
      success: function(data) {
        HelperModule.flashAlertMsg(data.flash, 'success');
        rowsSelected = [];
        resetTableView();
      },
      error: function(ev) {
        if (ev.status === 403) {
          HelperModule.flashAlertMsg(
            I18n.t('repositories.js.permission_error'), ev.responseJSON.style
          );
        }
      }
    });
  };

  // Edit record
  global.onClickEdit = function() {
    checkAvailableColumns();

    if (rowsSelected.length !== 1) {
      return;
    }

    let row = TABLE.row('#' + rowsSelected[0]);

    $(TABLE_ID).find('.repository-row-edit-icon').remove();

    changeToEditMode();
    RepositoryDatatableRowEditor.switchRowToEditMode(row);
    adjustTableHeader();
  };

  // Delete record
  global.onClickDelete = function() {
    $('#deleteRepositoryRecord').modal('show');
  };

  // Handle enter key
  $(document).off('keypress').keypress(function(event) {
    var keycode = (event.keyCode ? event.keyCode : event.which);
    if (currentMode === 'editMode' && keycode === '13') {
      $('#saveRecord').click();
    }
  });

  global.clearFileInput = function(el) {
    var parent = $(el).closest('div.repository-input-file-field');
    var input = parent.find('input:file')[0];
    // hide clear button
    $(parent.find('a[data-action="removeAsset"]')[0]).hide();
    // reset value
    input.value = '';
    // add flag
    $(input).attr('remove', true);
    // clear fileName
    $(parent.find('.file-name-label')[0]).text(I18n.t('general.file.no_file_chosen'));
    $(parent.find('.form-group')[0]).removeClass('has-error');
    parent.removeClass('has-error');
    $(parent.find('.help-block')[0]).remove();
  };

  function init(id) {
    TABLE_ID = id;
    EDITABLE = $(TABLE_ID).data('editable');
    TABLE = dataTableInit();
  }

  function destroy() {
    if (TABLE !== null) {
      TABLE.destroy();
      TABLE = null;
    }
    TABLE_ID = '';
  }

  function redrawTableOnSidebarToggle() {
    $('#sidebar-arrow').on('click', function() {
      var orgignalWidth = $('.repository-show .dataTables_scrollHead .table.dataTable').width();
      var windowWidth = $(window).width();
      if (!$(this).is('[data-shown]')) {
        if (windowWidth > orgignalWidth + 363) {
          $('.repository-show .dataTables_scrollHead')
            .find('.table.dataTable').css('width', (orgignalWidth + 280) + 'px');
        }
        document.documentElement.style.setProperty('--repository-sidebar-margin', '83px');
      } else {
        if (windowWidth > orgignalWidth + 83) {
          $('.repository-show .dataTables_scrollHead')
            .find('.table.dataTable').css('width', (orgignalWidth - 280) + 'px');
        }
        document.documentElement.style.setProperty('--repository-sidebar-margin', '363px');
      }
      setTimeout(function() {
        adjustTableHeader();
      }, 500);
    });
  }

  return Object.freeze({
    init: init,
    destroy: destroy,
    redrawTableOnSidebarToggle: redrawTableOnSidebarToggle,
    checkAvailableColumns: checkAvailableColumns
  });
}(window));
