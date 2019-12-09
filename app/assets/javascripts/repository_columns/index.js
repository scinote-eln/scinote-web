/* global I18n HelperModule animateSpinner RepositoryListColumnType */
/* global RepositoryStatusColumnType dropdownSelector */
/* eslint-disable no-restricted-globals */
var RepositoryColumns = (function() {
  var manageModal = '#manage-repository-column';
  var columnTypeClassNames = {
    RepositoryListValue: 'RepositoryListColumnType',
    RepositoryStatusValue: 'RepositoryStatusColumnType',
    RepositoryDateValue: 'RepositoryDateColumnType',
    RepositoryDateTimeValue: 'RepositoryDateTimeColumnType',
    RepositoryTimeValue: 'RepositoryDateTimeColumnType',
    RepositoryChecklistValue: 'RepositoryChecklistColumnType'
  };

  function initColumnTypeSelector() {
    var $manageModal = $(manageModal);
    $manageModal.on('change', '#repository-column-data-type', function() {
      $('.column-type').hide();
      $('[data-column-type="' + $(this).val() + '"]').show();
    });
  }

  function removeElementFromDom(column) {
    $('.repository-column-edtior .list-group-item[data-id="' + column.id + '"]').remove();
    if ($('.list-group-item').length === 0) {
      location.reload();
    }
  }

  function initDeleteSubmitAction() {
    var $manageModal = $(manageModal);
    $manageModal.on('click', '#delete-repo-column-submit', function() {
      animateSpinner();
      $manageModal.modal('hide');
      $.ajax({
        url: $(this).data('delete-url'),
        type: 'DELETE',
        dataType: 'json',
        success: (result) => {
          removeElementFromDom(result);
          HelperModule.flashAlertMsg(result.message, 'success');
          animateSpinner(null, false);
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

  function insertNewListItem(column) {
    var attributes = column.attributes;
    var html = `<li class="list-group-item row" data-id="${column.id}">

                  <div class="col-xs-8">
                    <span class="pull-left column-name">${attributes.name}</span>
                  </div>
                  <div class="col-xs-4">
                    <span class="controlls pull-right">
                      <button class="btn btn-default edit-repo-column manage-repo-column" 
                              data-action="edit"
                              data-modal-url="${attributes.edit_html_url}"
                      >
                      <span class="fas fa-pencil-alt"></span>
                        ${ I18n.t('libraries.repository_columns.index.edit_column')}
                      </button>
                      <button class="btn btn-default delete-repo-column manage-repo-column" 
                              data-action="destroy"
                              data-modal-url="${attributes.destroy_html_url}"
                      >
                        <span class="fas fa-trash-alt"></span>
                        ${ I18n.t('libraries.repository_columns.index.delete_column')}
                      </button>
                    </span>
                  </div>
                </li>`;

    // remove element if already persent
    $('[data-id="' + column.id + '"]').remove();
    $(html).insertBefore('.repository-columns-body ul li:first');
    // remove 'no column' list item
    $('[data-attr="no-columns"]').remove();
  }

  function updateListItem(column) {
    var name = column.attributes.name;
    $('li[data-id=' + column.id + ']').find('span').first().html(name);
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
          var data = result.data;
          insertNewListItem(data);
          HelperModule.flashAlertMsg(data.attributes.message, 'success');
          $manageModal.modal('hide');
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
          var data = result.data;
          updateListItem(data);
          HelperModule.flashAlertMsg(data.attributes.message, 'success');
          $manageModal.modal('hide');
        },
        error: function(error) {
          $('#new-repository-column').renderFormErrors('repository_column', error.responseJSON.repository_column, true);
        }
      });
    });
  }

  function initManageColumnModal() {
    var $manageModal = $(manageModal);
    $('.repository-column-edtior').on('click', '.manage-repo-column', function() {
      var button = $(this);
      var modalUrl = button.data('modal-url');
      var columnType;
      $.get(modalUrl, (data) => {
        $manageModal.modal('show').find('.modal-content').html(data.html)
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

  return {
    init: () => {
      if ($('.repository-columns-header').length > 0) {
        initColumnTypeSelector();
        initEditSubmitAction();
        initCreateSubmitAction();
        initDeleteSubmitAction();
        initManageColumnModal();
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
