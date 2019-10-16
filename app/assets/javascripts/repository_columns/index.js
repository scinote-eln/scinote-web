/* global I18n HelperModule animateSpinner */
/* no-restricted-globals */
var RepositoryColumns = (function() {
  function initColumnTypeSelector() {
    $('#repository_column_data_type')
      .on('click', function() {
        $('.column-type').hide();
        $('[data-column-type="' + $(this).val() + '"]').show();
      });
  }

  // function replaceListItem(column) {
  //   $('.list-group-item[data-id="' + column.id + '"]')
  //     .find('span.pull-left').text(column.name);
  // }
  //
  // function initTagInput() {
  //   $('[data-role="tagsinput"]').tagsinput({
  //     maxChars: GLOBAL_CONSTANTS.NAME_MAX_LENGTH,
  //     trimValue: true
  //   });
  // }
  //
  // function processResponse(form, action, modalID) {
  //   form.on('ajax:success', function(e, data) {
  //     switch (action) {
  //       case 'destroy':
  //         removeElementFromDom(data);
  //         break;
  //       case 'create':
  //         break;
  //       case 'update':
  //         replaceListItem(data);
  //         break;
  //       default:
  //         location.reload();
  //     }
  //     HelperModule.flashAlertMsg(data.message, 'success');
  //     animateSpinner(null, false);
  //     if (modalID) {
  //       $(modalID).modal('hide');
  //     }
  //   }).on('ajax:error', function(e, xhr) {
  //     animateSpinner(null, false);
  //     if (modalID) {
  //       if (xhr.responseJSON.message.hasOwnProperty('repository_list_items')) {
  //         var message = xhr.responseJSON.message['repository_list_items'];
  //         $('.dnd-error').remove();
  //         $('#manageRepositoryColumn ').find('.bootstrap-tagsinput').after(
  //           "<i class='dnd-error'>" + message + "</i>"
  //         );
  //       } else {
  //         var field = { "name": xhr.responseJSON.message };
  //         $(form).renderFormErrors('repository_column', field, true, e);
  //       }
  //     } else {
  //       HelperModule.flashAlertMsg(xhr.responseJSON.message, 'danger');
  //     }
  //   });
  //   if (modalID) {
  //     form.submit();
  //   }
  // }

  // @TODO refactor that
  function initEditCoumnModal() {
    var modalID = '#manageRepositoryColumn';
    // var colRadID = '#repository_column_data_type_repositorylistvalue';
    // var tagsInputID = '[data-role="tagsinput"]';
    // var formID = '[data-role="manage-repository-column-form"]';
    $('.repository-columns-body').off('click', '.edit-repo-column').on('click', '.edit-repo-column', function() {
      var editUrl = $(this).closest('li').attr('data-edit-url');
      $.get(editUrl, function(data) {
        $(modalID).find('.modal-content').html(data.html);
        $(modalID).modal('show');

        initColumnTypeSelector();
        $('#repository_column_data_type').val($(modalID).find('#new_repository_column').attr('data-edit-type')).trigger('click');
        $('#repository_column_data_type').prop('disabled', true);
        setTimeout(function() {
          $('#repository_column_name').focus();
        }, 500);

        // if ($(modalID).attr('data-edit-type') === 'RepositoryListValue') {
        //   var values = JSON.parse($(tagsInputID).attr('data-value'));
        //   $('#repository_column_data_type').val('RepositoryListValue');
        //   $(colRadID).click().promise().done(function() {
        //     $.each(tagsInputValues, function(index, element) {
        //       $(tagsInputID).tagsinput('add', element);
        //     });
        //   });
        // }

        $('#new-repo-column-submit').on('click', function() {
          // if ($('#repository_column_data_type').val() === 'RepositoryListValue') {
          //   $('#list_items').val($(tagsInputID).val());
          // }
          //
          // processResponse($(formID), 'update', modalID);
        });
      }).fail(function() {
        HelperModule.flashAlertMsg(
          I18n.t('libraries.repository_columns.no_permissions'), 'danger'
        );
      });
    });
  }

  function removeElementFromDom(column) {
    $('.list-group-item[data-id="' + column.id + '"]').remove();
    if ($('.list-group-item').length === 0) {
      location.reload();
    }
  }

  function initDeleteSubmitAction(modal, form) {
    modal.find('#delete-repo-column-submit').on('click', function() {
      form.submit();
      modal.modal('hide');
      animateSpinner();
      form.on('ajax:success', function(e, data) {
        removeElementFromDom(data);
        HelperModule.flashAlertMsg(data.message, 'success');
        animateSpinner(null, false);
      }).on('ajax:error', function(e, xhr) {
        animateSpinner(null, false);
        HelperModule.flashAlertMsg(xhr.responseJSON.message, 'danger');
      });
    });
  }

  function initDeleteColumnModal() {
    $('.repository-columns-body').off('click', '.delete-repo-column').on('click', '.delete-repo-column', function() {
      var element = $(this);
      var modalHtml = $('#deleteRepositoryColumn');
      $.get(element.closest('li').attr('data-destroy-url'), function(data) {
        modalHtml.find('.modal-body').html(data.html);
        modalHtml.modal('show');
        initDeleteSubmitAction(modalHtml, $(modalHtml.find('form')));
      }).fail(function() {
        HelperModule.flashAlertMsg(
          I18n.t('libraries.repository_columns.no_permissions'), 'danger'
        );
      });
    });
  }

  function insertNewListItem(column) {
    var html = `<li class="list-group-item row" data-id="${column.id}"
                    data-destroy-url="${column.destroy_html_url}"
                    data-edit-url="${column.edit_url}">
                  <div class="col-xs-8">
                    <span class="pull-left column-name">${column.name}</span>
                  </div>
                  <div class="col-xs-4">
                    <span class="controlls pull-right">
                      <button class="btn btn-default edit-repo-column" data-action="edit">
                        <span class="fas fa-pencil-alt"></span>&nbsp;
                        <%= I18n.t "libraries.repository_columns.index.edit_column" %>
                      </button>&nbsp;
                      <button class="btn btn-default delete-repo-column" data-action="destroy">
                        <span class="fas fa-trash-alt"></span>&nbsp;
                        <%= I18n.t "libraries.repository_columns.index.delete_column" %>
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

  function initNewColumnModal() {
    var modalID = '#manageRepositoryColumn';
    $('.repository-columns-header').off('click', '#new-repo-column-modal').on('click', '#new-repo-column-modal', function() {
      var modalUrl = $(this).attr('data-modal-url');
      $.get(modalUrl, function(data) {
        $(modalID).find('.modal-content').html(data.html);
        $(modalID).modal('show');

        initColumnTypeSelector();
        $('[data-column-type="RepositoryTextValue"]').show();
        setTimeout(function() {
          $('#repository_column_name').focus();
        }, 500);

        $('#new-repo-column-submit').on('click', function() {
          var url = $('#repository_column_data_type').find(':selected').data('create-url');
          $.ajax({
            url: url,
            data: { repository_column: { name: $('#repository_column_name').val() } },
            type: 'POST',
            success: function(data2) {
              insertNewListItem(data2);
              HelperModule.flashAlertMsg(data2.message, 'success');
              if (modalID) {
                $(modalID).modal('hide');
              }
            },
            error: function() {
            }
          });
        });
      });
    });
  }

  return {
    init: () => {
      if ($('.repository-columns-header').length > 0) {
        initEditCoumnModal();
        initDeleteColumnModal();
        initNewColumnModal();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  RepositoryColumns.init();
});
