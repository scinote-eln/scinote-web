/* global I18n HelperModule animateSpinner */
/* eslint-disable no-restricted-globals */
var RepositoryColumns = (function() {
  var manageModal = '#manageRepositoryColumn';

  function initColumnTypeSelector() {
    var $manageModal = $(manageModal);
    $manageModal.off('click', '#repository-column-data-type').on('click', '#repository-column-data-type', function() {
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

  function initCreateSubmitAction() {
    var $manageModal = $(manageModal);
    $manageModal.off('click', '#new-repo-column-submit').on('click', '#new-repo-column-submit', function() {
      var url = $('#repository-column-data-type').find(':selected').data('create-url');
      var params = { repository_column: { name: $('#repository-column-name').val() } };
      $.post(url, params, (result) => {
        var data = result.data;
        insertNewListItem(data);
        HelperModule.flashAlertMsg(data.attributes.message, 'success');
        $manageModal.modal('hide');
      }).error((error) => {
        $('#new-repository-column').renderFormErrors('repository_column', error.responseJSON.repository_column, true);
      });
    });
  }

  function initEditSubmitAction() {
    var $manageModal = $(manageModal);
    $manageModal.off('click', '#new-repo-column-submit').on('click', '#new-repo-column-submit', function() {
      // TODO
    });
  }

  function initManageColumnModal() {
    var $manageModal = $(manageModal);
    $('.repository-column-edtior').off('click', '.manage-repo-column').on('click', '.manage-repo-column', function() {
      var button = $(this);
      var modalUrl = button.data('modal-url');
      $.get(modalUrl, (data) => {
        $manageModal.modal('show').find('.modal-content').html(data.html)
          .find('#repository-column-name')
          .focus();

        if (button.data('action') === 'new') {
          $('[data-column-type="RepositoryTextValue"]').show();
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
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  RepositoryColumns.init();
});
