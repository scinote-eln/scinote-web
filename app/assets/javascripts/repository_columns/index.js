/* global I18n HelperModule truncateLongString animateSpinner RepositoryListColumnType */
/* global RepositoryDatatable RepositoryStatusColumnType RepositoryChecklistColumnType dropdownSelector */
/* eslint-disable no-restricted-globals */

//= require jquery-ui/widgets/sortable

var RepositoryColumns = (function() {
  var TABLE_ID = '';
  var TABLE = null;
  var columnsList = '#repository-columns-list';
  var manageModal = '#manage-repository-column';
  var columnTypeClassNames = {
    RepositoryListValue: 'RepositoryListColumnType',
    RepositoryStatusValue: 'RepositoryStatusColumnType',
    RepositoryDateValue: 'RepositoryDateColumnType',
    RepositoryDateTimeValue: 'RepositoryDateTimeColumnType',
    RepositoryTimeValue: 'RepositoryTimeColumnType',
    RepositoryChecklistValue: 'RepositoryChecklistColumnType',
    RepositoryNumberValue: 'RepositoryNumberColumnType'
  };

  function reloadDataTablePartial() {
    // Append buttons for inventory datatable
    $('div.toolbarButtonsDatatable').appendTo('.repository-show');
    $('div.toolbarButtonsDatatable').hide();

    $('div.toolbar-filter-buttons').appendTo('.repository-show');
    $('div.toolbar-filter-buttons').hide();

    // destroy datatable and remove partial
    TABLE.destroy();
    $('.repository-table').remove();

    // reload datatable partial and intialize DataTable
    $.get($('.repository-show').data('table-url'), (response) => {
      $(response.html).appendTo($('.repository-show'));
      RepositoryDatatable.init('#' + $('.repository-table table').attr('id'));
      RepositoryDatatable.redrawTableOnSidebarToggle();
      // show manage columns index modal
      setTimeout(function() {
        $(manageModal).find('.back-to-column-modal').trigger('click');
      }, 500);
    });
  }

  function initColumnTypeSelector() {
    var $manageModal = $(manageModal);
    $manageModal.on('change', '#repository-column-data-type', function() {
      $('.column-type').hide();
      $('[data-column-type="' + $(this).val() + '"]').show();
    });
  }

  function initDeleteSubmitAction() {
    var $manageModal = $(manageModal);
    $manageModal.on('click', '#delete-repo-column-submit', function() {
      animateSpinner();
      $.ajax({
        url: $(this).data('delete-url'),
        type: 'DELETE',
        dataType: 'json',
        success: (result) => {
          reloadDataTablePartial();
          animateSpinner(null, false);
          HelperModule.flashAlertMsg(result.message, 'success');
        },
        error: (result) => {
          animateSpinner(null, false);
          HelperModule.flashAlertMsg(result.responseJSON.error, 'danger');
        }
      });
    });
  }

  function checkData() {
    var currentPartial = $('#repository-column-data-type').val();

    if (columnTypeClassNames[currentPartial]) {
      return eval(columnTypeClassNames[currentPartial])
        .checkValidation();
    }
    return true;
  }

  function addSpecificParams(type, params) {
    var allParams = params;
    var columnParams;
    var specificParams;
    var currentPartial = $('#repository-column-data-type').val();

    if (columnTypeClassNames[currentPartial]) {
      specificParams = eval(columnTypeClassNames[currentPartial]).loadParams();
      columnParams = Object.assign(params.repository_column, specificParams);
      allParams.repository_column = columnParams;
    }

    return allParams;
  }

  function initCreateSubmitAction() {
    var $manageModal = $(manageModal);
    $manageModal.on('click', '#new-repo-column-submit', function() {
      var url = $('#repository-column-data-type').find(':selected').data('create-url');
      var params = { repository_column: { name: $('#repository-column-name').val() } };
      var selectedType = $('#repository-column-data-type').val();
      params = addSpecificParams(selectedType, params);
      if (!checkData()) return;

      $.ajax({
        url: url,
        type: 'POST',
        data: JSON.stringify(params),
        contentType: 'application/json',
        success: function(result) {
          reloadDataTablePartial();
          HelperModule.flashAlertMsg(result.data.attributes.message, 'success');
        },
        error: function(error) {
          $('#new-repository-column').renderFormErrors('repository_column', error.responseJSON.repository_column, true);
        }
      });
    });
  }

  function initEditSubmitAction() {
    var $manageModal = $(manageModal);
    $manageModal.on('click', '#update-repo-column-submit', function() {
      var url = $('#repository-column-data-type').find(':selected').data('edit-url');
      var params = { repository_column: { name: $('#repository-column-name').val() } };
      var selectedType = $('#repository-column-data-type').val();
      params = addSpecificParams(selectedType, params);
      if (!checkData()) return;

      $.ajax({
        url: url,
        type: 'PUT',
        data: JSON.stringify(params),
        dataType: 'json',
        contentType: 'application/json',
        success: function(result) {
          reloadDataTablePartial();
          HelperModule.flashAlertMsg(result.data.attributes.message, 'success');
        },
        error: function(error) {
          $('#new-repository-column').renderFormErrors('repository_column', error.responseJSON.repository_column, true);
        }
      });
    });
  }

  function initManageColumnAction() {
    var $manageModal = $(manageModal);
    $manageModal.on('click', '.manage-repo-column', function() {
      var button = $(this);
      var modalUrl = button.data('modal-url');
      var columnType;
      var delimiterOptionsRender = function(data) {
        return `<span class='icon'>${data.params.icon}</span>${data.label}`;
      };
      var delimiterDropdownConfig = {
        singleSelect: true,
        noEmptyOption: true,
        selectAppearance: 'simple',
        closeOnSelect: true,
        optionClass: 'delimiter-icon-dropdown',
        optionLabel: delimiterOptionsRender,
        tagClass: 'delimiter-icon-dropdown',
        tagLabel: delimiterOptionsRender,
        disableSearch: true
      };
      $.get(modalUrl, (data) => {
        $manageModal.find('.modal-content').html(data.html)
          .find('#repository-column-name')
          .focus();

        if (button.data('action') !== 'destroy') {
          columnType = $('#repository-column-data-type').val();
          dropdownSelector.init('#repository-column-data-type', {
            noEmptyOption: true,
            singleSelect: true,
            closeOnSelect: true,
            optionClass: 'custom-option',
            selectAppearance: 'simple',
            disableSearch: true
          });

          dropdownSelector.init('.list-column-type .delimiter', delimiterDropdownConfig);
          RepositoryListColumnType.initListDropdown();
          RepositoryListColumnType.initListPlaceholder();

          dropdownSelector.init('.checklist-column-type .delimiter', delimiterDropdownConfig);
          RepositoryChecklistColumnType.initChecklistDropdown();
          RepositoryChecklistColumnType.initChecklistPlaceholder();

          $manageModal
            .trigger('columnModal::partialLoadedFor' + columnType);

          RepositoryStatusColumnType.updateLoadedEmojies();

          if (button.data('action') === 'new') {
            $('[data-column-type="RepositoryTextValue"]').show();
            $('#new-repo-column-submit').show();
          } else {
            $('#update-repo-column-submit').show();
            $('[data-column-type="' + columnType + '"]').show();
          }
        }
      }).fail(function() {
        HelperModule.flashAlertMsg(I18n.t('libraries.repository_columns.no_permissions'), 'danger');
      });
    });
  }

  function generateColumnNameTooltip(name) {
    var maxLength = $(TABLE_ID).data('max-dropdown-length');
    if ($.trim(name).length > maxLength) {
      return `<div class="modal-tooltip">
                ${truncateLongString(name, maxLength)}
                <span class="modal-tooltiptext">${name}</span>
              </div>`;
    }
    return name;
  }

  function toggleColumnVisibility() {
    var lis = $(columnsList).find('.vis');
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
    });
  }

  function getColumnTypeText(el, colId) {
    var colType = '';
    switch (colId) {
      case 'row-id':
        colType = 'RepositoryNumberValue';
        break;
      case 'row-name':
        colType = 'RepositoryTextValue';
        break;
      case 'added-on':
        colType = 'RepositoryDateTimeValue';
        break;
      case 'added-by':
        colType = 'RepositoryListValue';
        break;
      default:
        colType = $(el).attr('data-type');
    }
    return I18n.t('libraries.manange_modal_column.select.' + colType.split(/(?=[A-Z])/).join('_').toLowerCase());
  }

  // loads the columns names in the manage columns modal index
  function loadColumnsNames() {
    var $columnsList = $(columnsList);
    var scrollPosition = $columnsList.scrollTop();
    // Clear the list
    $columnsList.find('li[data-position]').remove();
    _.each(TABLE.columns().header(), function(el, index) {
      if (index > 1) {
        let colId = $(el).attr('id');
        let colIndex = $(el).attr('data-column-index');
        let visible = TABLE.column(colIndex).visible();
        let visClass = (visible) ? 'fa-eye' : 'fa-eye-slash';
        let visLi = (visible) ? '' : 'col-invisible';
        let visText = $(TABLE_ID).data('columns-visibility-text');
        let customColumn = ($(el).attr('data-type')) ? 'editable' : '';
        let editableRow = ($(el).attr('data-editable-row') === 'true') ? 'has-permissions' : '';
        let editUrl = $(el).attr('data-edit-column-url');
        let destroyUrl = $(el).attr('data-destroy-column-url');
        let thederName;
        if ($(el).find('.modal-tooltiptext').length > 0) {
          thederName = $(el).find('.modal-tooltiptext').text();
        } else {
          thederName = el.innerText;
        }
        if (thederName === 'Name') {
          visClass = '';
          visText = '';
        }
        let listItem = `<li class="col-list-el ${visLi} ${customColumn} ${editableRow}" data-position="${colIndex}" data-id="${colId}">
          <i class="grippy"></i>
          <span class="vis-controls">
            <span class="vis fas ${visClass}" title="${visText}"></span>
          </span>
          <span class="text">${generateColumnNameTooltip(thederName)}</span>
          <span class="column-type pull-right">${getColumnTypeText(el, colId)}</span>
          <span class="sci-btn-group manage-controls pull-right">
            <button class="btn icon-btn btn-light edit-repo-column manage-repo-column"
                    data-action="edit"
                    data-modal-url="${editUrl}">
              <span class="fas fa-pencil-alt" title="Edit"></span>
            </button>
            <button class="btn icon-btn btn-light delete-repo-column manage-repo-column"
                    data-action="destroy"
                    data-modal-url="${destroyUrl}">
              <span class="fas fa-trash" title="Delete"></span>
            </button>
          </span>
          <br>
        </li>`;

        $columnsList.append(listItem);
      }
    });
    $columnsList.scrollTop(scrollPosition);
    toggleColumnVisibility();
  }

  function initSorting() {
    var $columnsList = $(columnsList);
    $columnsList.sortable({
      items: 'li',
      scrollSpeed: 10,
      axis: 'y',
      update: function() {
        var reorderer = TABLE.colReorder;
        var listIds = [];
        // We skip first two columns
        listIds.push(0, 1);
        $columnsList.find('li[data-position]').each(function() {
          listIds.push($(this).first().data('position'));
        });
        reorderer.order(listIds, false);
        loadColumnsNames();
      }
    });
  }

  function initManageColumnModal(button) {
    var modalUrl = button.data('modal-url');
    $.get(modalUrl, (data) => {
      // show modal
      $(manageModal).modal('show').find('.modal-content').html(data.html);

      TABLE_ID = '#repository-table-' + data.id;
      TABLE = $(TABLE_ID).DataTable();

      initSorting();
      toggleColumnVisibility();
      loadColumnsNames();
      RepositoryDatatable.checkAvailableColumns();
    }).fail(function() {
      HelperModule.flashAlertMsg(I18n.t('libraries.repository_columns.no_permissions'), 'danger');
    });
  }

  function initBackToManageColumns() {
    var $manageModal = $(manageModal);
    $manageModal.on('click', '.back-to-column-modal', function() {
      var button = $(this);
      initManageColumnModal(button);
    });
  }

  function initColumnsButton() {
    $('.repo-datatables-buttons').on('click', '.manage-repo-column-index', function() {
      var button = $(this);
      initManageColumnModal(button);
    });
  }

  return {
    init: () => {
      if ($('.repo-datatables-buttons').length > 0) {
        initColumnTypeSelector();
        initCreateSubmitAction();
        initEditSubmitAction();
        initDeleteSubmitAction();
        initBackToManageColumns();
        initColumnsButton();
        initManageColumnAction();
        RepositoryListColumnType.init();
        RepositoryStatusColumnType.init();
        RepositoryChecklistColumnType.init();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  RepositoryColumns.init();
});
