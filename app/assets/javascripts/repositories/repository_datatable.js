//= require jquery-ui/sortable

var RepositoryDatatable = (function(global) {
  'use strict';

  var TABLE_ID = '';
  var TABLE = {};

  // Extend datatables API with searchable options
  // (http://stackoverflow.com/questions/39912395/datatables-dynamically-set-columns-searchable)
  $.fn.dataTable.Api.register('isColumnSearchable()', function(colSelector) {
    var idx = this.column(colSelector).index();
    return this.settings()[0].aoColumns[idx].bSearchable;
  });
  $.fn.dataTable.Api
    .register('setColumnSearchable()', function(colSelector, value) {
      if (value !== this.isColumnSearchable(colSelector)) {
        var idx = this.column(colSelector).index();
        this.settings()[0].aoColumns[idx].bSearchable = value;
        if (value === true) {
          this.rows().invalidate();
        }
      }
      return value;
    });

  var rowsSelected = [];

  // Tells whether we're currently viewing or editing table
  var currentMode = 'viewMode';

  // Tells what action will execute by pressing on save button (update/create)
  var saveAction = 'update';
  var selectedRecord;

  // Helps saving correct table state
  var myData;
  var loadFirstTime = true;

  var originalHeader;

  // Tells whether to filter only assigned repository records
  var viewAssigned;

  function dataTableInit() {
    // Make a copy of original repository table header
    originalHeader = $(TABLE_ID + ' thead').children().clone();
    viewAssigned = 'assigned';
    TABLE = $(TABLE_ID).DataTable({
      order: [[2, 'desc']],
      dom: "R<'row'<'col-sm-9-custom toolbar'l><'col-sm-3-custom'f>>tpi",
      stateSave: true,
      processing: true,
      serverSide: true,
      sScrollX: '100%',
      sScrollXInner: '100%',
      scrollY: '64vh',
      scrollCollapse: true,
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
        targets: 0,
        searchable: false,
        orderable: false,
        className: 'dt-body-center',
        sWidth: '1%',
        render: function() {
          return "<input class='repository-row-selector' type='checkbox'>";
        }
      }, {
        targets: 1,
        searchable: false,
        orderable: true,
        sWidth: '1%'
      }],
      rowCallback: function(row, data) {
        // Get row ID
        var rowId = data.DT_RowId;
        // If row ID is in the list of selected row IDs
        if ($.inArray(rowId, rowsSelected) !== -1) {
          $(row).find('input[type="checkbox"]').prop('checked', true);
          $(row).addClass('selected');
        }
      },
      columns: (function() {
        var numOfColumns = $(TABLE_ID).data('num-columns');
        var columns = [];
        for (var i = 0; i < numOfColumns; i++) {
          var visible = (i <= 4);
          var searchable = (i > 0 && i <= 4);
          columns.push({
            data: String(i),
            defaultContent: '',
            visible: visible,
            searchable: searchable
          });
        }
        return columns;
      })(),
      fnDrawCallback: function() {
        animateSpinner(this, false);
        changeToViewMode();
        updateButtons();
        updateDataTableSelectAllCtrl();
        // Prevent row toggling when selecting user smart annotation link
        SmartAnnotation.preventPropagation('.atwho-user-popover');

        // Show number of selected rows near pages info
        $('#repository-table_info').append('<span id="selected_info"></span>');
        $('#selected_info').html(' (' +
                                 rowsSelected.length +
                                 ' entries selected)');
        initRowSelection();
        initHeaderTooltip();
      },
      preDrawCallback: function() {
        animateSpinner(this);
      },
      stateLoadCallback: function() {
        // Send an Ajax request to the server to get the data. Note that
        // this is a synchronous request since the data is expected back from the
        // function
        var repositoryId = $(TABLE_ID).data('repository-id');
        $.ajax({
          url: '/repositories/' + repositoryId + '/state_load',
          data: {},
          async: false,
          dataType: 'json',
          type: 'POST',
          success: function(json) {
            myData = json.state;
          }
        });
        return myData;
      },
      stateSaveCallback: function(settings, data) {
        // Send an Ajax request to the server with the state object
        var repositoryId = $(TABLE_ID).data('repository-id');
        // Save correct data
        if (loadFirstTime === true) {
          data = myData;
        }
        $.ajax({
          url: '/repositories/' + repositoryId + '/state_save',
          data: { state: data },
          dataType: 'json',
          type: 'POST'
        });
        loadFirstTime = false;
        initHeaderTooltip();
      },
      fnInitComplete: function(oSettings) {
        // Reload correct column order and visibility (if you refresh page)
        // First two columns are fixed
        TABLE.column(0).visible(true);
        TABLE.column(1).visible(true);
        for (var i = 2; i < TABLE.columns()[0].length; i++) {
          var visibility = false;
          if (myData.columns[i]) {
            visibility = myData.columns[i].visible;
          }
          if (typeof (visibility) === 'string') {
            visibility = (visibility === 'true');
          }
          TABLE.column(i).visible(visibility);
          TABLE.setColumnSearchable(i, visibility);
        }
        oSettings._colReorder.fnOrder(myData.ColReorder);
        TABLE.on('mousedown', function() {
          $('#repository-columns-dropdown').removeClass('open');
        });
        initHeaderTooltip();
        initRowSelection();
        bindExportActions();
      }
    });

    // Handle click on table cells with checkboxes
    $(TABLE_ID).on('click', 'tbody td', function(e) {
      if ($(e.target).is('.repository-row-selector')) {
        // Skip if clicking on selector checkbox
        return;
      }
      $(this).parent().find('.repository-row-selector').trigger('click');
    });

    TABLE.on('column-reorder', function() {
      initRowSelection();
    });

    $('#assignRepositories, #unassignRepositories').click(function() {
      animateLoading();
    });

    // Timeout for table header scrolling
    setTimeout(function() {
      TABLE.columns.adjust();

      // Append button to inner toolbar in table
      $('div.toolbarButtons').appendTo('div.toolbar');
      $('div.toolbarButtons').show();
    }, 10);

    return TABLE;
  }

  // Enables noSearchHidden plugin
  $.fn.dataTable.defaults.noSearchHidden = true;

  function bindExportActions() {
    $('form#form-export').submit(function() {
      var form = this;

      if (currentMode === 'viewMode') {
        // Remove all hidden fields
        $(form).find('input[name=row_ids\\[\\]]').remove();
        $(form).find('input[name=header_ids\\[\\]]').remove();

        // Append visible column information
        $('.active table' + TABLE_ID + ' thead tr th').each(function() {
          var th = $(this);
          var val;
          switch ($(th).attr('id')) {
            case 'checkbox':
              val = -1;
              break;
            case 'assigned':
              val = -2;
              break;
            case 'row-name':
              val = -3;
              break;
            case 'added-by':
              val = -4;
              break;
            case 'added-on':
              val = -5;
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
    });
  }


  function appendInput(form, val, name) {
    $(form).append(
      $('<input>')
      .attr('type', 'hidden')
      .attr('name', name)
      .val(val)
    );
  }

  function initRowSelection() {
    // Handle clicks on checkbox
    $('.dt-body-center .repository-row-selector').change(function(e) {
      if (currentMode !== 'viewMode') {
        return false;
      }
      // Get row ID
      var $row = $(this).closest('tr');
      var data = TABLE.row($row).data();
      var rowId = data.DT_RowId;

      // Determine whether row ID is in the list of selected row IDs
      var index = $.inArray(rowId, rowsSelected);

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

      e.stopPropagation();
      updateButtons();
      // Update number of selected records info
      $('#selected_info').html(' (' + rowsSelected.length + ' entries selected)');
    });

    // Handle click on "Select all" control
    $('.dataTables_scrollHead input[name="select_all"]').change(function(e) {
      if (this.checked) {
        $('.repository-row-selector:not(:checked)').trigger('click');
      } else {
        $('.repository-row-selector:checked').trigger('click');
      }
      // Prevent click event from propagating to parent
      e.stopPropagation();
    });
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

  function initHeaderTooltip() {
    // Fix compatibility of fixed table header and column names modal-tooltip
    $('.modal-tooltip').off();
    $('.modal-tooltip').hover(function() {
      var $tooltip = $(this).find('.modal-tooltiptext');
      var offsetLeft = $tooltip.offset().left;
      if ((offsetLeft + 200) > $(window).width()) {
        offsetLeft -= 150;
      }
      var offsetTop = $tooltip.offset().top;
      var width = 200;

      // set tooltip params in the table body
      if ($(this).parents(TABLE_ID).length) {
        offsetLeft = $(TABLE_ID).offset().left + 100;
        width = $(TABLE_ID).width() - 200;
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
      $tooltip.css('width', width + 'px');
      $tooltip.css('word-wrap', 'break-word');
      $tooltip.css('z-index', '4');
      $(this).data('dropdown-tooltip', $tooltip);
    }, function() {
      $(this).append($(this).data('dropdown-tooltip'));
      $(this).data('dropdown-tooltip').removeAttr('style');
    });
  }

  global.onClickAddRecord = function() {
    changeToEditMode();
    updateButtons();

    saveAction = 'create';
    var tr = document.createElement('tr');
    if (TABLE.column(1).visible() === false) {
      TABLE.column(1).visible(true);
    }
    $('table' + TABLE_ID + ' thead tr').children('th').each(function() {
      var th = $(this);
      var td;
      var input;
      if ($(th).attr('id') === 'checkbox') {
        td = createTdElement('');
        $(td).html($('#saveRecord').clone());
        tr.appendChild(td);
      } else if ($(th).attr('id') === 'assigned') {
        td = createTdElement('');
        $(td).html($('#cancelSave').clone());
        tr.appendChild(td);
      } else if ($(th).attr('id') === 'row-name') {
        input = changeToInputField('repository_row', 'name', '');
        tr.appendChild(createTdElement(input));
      } else if ($(th).hasClass('repository-column')) {
        input = changeToInputField('repository_cell', th.attr('id'), '');
        tr.appendChild(createTdElement(input));
      } else {
        // Column we don't care for, just add empty td
        tr.appendChild(createTdElement(''));
      }
    });
    $('table' + TABLE_ID).prepend(tr);
    selectedRecord = tr;

    // initialize smart annotation
    _.each($('[data-object="repository_cell"]'), function(el) {
      if (_.isUndefined($(el).data('atwho'))) {
        SmartAnnotation.init(el);
      }
    });
    // Adjust columns width in table header
    adjustTableHeader();
  }

  global.onClickToggleAssignedRecords = function() {
    $('.repository-assign-group > .btn').click(function() {
      $('.btn-group > .btn').removeClass('active btn-primary');
      $('.btn-group > .btn').addClass('btn-default');
      $(this).addClass('active btn-primary');
    });

    $('#assigned-repo-records').on('click', function() {
      viewAssigned = 'assigned';
      TABLE.ajax.reload(function() {
        initRowSelection();
      }, false);
    });
    $('#all-repo-records').on('click', function() {
      viewAssigned = 'all';
      TABLE.ajax.reload(function() {
        initRowSelection();
      }, false);
    });
  };

  global.onClickAssignRecords = function() {
    animateSpinner();
    $.ajax({
      url: $('#assignRepositoryRecords').data('assign-url'),
      type: 'POST',
      dataType: 'json',
      data: { selected_rows: rowsSelected },
      success: function(data) {
        HelperModule.flashAlertMsg(data.flash, 'success');
        onClickCancel();
        clearRowSelection();
      },
      error: function(data) {
        HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
        onClickCancel();
        clearRowSelection();
      }
    });
  }

  global.onClickUnassignRecords = function() {
    animateSpinner();
    $.ajax({
      url: $('#unassignRepositoryRecords').data('unassign-url'),
      type: 'POST',
      dataType: 'json',
      data: {selected_rows: rowsSelected},
      success: function(data) {
        HelperModule.flashAlertMsg(data.flash, 'success');
        onClickCancel();
        clearRowSelection();
      },
      error: function(data) {
        HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
        onClickCancel();
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
      data: {selected_rows: rowsSelected},
      success: function(data) {
        HelperModule.flashAlertMsg(data.flash, data.color);
        rowsSelected = [];
        onClickCancel();
      },
      error: function(e) {
        if (e.status === 403) {
          HelperModule.flashAlertMsg(
            I18n.t('repositories.js.permission_error'), e.responseJSON.style
          );
        }
      }
    });
  }

  // Edit record
  global.onClickEdit = function() {
    if (rowsSelected.length !== 1) {
      return;
    }

    var row = TABLE.row('#' + rowsSelected[0]);
    var node = row.node();
    var rowData = row.data();

    $(node).find('td input').trigger('click');
    selectedRecord = node;

    clearAllErrors();
    changeToEditMode();
    updateButtons();
    saveAction = 'update';

    $.ajax({
      url: rowData.recordEditUrl,
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        if (TABLE.column(1).visible() === false) {
          TABLE.column(1).visible(true);
        }
        // Show save and cancel buttons in first two columns
        $(node).children('td').eq(0).html($('#saveRecord').clone());
        $(node).children('td').eq(1).html($('#cancelSave').clone());

        // Record name column
        var colIndex = getColumnIndex('#row-name');
        if (colIndex) {
          $(node).children('td').eq(colIndex)
                 .html(changeToInputField('repository_row', 'name',
                                          data.repository_row.name));
        }

        // Take care of custom cells
        var cells = data.repository_row.repository_cells;
        $(node).children('td').each(function(i) {
          var td = $(this);
          var rawIndex = TABLE.column.index('fromVisible', i);
          var colHeader = TABLE.column(rawIndex).header();
          if ($(colHeader).hasClass('repository-column')) {
            // Check if cell on this record exists
            var cell = cells[$(colHeader).attr('id')];
            if (cell) {
              td.html(changeToInputField('repository_cell',
                                         $(colHeader).attr('id'),
                                         cell.value));
            } else {
              td.html(changeToInputField('repository_cell',
                                         $(colHeader).attr('id'), ''));
            }
          }
        });

        // initialize smart annotation
        _.each($('[data-object="repository_cell"]'), function(el) {
          if (_.isUndefined($(el).data('atwho'))) {
                  SmartAnnotation.init(el);
          }
        });
        // Adjust columns width in table header
        adjustTableHeader();
        updateButtons();
      },
      error: function(e) {
        if (e.status === 403) {
          HelperModule.flashAlertMsg(
            I18n.t('repositories.js.permission_error'), e.responseJSON.style
          );
          changeToViewMode();
          updateButtons();
        }
      }
    });
  }

  // Save record
  global.onClickSave = function() {
    var node;
    var rowData;
    if (saveAction === 'update') {
      var row = TABLE.row(selectedRecord);
      node = row.node();
      rowData = row.data();
    } else if (saveAction === 'create') {
      node = selectedRecord;
    }
    // First fetch all the data in input fields
    var data = {
      request_url: $(TABLE_ID).data('current-uri'),
      repository_row_id: $(selectedRecord).attr('id'),
      repository_row: {},
      repository_cells: {}
    };

    // Direct record attributes
    // Record name
    data.repository_row.name = $('td input[data-object = repository_row]').val();

    // Custom cells
    $(node).find('td input[data-object = repository_cell]').each(function() {
      // Send data only and only if cell is not empty
      if ($(this).val().trim()) {
        data.repository_cells[$(this).attr('name')] = $(this).val();
      }
    });

    var url;
    var type;
    if (saveAction === 'update') {
      url = rowData.recordUpdateUrl;
      type = 'PUT';
    } else {
      type = 'POST';
      url = $('table' + TABLE_ID).data('create-record');
    }
    $.ajax({
      url: url,
      type: type,
      dataType: 'json',
      data: data,
      success: function(data) {
        HelperModule.flashAlertMsg(data.flash, 'success');
        SmartAnnotation.closePopup();
        onClickCancel();
      },
      error: function(e) {
        SmartAnnotation.closePopup();
        var data = e.responseJSON;
        clearAllErrors();

        if (e.status === 404) {
          HelperModule.flashAlertMsg(
            I18n.t('repositories.js.not_found_error'), 'danger'
          );
          changeToViewMode();
          updateButtons();
        } else if (e.status === 403) {
          HelperModule.flashAlertMsg(
            I18n.t('repositories.js.permission_error'), 'danger'
          );
          changeToViewMode();
          updateButtons();
        } else if (e.status === 400) {
          if (data.default_fields) {
            var defaultFields = data.default_fields;

            // Validate record name
            if (defaultFields.name) {
              var input = $(selectedRecord).find('input[name = name]');

              if (input) {
                input.closest('.form-group').addClass('has-error');
                input.parent().append("<span class='help-block'>" +
                                      defaultFields.name + '<br /></span>');
              }
            }
          }

          // Validate custom cells
          $.each(data.repository_cells || [], function(key, val) {
            $.each(val, function(key, val) {
              var input = $(selectedRecord).find('input[name=' + key + ']');
              if (input) {
                input.closest('.form-group').addClass('has-error');
                input.parent().append("<span class='help-block'>" +
                                      val.data[0] + '<br /></span>');
              }
            });
          });
        }
      }
    });
  }

  // Enable/disable edit button
  function updateButtons() {
    if (currentMode === 'viewMode') {
      $('#addRepositoryRecord').removeClass('disabled');
      $('#addRepositoryRecord').prop('disabled', false);
      $('#addNewColumn').removeClass('disabled');
      $('#addNewColumn').prop('disabled', false);
      $('#repository-columns-dropdown')
        .find('.dropdown-toggle')
        .prop('disabled', false);
      $('th').removeClass('disable-click');
      $('.repository-row-selector').removeClass('disabled');
      $('.repository-row-selector').prop('disabled', false);
      if (rowsSelected.length === 0) {
        $('#editRepositoryRecord').prop('disabled', true);
        $('#editRepositoryRecord').addClass('disabled');
        $('#deleteRepositoryRecordsButton').prop('disabled', true);
        $('#deleteRepositoryRecordsButton').addClass('disabled');
        $('#exportRepositoriesButton').addClass('disabled');
        $('#exportRepositoriesButton').prop('disabled', true);
        $('#exportRepositoriesButton').off('click');
        $('#export-repositories').off('click');
        $('#assignRepositoryRecords').addClass('disabled');
        $('#assignRepositoryRecords').prop('disabled', true);
        $('#unassignRepositoryRecords').addClass('disabled');
        $('#unassignRepositoryRecords').prop('disabled', true);
      } else {
        if (rowsSelected.length === 1 &&
            $('#exportRepositoriesButton').get(0)) {
          $('#editRepositoryRecord').prop('disabled', false);
          $('#editRepositoryRecord').removeClass('disabled');

          // If we switched from 2 selections to 1, then this is not needed
          var events = $._data($('#exportRepositoriesButton').get(0), 'events');
          if (!events || !events.click) {
            $('#exportRepositoriesButton').removeClass('disabled');
            $('#exportRepositoriesButton').prop('disabled', false);
            $('#exportRepositoriesButton').off('click').on('click', function() {
              $('#exportRepositoryModal').modal('show');
            });
            $('#export-repositories').off('click').on('click', function() {
              animateSpinner(null, true);
              $('#form-export').submit();
            });
          }
        } else {
          $('#editRepositoryRecord').prop('disabled', true);
          $('#editRepositoryRecord').addClass('disabled');
        }
        $('#deleteRepositoryRecordsButton').prop('disabled', false);
        $('#deleteRepositoryRecordsButton').removeClass('disabled');
        $('#assignRepositoryRecords').removeClass('disabled');
        $('#assignRepositoryRecords').prop('disabled', false);
        $('#unassignRepositoryRecords').removeClass('disabled');
        $('#unassignRepositoryRecords').prop('disabled', false);
      }
    } else if (currentMode === 'editMode') {
      $('#addRepositoryRecord').addClass('disabled');
      $('#addRepositoryRecord').prop('disabled', true);
      $('#editRepositoryRecord').addClass('disabled');
      $('#editRepositoryRecord').prop('disabled', true);
      $('#addNewColumn').addClass('disabled');
      $('#addNewColumn').prop('disabled', true);
      $('#deleteRepositoryRecordsButton').addClass('disabled');
      $('#deleteRepositoryRecordsButton').prop('disabled', true);
      $('#exportRepositoriesButton').addClass('disabled');
      $('#exportRepositoriesButton').off('click');
      $('#export-repositories').off('click');
      $('#assignRepositoryRecords').addClass('disabled');
      $('#assignRepositoryRecords').prop('disabled', true);
      $('#unassignRepositoryRecords').addClass('disabled');
      $('#unassignRepositoryRecords').prop('disabled', true);
      $('#repository-columns-dropdown').find('.dropdown-toggle')
                                    .prop('disabled', true);
      $('th').addClass('disable-click');
      $('.repository-row-selector').addClass('disabled');
      $('.repository-row-selector').prop('disabled', true);
    }
  }

  // Clear all has-error tags
  function clearAllErrors() {
    // Remove any validation errors
    $(selectedRecord).find('.has-error').each(function() {
      $(this).removeClass('has-error');
      $(this).find('span').remove();
    });
    // Remove any alerts
    $('#alert-container').find('div').remove();
  }

  function clearRowSelection() {
    $('.dt-body-center .repository-row-selector').prop('checked', false);
    $('.dt-body-center .repository-row-selector').closest('tr')
                                                 .removeClass('selected');
    rowsSelected = [];
  }

  // Restore previous table
  global.onClickCancel = function() {
    if ($('#assigned').text().length === 0) {
      TABLE.column(1).visible(false);
    }
    TABLE.ajax.reload(function() {
      initRowSelection();
    }, false);
    changeToViewMode();
    updateButtons();
    SmartAnnotation.closePopup();
    animateSpinner(null, false);
  }

  // Handle enter key
  $(document).off('keypress').keypress(function(event) {
    var keycode = (event.keyCode ? event.keyCode : event.which);
    if (currentMode === 'editMode' && keycode === '13') {
      $('#saveRecord').click();
      return false;
    }
  });

  // Helper functions
  function getColumnIndex(id) {
    if (id < 0) {
      return false;
    }
    return TABLE.column(id).index('visible');
  }

  // Takes object and surrounds it with input
  function changeToInputField(object, name, value) {
    return "<div class='form-group'><input class='form-control' data-object='" +
        object + "' name='" + name + "' value='" + value + "'></input></div>";
  }

  // Return td element with content
  function createTdElement(content) {
    var td = document.createElement('td');
    td.innerHTML = content;
    return td;
  }

  // Adjust columns width in table header
  function adjustTableHeader() {
    TABLE.columns.adjust();
    $('.dropdown-menu').parent()
      .on('shown.bs.dropdown hidden.bs.dropdown', function() {
        TABLE.columns.adjust();
      });
  }

  function changeToViewMode() {
    currentMode = 'viewMode';
    // Table specific stuff
    TABLE.button(0).enable(true);
  }

  function changeToEditMode() {
    currentMode = 'editMode';
    // Table specific stuff
    TABLE.button(0).enable(false);
    initHeaderTooltip();
  }

  /*
   * Repository columns dropdown
   */

  var dropdown, dropdownList;

  function createNewColumn() {
    // Make an Ajax request to repository_columns_controller
    var url = $('#new-column-form').data('action');
    var columnName = $('#new-column-name').val();
    if (columnName.length > 0) {
      $.ajax({
        method: 'POST',
        dataType: 'json',
        data: {repository_column: {name: columnName}},
        error: function(data) {
          var form = $('#new-column-form');
          form.addClass('has-error');
          form.find('.help-block').remove();
          form.append('<span class="help-block">' +
            data.responseJSON.name +
            '</span>');
        },
        success: function(data) {
          var form = $('#new-column-form');
          form.find('.help-block').remove();
          if (form.hasClass('has-error')) {
            form.removeClass('has-error');
          }
          $('#new-column-name').val('');
          form.append('<span class="help-block">' +
            I18n.t('repositories.js.column_added') +
            '</span>');

          // Preserve save/delete buttons as we need them after new table
          // will be created
          $('div.toolbarButtons').appendTo('div.repository-table');
          $('div.toolbarButtons').hide();

          // Destroy datatable
          TABLE.destroy();

          // Add number of columns
          $(TABLE_ID).data('num-columns',
            $(TABLE_ID).data('num-columns') + 1);
          // Add column to table (=table header)
          originalHeader.append(
            '<th class="repository-column" id="' + data.id + '" ' +
            'data-editable data-deletable ' +
            'data-edit-url="' + data.edit_url + '" ' +
            'data-update-url="' + data.update_url + '" ' +
            'data-destroy-html-url="' + data.destroy_html_url + '"' +
            '>' + generateColumnNameTooltip(data.name) + '</th>');

          // Remove all event handlers as we re-initialize them later with
          // new table
          $(TABLE_ID).off();
          $(TABLE_ID +' thead').empty();
          $(TABLE_ID + ' thead').append(originalHeader);

          // Re-initialize datatable
          TABLE = dataTableInit();
          TABLE.on('init.dt', function() {
            loadColumnsNames();
            dropdownOverflow();
          });
        },
        url: url
      });
    } else {
      var form = $('#new-column-form');
      form.addClass('has-error');
      form.find('.help-block').remove();
      form.append('<span class="help-block">' +
        I18n.t('repositories.js.empty_column_name') +
        '</span>');
    }
  }

  function initNewColumnForm() {
    $('#repository-columns-dropdown').on('show.bs.dropdown', function() {
      // Clear input and errors when dropdown is opened
      var input = $(this).find('input#new-column-name');
      input.val('');
      var form = $('#new-column-form');
      if (form.hasClass('has-error')) {
        form.removeClass('has-error');
      }
      form.find('.help-block').remove();
    });
    $('#add-new-column-button').click(function(e) {
      e.stopPropagation();
      createNewColumn();
    });
    $('#new-column-name').keydown(function(e) {
      if (e.keyCode === 13) {
        e.preventDefault();
        createNewColumn();
      }
    });
  }

  // loads the columns names in the dropdown list
  function loadColumnsNames() {
    // Save scroll position
    var scrollPosition = dropdownList.scrollTop();
    // Clear the list
    dropdownList.find('li[data-position]').remove();
    _.each(TABLE.columns().header(), function(el, index) {
      if (index > 1) {
        var colIndex = $(el).attr('data-column-index');
        var visible = TABLE.column(colIndex).visible();
        var editable = $(el).is('[data-editable]');
        var deletable = $(el).is('[data-deletable]');

        var visClass = (visible) ? 'glyphicon-eye-open' : 'glyphicon-eye-close';
        var visLi = (visible) ? '' : 'col-invisible';
        var editClass = (editable) ? '' : 'disabled';
        var delClass = (deletable) ? '' : 'disabled';

        var thederName;
        if ($(el).find('.modal-tooltiptext').length > 0) {
          thederName = $(el).find('.modal-tooltiptext').text();
        } else {
          thederName = el.innerText;
        }

        var html =
          '<li ' +
          'data-position="' + colIndex + '" ' +
          'data-id="' + $(el).attr('id') + '" ' +
          'data-edit-url=' + $(el).attr('data-edit-url') + ' ' +
          'data-update-url=' + $(el).attr('data-update-url') + ' ' +
          'data-destroy-html-url=' + $(el).attr('data-destroy-html-url') + ' ' +
          'class="' + visLi + '"><i class="grippy"></i> ' +
          '<span class="text">' + generateColumnNameTooltip(thederName) +
          '</span> ' +
          '<span class="form-group"><input type="text" class="text-edit ' +
            'form-control" style="display: none;" />' +
          '<span class="pull-right controls">' +
          '<span class="ok glyphicon glyphicon-ok" style="display: none;" ' +
            'title="' + $(TABLE_ID).data('save-text') + '"></span>' +
          '<span class="cancel glyphicon glyphicon-remove" ' +
            'style="display: none;" ' +
            'title="' + $(TABLE_ID).data('cancel-text') +
            '"></span>' +
          '<span class="vis glyphicon ' + visClass + '" title="' +
            $(TABLE_ID).data('columns-visibility-text') + '">' +
          '</span> ' +
          '<span class="edit glyphicon glyphicon-pencil ' + editClass +
            '" title="' + $(TABLE_ID).data('edit-text') +
            '"></span>' +
          '<span class="del glyphicon glyphicon-trash ' + delClass +
            '" title="' + $(TABLE_ID).data('columns-delete-text') +
            '"></span>' +
          '</span><br></span></li>';
        dropdownList.append(html);
      }
    });
    // Restore scroll position
    dropdownList.scrollTop(scrollPosition);
    toggleColumnVisibility();
    // toggles grip img
    customLiHoverEffect();
  }

  function customLiHoverEffect() {
    var liEl = dropdownList.find('li');
    liEl.mouseover(function() {
      $(this)
        .find('.grippy')
        .addClass('grippy-img');
    }).mouseout(function() {
      $(this)
        .find('.grippy')
        .removeClass('grippy-img');
    });
  }

  function toggleColumnVisibility() {
    var lis = dropdownList.find('.vis');
    lis.on('click', function(event) {
      event.stopPropagation();
      var self = $(this);
      var li = self.closest('li');
      var column = TABLE.column(li.attr('data-position'));

      if (column.visible()) {
        self.addClass('glyphicon-eye-close');
        self.removeClass('glyphicon-eye-open');
        li.addClass('col-invisible');
        column.visible(false);
        TABLE.setColumnSearchable(column.index(), false);
      } else {
        self.addClass('glyphicon-eye-open');
        self.removeClass('glyphicon-eye-close');
        li.removeClass('col-invisible');
        column.visible(true);
        TABLE.setColumnSearchable(column.index(), true);
        initHeaderTooltip();
      }

      // Re-filter/search if neccesary
      var searchText = $('div.dataTables_filter input').val();
      if (!_.isEmpty(searchText)) {
        TABLE.search(searchText).draw();
      }
      initRowSelection();
    });
  }

  function initSorting() {
    dropdownList.sortable({
      items: 'li:not(.add-new-column-form)',
      cancel: '.new-repository-column',
      axis: 'y',
      update: function() {
        var reorderer = TABLE.colReorder;
        var listIds = [];
        // We skip first two columns
        listIds.push(0, 1);
        dropdownList.find('li[data-position]').each(function() {
          listIds.push($(this).first().data('position'));
        });
        reorderer.order(listIds, false);
        loadColumnsNames();
      }
    });
  }

  function initEditColumns() {
    function cancelEditMode() {
      dropdownList.find('.text-edit').hide();
      dropdownList.find('.controls .ok,.cancel').hide();
      dropdownList.find('.text').css('display', ''); // show() doesn't work
      dropdownList.find('.controls .vis,.edit,.del').css('display', ''); // show() doesn't work
    }

    function editColumn(li) {
      var id = li.attr('data-id');
      var text = li.find('.text');
      var textEdit = li.find('.text-edit');
      var newName = textEdit.val().trim();
      var url = li.attr('data-update-url');

      $.ajax({
        url: url,
        type: 'PUT',
        data: {repository_column: {name: newName}},
        dataType: 'json',
        success: function() {
          dropdownList.sortable('enable');
          $(li).clearFormErrors();
          text.html(generateColumnNameTooltip(newName));
          $(TABLE.columns().header()).filter('#' + id)
            .html(generateColumnNameTooltip(newName));
          originalHeader.find('#' + id).html(newName);
          cancelEditMode();
          initHeaderTooltip();
        },
        error: function(xhr) {
          dropdownList.sortable('disable');
          $(li).clearFormErrors();
          var msg = $.parseJSON(xhr.responseText);

          renderFormError(xhr,
                          $(li).find('.text-edit'),
                          Object.keys(msg)[0] + ' ' + msg.name.toString());
          var verticalHeight = $(li).offset().top;
          dropdownList.scrollTo(verticalHeight, 0);
        }
      });
    }

    // On edit buttons click (bind onto master dropdown list)
    dropdownList.on('click', '.edit:not(.disabled)', function(event) {
      event.stopPropagation();

      // Clear all input errors
      _.each(dropdownList, function(el) {
        $(el).clearFormErrors();
      });

      cancelEditMode();

      var li = $(this).closest('li');
      var url = li.attr('data-edit-url');
      ajaxCallEvent();

      function ajaxCallEvent() {
        $.ajax({
          url: url,
          success: function() {
            var text;
            var textEdit;
            var controls;
            var controlsEdit;
            text = li.find('.text');
            if ($(text).find('.modal-tooltiptext').length > 0) {
              text = $(text).find('.modal-tooltiptext');
            }
            textEdit = li.find('.text-edit');
            controls = li.find('.controls .vis,.edit,.del');
            controlsEdit = li.find('.controls .ok,.cancel');

            // Toggle edit mode
            li.addClass('editing');

            // Set the text-edit's value
            textEdit.val(text.text().trim());

            // Toggle elements
            text.hide();
            controls.hide();
            textEdit.css('display', ''); // show() doesn't work
            controlsEdit.css('display', ''); // show() doesn't work
            dropdownList.sortable('disable');
            dropdownList.on('click', function(ev) {
              ev.stopPropagation();
            });
            // Focus input
            textEdit.focus();
          },
          error: function(e) {
            $(li).clearFormErrors();
            var msg = $.parseJSON(e.responseText);

            renderFormError(undefined,
                            $(li).find('.text-edit'),
                            msg.name.toString());
            var verticalHeight = $(li).offset().top;
            dropdownList.scrollTo(verticalHeight, 0);
            setTimeout(function() {
              $(li).clearFormErrors();
            }, 5000);
          }
        });
      }
    });

    // On hiding dropdown, cancel edit mode throughout dropdown
    dropdown.on('hidden.bs.dropdown', function() {
      cancelEditMode();
    });

    // On OK buttons click
    dropdownList.on('click', '.ok', function(event) {
      event.stopPropagation();
      dropdownList.sortable('enable');
      var self = $(this);
      var li = self.closest('li');
      $(li).clearFormErrors();
      editColumn(li);
    });

    // On enter click while editing column text
    dropdownList.on('keydown', 'input.text-edit', function(event) {
      if (event.keyCode === 13) {
        event.preventDefault();
        dropdownList.sortable('enable');
        var self = $(this);
        var li = self.closest('li');
        $(li).clearFormErrors();
        editColumn(li);
      }
    });

    // On cancel buttons click
    dropdownList.on('click', '.cancel', function(event) {
      event.stopPropagation();
      dropdownList.sortable('enable');
      var self = $(this);
      var li = self.closest('li');
      $(li).clearFormErrors();
      li.removeClass('editing');

      li.find('.text-edit').hide();
      li.find('.controls .ok,.cancel').hide();
      li.find('.text').css('display', ''); // show() doesn't work
      li.find('.controls .vis,.edit,.del').css('display', ''); // show() doesn't work
    });
  }

  function initDeleteColumns() {
    var modal = $('#deleteRepositoryColumn');

    dropdownList.on('click', '.del', function(event) {
      event.stopPropagation();

      var self = $(this);
      var li = self.closest('li');
      var url = li.attr('data-destroy-html-url');
      var colIndex = originalHeader.find('#' + li.attr('data-id')).index();

      $.ajax({
        url: url,
        type: 'POST',
        dataType: 'json',
        data: {column_index: colIndex},
        success: function(data) {
          var modalBody = modal.find('.modal-body');

          // Inject the body's HTML into modal
          modalBody.html(data.html);

          // Show the modal
          modal.modal('show');
        },
        error: function(xhr) {
          dropdownList.sortable('disable');
          $(li).clearFormErrors();
          var msg = $.parseJSON(xhr.responseText);

          renderFormError(undefined,
                          $(li).find('.text-edit'),
                          msg.name.toString());
          var verticalHeight = $(li).offset().top;
          dropdownList.scrollTo(verticalHeight, 0);
          setTimeout(function() {
            $(li).clearFormErrors();
          }, 5000);
        }
      });
    });

    modal.find('.modal-footer [data-action=delete]').on('click', function() {
      var modalBody = modal.find('.modal-body');
      var form = modalBody.find('[data-role=destroy-repository-column-form]');
      var id = form.attr('data-id');

      form
      .on('ajax:success', function() {
        // Preserve save/delete buttons as we need them after new table
        // will be created
        $('div.toolbarButtons').appendTo('div.repository-table');
        $('div.toolbarButtons').hide();

        // Destroy datatable
        TABLE.destroy();

        // Subtract number of columns
        $(TABLE_ID).data(
          'num-columns',
          $(TABLE_ID).data('num-columns') - 1
        );

        // Remove column from table (=table header) & rows
        var th = originalHeader.find('#' + id);
        var index = th.index();
        th.remove();
        $(TABLE_ID + ' tbody td:nth-child(' + (index + 1) + ')').remove();

        // Remove all event handlers as we re-initialize them later with
        // new table
        $(TABLE_ID).off();
        $(TABLE_ID + ' thead').empty();
        $(TABLE_ID + ' thead').append(originalHeader);

        // Re-initialize datatable
        TABLE = dataTableInit();
        loadColumnsNames();

        // Hide modal
        modal.modal('hide');
      })
      .on('ajax:error', function() {
        // TODO
      });

      form.submit();
    });

    modal.on('hidden.bs.modal', function() {
      // Remove event handlers, clear contents
      var modalBody = modal.find('.modal-body');
      modalBody.off();
      modalBody.html('');
    });
  }

  // calculate the max height of window and adjust dropdown max-height
  function dropdownOverflow() {
    var windowHeight = $(window).height();
    var offset = windowHeight - dropdownList.offset().top;

    if (dropdownList.height() >= offset) {
      dropdownList.css('maxHeight', offset);
    }
  }

  function generateColumnNameTooltip(name) {
    var maxLength = $(TABLE_ID).data('max-dropdown-length');
    if ($.trim(name).length > maxLength) {
      return '<div class="modal-tooltip">' +
             truncateLongString(name, maxLength) +
             '<span class="modal-tooltiptext">' + name + '</span></div>';
    }
    return name;
  }

  // initialze dropdown after the table is loaded
  function initDropdown() {
    TABLE.on('init.dt', function() {
      dropdown = $('#repository-columns-dropdown');
      dropdownList = $('#repository-columns-list');
      initNewColumnForm();
      initSorting();
      toggleColumnVisibility();
      initEditColumns();
      initDeleteColumns();
    });
    $('#repository-columns-dropdown').on('show.bs.dropdown', function() {
      loadColumnsNames();
      dropdownList.sortable('enable');
    });

    $('#repository-columns-dropdown').on('shown.bs.dropdown', function() {
      dropdownOverflow();
    });
  }

  function init(id) {
    TABLE_ID = id;
    TABLE = dataTableInit();
    initDropdown();
  }

  function destroy() {
    TABLE = {};
    TABLE_ID = '';
  }

  return Object.freeze({
    init: init,
    destroy: destroy
  });
})(window);
