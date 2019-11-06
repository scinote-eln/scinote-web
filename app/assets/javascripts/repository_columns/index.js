/* global I18n HelperModule animateSpinner RepositoryListColumnType */
/* eslint-disable no-restricted-globals */
var RepositoryColumns = (function() {
  var manageModal = '#manageRepositoryColumn';

  function initColumnTypeSelector() {
    var $manageModal = $(manageModal);
    $manageModal.off('change', '#repository-column-data-type').on('change', '#repository-column-data-type', function() {
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
    $manageModal.off('click', '#delete-repo-column-submit').on('click', '#delete-repo-column-submit', function() {
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
    $('li[data-id=' + column.id + ']').find('span').first().text(name);
  }

  function loadSpecificParams(type, params) {
    var newParams = params;
    if (type === 'RepositoryListValue') {
      newParams.repository_column.repository_list_items_attributes = JSON.parse($('#dropdown_options').val());
      newParams.repository_column.delimiter = $('select#delimiter').data('used-delimiter');
    }
    return newParams;
  }

  function initCreateSubmitAction() {
    var $manageModal = $(manageModal);
    $manageModal.off('click', '#new-repo-column-submit').on('click', '#new-repo-column-submit', function() {
      var url = $('#repository-column-data-type').find(':selected').data('create-url');
      var params = { repository_column: { name: $('#repository-column-name').val() } };
      var selectedType = $('#repository-column-data-type').find(':selected').val();
      params = loadSpecificParams(selectedType, params);
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
    $manageModal.off('click', '#update-repo-column-submit').on('click', '#update-repo-column-submit', function() {
      var url = $('#repository-column-data-type').find(':selected').data('edit-url');
      var params = { repository_column: { name: $('#repository-column-name').val() } };
      var selectedType = $('#repository-column-data-type').find(':selected').val();
      params = loadSpecificParams(selectedType, params);
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
    $('.repository-column-edtior').off('click', '.manage-repo-column').on('click', '.manage-repo-column', function() {
      var button = $(this);
      var modalUrl = button.data('modal-url');
      var columnType;
      $.get(modalUrl, (data) => {
        $manageModal.modal('show').find('.modal-content').html(data.html)
          .find('#repository-column-name')
          .focus();
        $manageModal.trigger('columnModal::partialLoaded');

        if (button.data('action') === 'new') {
          $('[data-column-type="RepositoryTextValue"]').show();
          $('#new-repo-column-submit').show();
        } else {
          columnType = $('#repository-column-data-type').find(':selected').val();
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
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  RepositoryColumns.init();
});
