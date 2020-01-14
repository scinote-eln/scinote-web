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

    // destroy datatable and remove partial
    TABLE.destroy();
    $('.repository-table').remove();

    // reload datatable partial and intialize DataTable
    $.get($('.repository-show').data('table-url'), (response) => {
      $(response.html).appendTo($('.repository-show'));
      RepositoryDatatable.init('#' + $('.repository-table table').attr('id'));
      RepositoryDatatable.redrawTableOnSidebarToggle();
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
          // show manage columns index modal
          $manageModal.find('.back-to-column-modal').trigger('click');

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
          // show manage columns index modal
          $manageModal.find('.back-to-column-modal').trigger('click');

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
          // show manage columns index modal
          $manageModal.find('.back-to-column-modal').trigger('click');

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
      $.get(modalUrl, (data) => {
        $manageModal.find('.modal-content').html(data.html)
          .find('#repository-column-name')
          .focus();
        columnType = $('#repository-column-data-type').val();
        dropdownSelector.init('#repository-column-data-type', {
          noEmptyOption: true,
          singleSelect: true,
          closeOnSelect: true,
          optionClass: 'custom-option',
          selectAppearance: 'simple'
        });
        $manageModal
          .trigger('columnModal::partialLoadedFor' + columnType);

        if (button.data('action') === 'new') {
          $('[data-column-type="RepositoryTextValue"]').show();
          $('#new-repo-column-submit').show();
        } else {
          $('#update-repo-column-submit').show();
          $('[data-column-type=' + columnType + ']').show();
        }
      }).fail(function() {
        HelperModule.flashAlertMsg(I18n.t('libraries.repository_columns.no_permissions'), 'danger');
      });
    });
  }

  function generateColumnNameTooltip(name) {
    var maxLength = $(TABLE_ID).data('max-dropdown-length');
    if ($.trim(name).length > maxLength) {
      return '<div class="modal-tooltip">'
             + truncateLongString(name, maxLength)
             + '<span class="modal-tooltiptext">' + name + '</span></div>';
    }
    return name;
  }

  function customLiHoverEffect() {
    var liEl = $(columnsList).find('li');
    liEl.mouseover(function() {
      $(this).find('.grippy').addClass('grippy-img');
    }).mouseout(function() {
      $(this).find('.grippy').removeClass('grippy-img');
    });
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

        let listItem = $columnsList.find('.repository-columns-list-template').clone();

        let repoId = $(TABLE_ID).data('repository-id');
        let colId = $(el).attr('id');
        let actionUrl = '/repositories/' + repoId + '/repository_columns/' + colId;

        listItem.attr('data-position', colIndex);
        listItem.attr('data-id', colId);
        listItem.addClass(visLi);
        listItem.removeClass('repository-columns-list-template hide');

        if ($(el).attr('data-type')) {
          listItem.addClass('editable');
          listItem.find('.manage-controls').addClass('editable');
          listItem.find('[data-action="edit"]').attr('data-modal-url', actionUrl + '/edit');
          listItem.find('[data-action="destroy"]').attr('data-modal-url', actionUrl + '/destroy_html');
        }
        listItem.find('.column-type').html(getColumnTypeText(el, colId));

        listItem.find('.text').html(generateColumnNameTooltip(thederName));
        if (thederName !== 'Name') {
          listItem.find('.vis').addClass(visClass);
          listItem.find('.vis').attr('title', $(TABLE_ID).data('columns-visibility-text'));
        }
        $columnsList.append(listItem);
      }
    });
    $columnsList.scrollTop(scrollPosition);
    toggleColumnVisibility();
    customLiHoverEffect();
  }

  function initSorting() {
    var $columnsList = $(columnsList);
    $columnsList.sortable({
      items: 'li:not(.repository-columns-list-template)',
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
    $('.sorting').on('click', RepositoryDatatable.checkAvailableColumns());
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
