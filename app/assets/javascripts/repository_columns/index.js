/* global I18n HelperModule truncateLongString animateSpinner RepositoryListColumnType RepositoryStockColumnType */
/* global RepositoryDatatable RepositoryStatusColumnType RepositoryChecklistColumnType dropdownSelector RepositoryDateTimeColumnType */
/* global RepositoryDateColumnType RepositoryDatatable _ */
/* eslint-disable no-restricted-globals */


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
    RepositoryStockValue: 'RepositoryStockColumnType',
    RepositoryNumberValue: 'RepositoryNumberColumnType'
  };

  function reloadDataTablePartial() {
    // Append buttons for inventory datatable
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
    var status = true;
    var currentPartial = $('#repository-column-data-type').val();
    if ($('#repository-column-name').val().length === 0) {
      $('#repository-column-name').parent().addClass('error');
      status = false;
    } else {
      $('#repository-column-name').parent().removeClass('error');
    }
    if (columnTypeClassNames[currentPartial]) {
      status = eval(columnTypeClassNames[currentPartial]).checkValidation() && status;
    }
    return status;
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
        disableSearch: true,
        labelHTML: true
      };
      $.get(modalUrl, (data) => {
        var inputField = $manageModal.find('.modal-content').html(data.html)
          .find('#repository-column-name');
        var value = inputField.val()
        inputField.focus().val('').val(value);

        if (button.data('action') !== 'destroy') {
          columnType = $('#repository-column-data-type').val();
          dropdownSelector.init('#repository-column-data-type', {
            noEmptyOption: true,
            singleSelect: true,
            closeOnSelect: true,
            optionClass: 'custom-option',
            selectAppearance: 'simple',
            disableSearch: true,
            labelHTML: true,
            optionLabel: function(option) {
              return `<div class="column-type-option" data-disabled="${option.params.disabled}">
                        <span>${option.label}</span>
                        <span class="text-description">${option.params.text_description || ''}</span>
                      </div>`
            }
          });

          dropdownSelector.init('.list-column-type .delimiter', delimiterDropdownConfig);
          RepositoryListColumnType.initListDropdown();
          RepositoryListColumnType.initListPlaceholder();

          RepositoryDateTimeColumnType.initReminderUnitDropdown();
          RepositoryDateColumnType.initReminderUnitDropdown();

          dropdownSelector.init('.checklist-column-type .delimiter', delimiterDropdownConfig);
          RepositoryChecklistColumnType.initChecklistDropdown();
          RepositoryChecklistColumnType.initChecklistPlaceholder();

          RepositoryStockColumnType.initStockUnitDropdown();

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

  function toggleColumnVisibility() {
    $(columnsList).find('.vis').on('click', function(event) {
      const $this = $(this);
      const li = $this.closest('li');
      const column = TABLE.column(li.attr('data-position'));

      event.stopPropagation();
      if (!['row-name', 'archived-by', 'archived-on'].includes(column.header().id)) {
        if (column.visible()) {
          $this.addClass('sn-icon-visibility-hide');
          $this.removeClass('sn-icon-visibility-show');
          li.addClass('col-invisible');
          column.visible(false);
          TABLE.setColumnSearchable(column.index(), false);
        } else {
          $this.addClass('sn-icon-visibility-show');
          $this.removeClass('sn-icon-visibility-hide');
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
      const scrollBody = $('.dataTables_scrollBody');
      if (scrollBody[0].offsetWidth > scrollBody[0].clientWidth) {
        scrollBody.css('width', `calc(100% + ${scrollBody[0].offsetWidth - scrollBody[0].clientWidth}px)`);
      }
    });
  }

  function getColumnTypeText(el) {
    let colType = $(el).attr('data-type');
    if (!colType) return '';

    return I18n.t('libraries.manange_modal_column.select.' + colType.split(/(?=[A-Z])/).join('_')
      .toLowerCase());
  }

  // loads the columns names in the manage columns modal index
  function loadColumnsNames() {
    var $columnsList = $(columnsList);
    var scrollPosition = $columnsList.scrollTop();
    // Clear the list
    $columnsList.find('li[data-position]').remove();
    _.each(TABLE.columns().header(), (el) => {
      if (!el.dataset.unmanageable) {
        let colId = $(el).attr('id');
        let colIndex = $(el).attr('data-column-index');
        let visible = TABLE.column(colIndex).visible();
        let visClass = (visible) ? 'sn-icon-visibility-show' : 'sn-icon-visibility-hide';
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
        thederName = _.escape(thederName);

        if (['row-name', 'archived-by', 'archived-on'].includes(el.id)) {
          visClass = '';
          visText = '';
        }

        let destroyButton = '';

        if (destroyUrl) {
          destroyButton = `<button class="btn icon-btn btn-light btn-xs delete-repo-column manage-repo-column"
                              data-action="destroy"
                              data-modal-url="${destroyUrl}">
                              <span class="sn-icon sn-icon-delete" title="Delete"></span>
                          </button>`;
        }

        let listItem = `<li class="col-list-el ${visLi} ${customColumn} ${editableRow}" data-position="${colIndex}" data-id="${colId}">
          <i class="grippy sn-icon sn-icon-drag"></i>
          <span class="vis-controls">
            <span class="vis sn-icon ${visClass}" title="${visText}"></span>
          </span>
          <div class="text truncate" title="${thederName}">${thederName}</div>
          <span class="column-type pull-right shrink-0">${
            getColumnTypeText(el, colId) || '<i class="sn-icon sn-icon-locked-task"></i>'
          }</span>
          <span class="sci-btn-group manage-controls pull-right" data-view-mode="active">
            <button class="btn icon-btn btn-light btn-xs edit-repo-column manage-repo-column"
                    data-action="edit"
                    data-modal-url="${editUrl}">
              <span class="sn-icon sn-icon-edit" title="Edit"></span>
            </button>
            ${destroyButton}
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
    $manageModal.on('click', '.back-to-column-modal', function(e) {
      e.stopImmediatePropagation();
      var button = $(this);
      initManageColumnModal(button);
    });
  }

  function initColumnsButton() {
    $(document).on('click', '.manage-repo-column-index', function(e) {
      e.stopImmediatePropagation();
      var button = $(this);
      initManageColumnModal(button);
    });
  }

  return {
    init: () => {
      initColumnTypeSelector();
      initCreateSubmitAction();
      initEditSubmitAction();
      initDeleteSubmitAction();
      initBackToManageColumns();
      initColumnsButton();
      initManageColumnAction();
      RepositoryListColumnType.init();
      RepositoryStatusColumnType.init();
      RepositoryStockColumnType.init();
      RepositoryChecklistColumnType.init();
      RepositoryDateTimeColumnType.init();
      RepositoryDateColumnType.init();
    }
  };
}());



$(document).on('turbolinks:load', function() {
  RepositoryColumns.init();
});
