/* global I18n HelperModule truncateLongString animateSpinner RepositoryListColumnType RepositoryStockColumnType */
/* global RepositoryDatatable RepositoryStatusColumnType RepositoryChecklistColumnType dropdownSelector RepositoryDateTimeColumnType */
/* global RepositoryDateColumnType RepositoryDatatable _ */
/* eslint-disable no-restricted-globals */


var RepositoryColumns = (function() {
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
    $(manageModal).modal('hide');
    window.repositoryTableComponent.$refs.tableContainer.legacyReloadTableComponent();
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
              return `<div class="column-type-option" data-e2e="${option.params.data_e2e || ''}" data-disabled="${option.params.disabled}">
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

  // loads the columns names in the manage columns modal index
  function loadColumnsNames() {
    var $columnsList = $(columnsList);
    var scrollPosition = $columnsList.scrollTop();
    // Clear the list



    const columns = window.repositoryTableComponent.$refs.tableContainer.legacyColumnsHTML()

    $columnsList.html = '';

    if (columns.length > 0) {
      columns.forEach((column, index) => {
        $columnsList.append(column);
      })
    } else {
      $columnsList.append(
        `<li class="w-full text-center pt-10">
          ${I18n.t('libraries.repository_columns.empty_placeholder')}
        </li>`
      )
    }

    $columnsList.scrollTop(scrollPosition);
  }

  function initManageColumnModal(button) {
    var modalUrl = button.data('modal-url');
    $.get(modalUrl, (data) => {
      // show modal
      $(manageModal).modal('show').find('.modal-content').html(data.html);
      loadColumnsNames();
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
