/*
  globals I18n _ SmartAnnotation FilePreviewModal truncateLongString animateSpinner Promise
  ActiveStorage HelperModule animateLoading RepositoryItemEditForm onClickCancel
  hideAssignUnasignModal
*/

//= require jquery-ui/widgets/sortable
//= require repositories/forms/repository_item_edit.js

var RepositoryDatatable = (function(global) {
  'use strict';

  var TABLE_ID = '';
  var TABLE = null;
  var SCINOTE_REPOSITORY_EDITED_ROWS = []; // an array of edited rows

  var rowsSelected = [];

  // Tells whether we're currently viewing or editing table
  var currentMode = 'viewMode';

  // Tells what action will execute by pressing on save button (update/create)
  var saveAction = 'update';
  var selectedRecord;

  // Helps saving correct table state
  var myData;
  var loadFirstTime = true;

  // Tells whether to filter only assigned repository records
  var viewAssigned;

  var dropdownList;

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

  function changeToViewMode() {
    currentMode = 'viewMode';
    // Table specific stuff
    TABLE.button(0).enable(true);
    FilePreviewModal.init();
  }

  function changeToEditMode() {
    currentMode = 'editMode';
    // Table specific stuff
    TABLE.button(0).enable(false);
  }

  // Enable/disable edit button
  function updateButtons() {
    if (currentMode === 'viewMode') {
      $('#addRepositoryRecord').removeClass('disabled').prop('disabled', false);
      $('.dataTables_length select').prop('disabled', false);
      $('#repository-acitons-dropdown').removeClass('disabled').prop('disabled', false);
      $('#addNewColumn').removeClass('disabled').prop('disabled', false);
      $('#repository-columns-dropdown').find('.dropdown-toggle').prop('disabled', false);
      $('th').removeClass('disable-click');
      $('.repository-row-selector').removeClass('disabled').prop('disabled', false);
      if (rowsSelected.length === 0) {
        $('#copyRepositoryRecords').prop('disabled', true).addClass('disabled');
        $('#editRepositoryRecord').prop('disabled', true).addClass('disabled');
        $('#deleteRepositoryRecordsButton').prop('disabled', true).addClass('disabled');
        $('#exportRepositoriesButton').parent('li').addClass('disabled');
        $('#exportRepositoriesButton').prop('disabled', true).off('click');
        $('#export-repositories').off('click');
        $('#assignRepositoryRecords').addClass('disabled').prop('disabled', true);
        $('#unassignRepositoryRecords').addClass('disabled').prop('disabled', true);
      } else {
        if (rowsSelected.length === 1 && $('#exportRepositoriesButton').get(0)) {
          $('#editRepositoryRecord').prop('disabled', false).removeClass('disabled');

          // If we switched from 2 selections to 1, then this is not needed
          let events = $.data($('#exportRepositoriesButton').get(0), 'events');
          if (!events || !events.click) {
            $('#exportRepositoriesButton').parent('li').removeClass('disabled');
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
          $('#editRepositoryRecord').prop('disabled', true).addClass('disabled');
        }
        $('#deleteRepositoryRecordsButton').prop('disabled', false).removeClass('disabled');
        $('#copyRepositoryRecords').prop('disabled', false).removeClass('disabled');
        $('#assignRepositoryRecords').removeClass('disabled').prop('disabled', false);
        $('#unassignRepositoryRecords').removeClass('disabled').prop('disabled', false);
      }
    } else if (currentMode === 'editMode') {
      $('#repository-acitons-dropdown').addClass('disabled').prop('disabled', true);
      $('.dataTables_length select').prop('disabled', true);
      $('#addRepositoryRecord').addClass('disabled').prop('disabled', true);
      $('#editRepositoryRecord').addClass('disabled').prop('disabled', true);
      $('#addNewColumn').addClass('disabled').prop('disabled', true);
      $('#deleteRepositoryRecordsButton').addClass('disabled').prop('disabled', true);
      $('#exportRepositoriesButton').off('click');
      $('#export-repositories').off('click');
      $('#assignRepositoryRecords').addClass('disabled').prop('disabled', true);
      $('#unassignRepositoryRecords').addClass('disabled').prop('disabled', true);
      $('#repository-columns-dropdown').find('.dropdown-toggle').prop('disabled', true);
      $('th').addClass('disable-click');
      $('.repository-row-selector').addClass('disabled').prop('disabled', true);
    }
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

  // Helper functions
  function listItemDropdown(options, currentValue, columnId) {
    var html = `<select class="form-control selectpicker repository-dropdown"
                data-abs-min-length="2" data-live-search="true"
                data-container="body" column_id="${columnId}">
                <option value="-1"></option>`;
    $.each(options, function(index, value) {
      var selected = (currentValue === value[1]) ? 'selected' : '';
      html += '<option value="' + value[0] + '" ' + selected + '>';
      html += value[1] + '</option>';
    });
    html += '</select>';
    return html;
  }

  function addSelectedFile(type, cell, input) {
    if (type === 'RepositoryAssetValue') {
      if (cell.value != null) {
        const dT = new ClipboardEvent('').clipboardData // Firefox workaround exploiting https://bugzilla.mozilla.org/show_bug.cgi?id=1422655
          || new DataTransfer(); // specs compliant (as of March 2018 only Chrome)
        dT.items.add(new File([_], cell.value.file_name));
        input.files = dT.files;
      }
      $(input).on('change', function() {
        this.dataset.changed = 'true';
      });
    }
  }

  function initRowSelection() {
    // Handle clicks on checkbox
    $('.dt-body-center .repository-row-selector').change(function(e) {
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

  function appendInput(form, val, name) {
    $(form).append(
      $('<input>').attr('type', 'hidden').attr('name', name).val(val)
    );
  }

  // Takes object and surrounds it with input
  function changeToInputField(object, name, value) {
    return "<div class='form-group'><input class='form-control' data-object='"
        + object + "' name='" + name + "' value='" + value + "'></input></div>";
  }

  // Takes object and surrounds it with input
  function changeToInputFileField(object, name, value) {
    return "<div class='repository-input-file-field'>"
        + "<div class='new-input-file-field-div'><div class='form-group'>"
        + "<input type='file' class='form-control' data-object='"
        + object + "' name='" + name + "' value='" + value + "'></div>"
        + "<a onClick='clearFileInput(this)'>"
        + "<i class='fas fa-times'></i>"
        + '</a></div></div>';
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
    });
  }

  function disableCheckboxToggleOnAssetDownload() {
    $('.file-preview-link').on('click', function(ev) {
      ev.stopPropagation();
    });
  }

  // Return td element with content
  function createTdElement(content) {
    var td = document.createElement('td');
    td.innerHTML = content;
    return td;
  }

  function initialListItemsRequest(columnId) {
    var massageResponse = [];
    $.ajax({
      url: $(TABLE_ID).data('list-items-path'),
      type: 'POST',
      dataType: 'json',
      async: false,
      data: {
        q: '',
        column_id: columnId
      }
    }).done(function(data) {
      $.each(data.list_items, function(index, el) {
        massageResponse.push([el.id, el.data]);
      });
    });
    return listItemDropdown(massageResponse, '-1', columnId);
  }

  function initSelectPicker() {
    $('.selectpicker')
      .selectpicker({ liveSearch: true })
      .ajaxSelectPicker({
        ajax: {
          url: $(TABLE_ID).data('list-items-path'),
          type: 'POST',
          dataType: 'json',
          data: function() {
            var params = {
              q: '{{{q}}}',
              column_id: $(this.valueOf().plugin.$element).attr('column_id')
            };

            return params;
          }
        },
        locale: {
          emptyTitle: 'Nothing selected'
        },
        preprocessData: function(data) {
          var items = [];
          if (Object.prototype.hasOwnProperty.call(data, 'list_items')) {
            items.push({
              value: '-1',
              text: '',
              disabled: false
            });
            $.each(data.list_items, function(index, el) {
              items.push(
                {
                  value: el.id,
                  text: el.data,
                  disabled: false
                }
              );
            });
          }
          return items;
        },
        emptyRequest: true,
        clearOnEmpty: false,
        preserveSelected: false
      }).on('change.bs.select', function(el) {
        $(this).closest('td').attr('list_item_id', el.target.value);
        $(this).closest('td').attr('column_id', $(this).attr('column_id'));
      })
      .trigger('change.bs.select');
  }

  // Adjust columns width in table header
  function adjustTableHeader() {
    TABLE.columns.adjust();
    $('.dropdown-menu').parent()
      .on('shown.bs.dropdown hidden.bs.dropdown', function() {
        TABLE.columns.adjust();
      });
  }

  // Clear all has-error tags
  function clearAllErrors() {
    // Remove any validation errors
    $(selectedRecord)
      .find('.has-error')
      .removeClass('has-error')
      .find('span')
      .remove();
    // Remove any alerts
    $('#alert-container').find('div').remove();
  }

  function clearRowSelection() {
    $('.dt-body-center .repository-row-selector').prop('checked', false);
    $('.dt-body-center .repository-row-selector').closest('tr').removeClass('selected');
    rowsSelected = [];
  }

  function dataTableInit() {
    viewAssigned = 'assigned';
    TABLE = $(TABLE_ID).DataTable({
      dom: "R<'row'<'col-sm-6 toolbar'><'col-sm-6'lf>><'row'<'col-sm-12't>><'row'<'col-sm-7'i><'col-sm-5'p>>",
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
        // Checkbox column needs special handling
        targets: 0,
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
        searchable: false,
        orderable: true,
        sWidth: '1%'
      }, {
        // Name column is clickable
        targets: 3,
        visible: true,
        render: function(data, type, row) {
          return "<a href='" + row.recordInfoUrl + "'"
                 + "class='record-info-link'>" + data + '</a>';
        }
      }],
      oLanguage: {
        sSearch: I18n.t('general.filter_dots')
      },
      rowCallback: function(row, data) {
        // Get row ID
        var rowId = data.DT_RowId;
        // If row ID is in the list of selected row IDs
        if ($.inArray(rowId, rowsSelected) !== -1) {
          $(row).find('input[type="checkbox"]').prop('checked', true);
          $(row).addClass('selected');
        }
      },
      order: $(TABLE_ID).data('default-order'),
      columns: (function() {
        var numOfColumns = $(TABLE_ID).data('num-columns');
        var columns = $(TABLE_ID).data('default-table-columns');
        for (let i = 0; i < numOfColumns; i += 1) {
          if (columns[i] === undefined) {
            // This should only occur for custom columns
            columns[i] = { visible: true, searchable: true };
          }
          columns[i].data = String(i);
          columns[i].defaultContent = '';
        }
        return columns;
      }()),
      fnDrawCallback: function() {
        animateSpinner(this, false);
        changeToViewMode();
        updateButtons();
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

            // Fix the order - convert it from index-keyed JS object that
            // is returned from the server state into true JS array;
            // e.g. {0: [2, 'asc'], 1: [3, 'desc']}
            // is converted into [[2, 'asc'], [3, 'desc']]
            myData.order = _.toArray(myData.order);
          }
        });
        return myData;
      },
      stateSaveCallback: function(settings, data) {
        var stateData = data;
        // Send an Ajax request to the server with the state object
        var repositoryId = $(TABLE_ID).data('repository-id');
        // Save correct data
        if (loadFirstTime === true) {
          stateData = myData;
        }
        $.ajax({
          url: '/repositories/' + repositoryId + '/state_save',
          data: { state: stateData },
          dataType: 'json',
          type: 'POST'
        });
        loadFirstTime = false;
      },
      fnInitComplete: function(oSettings) {
        // First two columns are fixed
        TABLE.column(0).visible(true);
        TABLE.column(1).visible(true);

        // Reload correct column order and visibility (if you refresh page)
        for (let i = 2; i < TABLE.columns()[0].length; i += 1) {
          let visibility = false;
          if (myData.columns && myData.columns[i]) {
            visibility = myData.columns[i].visible;
          }
          if (typeof (visibility) === 'string') {
            visibility = (visibility === 'true');
          }
          TABLE.column(i).visible(visibility);
          TABLE.setColumnSearchable(i, visibility);
        }

        // Re-order table as per loaded state
        if (myData.order) {
          TABLE.order(myData.order);
          TABLE.draw();
        }

        // Datatables triggers this action about 3 times
        // sometimes on the first iteration the oSettings._colReorder is null
        // and the fnOrder rises an error that breaks the table
        // here I added a null guard for that case.
        // @todo we need to find out why the tables are loaded multiple times
        if (oSettings._colReorder) {
          oSettings._colReorder.fnOrder(myData.ColReorder);
        }
        initRowSelection();
        bindExportActions();
        disableCheckboxToggleOnAssetDownload();
        FilePreviewModal.init();
        initHeaderTooltip();
      }
    });

    // hack to replace filter placeholder
    $('.dataTables_filter .form-control').attr('placeholder', $('.dataTables_filter label').text())
    $('.dataTables_filter label').contents().filter(function(){
      return this.nodeType === 3;
    }).remove();

    // Handle click on table cells with checkboxes
    $(TABLE_ID).on('click', 'tbody td', function(e) {
      if ($(e.target).is('.repository-row-selector')) {
        // Skip if clicking on selector checkbox
        return;
      }
      if (!$(e.target).is('.record-info-link')) {
        // Skip if clicking on samples info link
        $(this).parent().find('.repository-row-selector').trigger('click');
      }
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
      $('div.toolbarButtonsDatatable').appendTo('div.toolbar');
      $('div.toolbarButtonsDatatable').show();

      // Append buttons for task inventory
      $('div.toolbarButtons').appendTo('div.toolbar');
      $('div.toolbarButtons').show();
    }, 10);

    return TABLE;
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
    SCINOTE_REPOSITORY_EDITED_ROWS = [];
    animateSpinner(null, false);
  };

  global.onClickAddRecord = function() {
    var tr = document.createElement('tr');

    checkAvailableColumns();
    changeToEditMode();
    updateButtons();

    saveAction = 'create';

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
      } else if ($(th).hasClass('repository-column')
                 && $(th).attr('data-type') === 'RepositoryTextValue') {
        input = changeToInputField('repository_cell', th.attr('id'), '');
        tr.appendChild(createTdElement(input));
      } else if ($(th).hasClass('repository-column')
                 && $(th).attr('data-type') === 'RepositoryListValue') {
        input = initialListItemsRequest($(th).attr('id'));
        tr.appendChild(createTdElement(input));
      } else if ($(th).hasClass('repository-column')
                 && $(th).attr('data-type') === 'RepositoryAssetValue') {
        input = changeToInputFileField('repository_cell_file', th.attr('id'), '');
        td = createTdElement(input);
        tr.appendChild(td);
        addSelectedFile($(th).attr('data-type'), '', $(td).find('input')[0]);
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

    // Init selectpicker
    initSelectPicker();
    // Adjust columns width in table header
    adjustTableHeader();
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
        onClickCancel();
        clearRowSelection();
      },
      error: function(data) {
        hideAssignUnasignModal('#assignRepositoryRecordModal');
        HelperModule.flashAlertMsg(data.responseJSON.flash, 'danger');
        onClickCancel();
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
        onClickCancel();
        clearRowSelection();
      },
      error: function(data) {
        hideAssignUnasignModal('#unassignRepositoryRecordModal');
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
      data: { selected_rows: rowsSelected },
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
  };

  // Edit record
  global.onClickEdit = function() {
    var row;
    var node;
    var rowData;

    checkAvailableColumns();
    if (rowsSelected.length !== 1) {
      return;
    }

    row = TABLE.row('#' + rowsSelected[0]);
    node = row.node();
    rowData = row.data();

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
        var editForm = new RepositoryItemEditForm(data, node);

        if (TABLE.column(1).visible() === false) {
          TABLE.column(1).visible(true);
        }
        // Show save and cancel buttons in first two columns
        $(node).children('td').eq(0).html($('#saveRecord').clone());
        $(node).children('td').eq(1).html($('#cancelSave').clone());

        editForm.renderForm(TABLE);
        initSelectPicker();
        editForm.initializeSelectpickerValues(node);

        // initialize smart annotation
        _.each($('[data-object="repository_cell"]'), function(el) {
          if (_.isUndefined($(el).data('atwho'))) {
            SmartAnnotation.init(el);
          }
        });
        // Adjust columns width in table header
        adjustTableHeader();
        updateButtons();

        SCINOTE_REPOSITORY_EDITED_ROWS.push(editForm);
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
  };

  function submitForm(url, formData) {
    var type;
    if (saveAction === 'update') {
      type = 'PUT';
    } else {
      type = 'POST';
    }
    $.ajax({
      url: url,
      type: type,
      dataType: 'json',
      data: formData,
      processData: false,
      contentType: false,
      success: function(data) {
        HelperModule.flashAlertMsg(data.flash, 'success');
        SmartAnnotation.closePopup();
        SCINOTE_REPOSITORY_EDITED_ROWS = [];
        onClickCancel();
        animateSpinner(null, false);
      },
      error: function(e) {
        var data = e.responseJSON;
        animateSpinner(null, false);
        SmartAnnotation.closePopup();
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
            let defaultFields = data.default_fields;

            // Validate record name
            if (defaultFields.name) {
              let input = $(selectedRecord).find('input[name = name]');

              if (input) {
                input.closest('.form-group').addClass('has-error');
                input.parent().append("<span class='help-block'>" + defaultFields.name + '<br /></span>');
              }
            }
          }

          // Validate custom cells
          $.each(data.repository_cells || [], function(_, val) {
            $.each(val, function(key, val2) {
              let input = $(selectedRecord).find('input[name=' + key + ']');
              if (input) {
                let message = Array.isArray(val2.data) ? val2.data[0] : val2.data;
                // handle custom input field
                if (input.attr('type') === 'file') {
                  let container = input.closest('.repository-input-file-field');
                  $(container.find('.form-group')[0]).addClass('has-error');
                  container.addClass('has-error');
                  container.append("<span class='help-block'>" + message + '<br /></span>');
                } else {
                  input.closest('.form-group').addClass('has-error');
                  input.parent().append("<span class='help-block'>" + message + '<br /></span>');
                }
              }
            });
          });
        }
      }
    });
  }

  function buildNewFormData() {
    return new Promise((resolve, reject) => {
      var node = selectedRecord;
      var formData = new FormData();
      var filesToUploadCntr = 0;
      var filesUploadedCntr = 0;
      const directUploadUrl = $(TABLE_ID).data('directUploadUrl');

      // First fetch all the data in input fields
      formData.append('request_url', $(TABLE_ID).data('current-uri'));
      formData.append('repository_row_id', $(selectedRecord).attr('id'));

      // Direct record attributes
      // Record name
      formData.append('repository_row_name', $('td input[data-object = repository_row]').val());

      // Custom cells text type
      $(node).find('td input[data-object = repository_cell]').each(function() {
        // Send data only and only if cell is not empty
        if ($(this).val().trim()) {
          formData.append('repository_cells[' + $(this).attr('name') + ']', $(this).val());
        }
      });

      // Custom cells list type
      $(node).find('td[column_id]').each(function(index, el) {
        var value = $(el).attr('list_item_id');
        formData.append('repository_cells[' + $(el).attr('column_id') + ']', value);
      });

      // Custom cells file type, first run, count files ready for upload
      $(node).find('td input[data-object = repository_cell_file]').each(function() {
        // Send data only and only if cell is not empty
        if ($(this)[0].files.length === 1) {
          filesToUploadCntr += 1;
        }
      });

      // No files for upload, so return earlier
      if (filesToUploadCntr === 0) {
        resolve(formData);
        return;
      }

      // Custom cells file type, second run, upload files
      $(node).find('td input[data-object = repository_cell_file]').each(function() {
        // Send data only and only if cell is not empty
        if ($(this)[0].files.length === 1) {
          let upload = new ActiveStorage.DirectUpload($(this)[0].files[0], directUploadUrl);
          let colId = $(this).attr('name');

          upload.create(function(error, blob) {
            if (error) {
              reject(error);
            } else {
              formData.append('repository_cells[' + colId + ']', blob.signed_id);
              filesUploadedCntr += 1;

              if (filesUploadedCntr === filesToUploadCntr) {
                resolve(formData);
              }
            }
          });
        }
      });
    });
  }

  // Save record
  global.onClickSave = function() {
    animateSpinner(null, true);
    if (saveAction === 'update') {
      let row = TABLE.row(selectedRecord);
      let rowData = row.data();
      SCINOTE_REPOSITORY_EDITED_ROWS[0].parseToFormObject(
        TABLE_ID, selectedRecord
      ).then(formData => {
        submitForm(rowData.recordUpdateUrl, formData);
      });
    } else if (saveAction === 'create') {
      buildNewFormData().then(formData => {
        submitForm($('table' + TABLE_ID).data('create-record'), formData);
      });
    }
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

  function generateColumnNameTooltip(name) {
    var maxLength = $(TABLE_ID).data('max-dropdown-length');
    if ($.trim(name).length > maxLength) {
      return '<div class="modal-tooltip">'
             + truncateLongString(name, maxLength)
             + '<span class="modal-tooltiptext">' + name + '</span></div>';
    }
    return name;
  }

  /*
   * Repository columns dropdown
   */

  function customLiHoverEffect() {
    var liEl = dropdownList.find('li');
    liEl.mouseover(function() {
      $(this).find('.grippy').addClass('grippy-img');
    }).mouseout(function() {
      $(this).find('.grippy').removeClass('grippy-img');
    });
  }

  function toggleColumnVisibility() {
    var lis = dropdownList.find('.vis');
    lis.on('click', function(event) {
      var self = $(this);
      var li = self.closest('li');
      var column = TABLE.column(li.attr('data-position'));

      event.stopPropagation();

      if (column.header.id !== 'row-name') {
        if (column.visible()) {
          self.addClass('fa-eye-slash');
          self.removeClass('fa-eye');
          li.addClass('col-invisible');
          column.visible(false);
          TABLE.setColumnSearchable(column.index(), false);
        } else {
          self.addClass('fa-eye');
          self.removeClass('fa-eye-slash');
          li.removeClass('col-invisible');
          column.visible(true);
          TABLE.setColumnSearchable(column.index(), true);
        }
      }
      // Re-filter/search if neccesary
      let searchText = $('div.dataTables_filter input').val();
      if (!_.isEmpty(searchText)) {
        TABLE.search(searchText).draw();
      }
      initRowSelection();
      FilePreviewModal.init();
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
        let colIndex = $(el).attr('data-column-index');
        let visible = TABLE.column(colIndex).visible();

        let visClass = (visible) ? 'fa-eye' : 'fa-eye-slash';
        let visLi = (visible) ? '' : 'col-invisible';

        let thederName;
        if ($(el).find('.modal-tooltiptext').length > 0) {
          thederName = $(el).find('.modal-tooltiptext').text();
        } else {
          thederName = el.innerText;
        }

        let listItem = dropdownList.find('.repository-columns-list-template').clone();

        listItem.attr('data-position', colIndex);
        listItem.attr('data-id', $(el).attr('id'));
        listItem.addClass(visLi);
        listItem.removeClass('repository-columns-list-template hide');
        listItem.find('.text').html(generateColumnNameTooltip(thederName));
        if (thederName !== 'Name') {
          listItem.find('.vis').addClass(visClass);
          listItem.find('.vis').attr('title', $(TABLE_ID).data('columns-visibility-text'));
        }
        dropdownList.append(listItem);
      }
    });
    // Restore scroll position
    dropdownList.scrollTop(scrollPosition);
    toggleColumnVisibility();
    // toggles grip img
    customLiHoverEffect();
  }

  function initSorting() {
    dropdownList.sortable({
      items: 'li:not(.repository-columns-list-template)',
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
        initRowSelection();
      }
    });
    $('.sorting').on('click', checkAvailableColumns);
  }

  // calculate the max height of window and adjust dropdown max-height
  function dropdownOverflow() {
    var windowHeight = $(window).height();
    var offset = windowHeight - dropdownList.offset().top;

    if (dropdownList.height() >= offset) {
      dropdownList.css('maxHeight', offset);
    }
  }

  // initialze dropdown after the table is loaded
  function initDropdown() {
    TABLE.on('init.dt', function() {
      dropdownList = $('#repository-columns-list');
      initSorting();
      toggleColumnVisibility();
    });
    $('#repository-columns-dropdown').on('show.bs.dropdown', function() {
      loadColumnsNames();
      dropdownList.sortable('enable');
      checkAvailableColumns();
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
    if (TABLE !== null) {
      TABLE.destroy();
      TABLE = null;
    }
    TABLE_ID = '';
  }

  function redrawTableOnSidebarToggle() {
    $('#sidebar-arrow').on('click', function() {
      setTimeout(function() {
        TABLE.draw();
      }, 250);
    });
  }

  return Object.freeze({
    init: init,
    destroy: destroy,
    redrawTableOnSidebarToggle: redrawTableOnSidebarToggle
  });
}(window));
