//= require repositories/import/records_importer.js

/*
  global animateSpinner repositoryRecordsImporter I18n
  RepositoryDatatable PerfectScrollbar HelperModule repositoryFilterObject
*/

(function(global) {
  'use strict';

  function pageReload() {
    animateSpinner();
    location.reload();
  }

  function handleErrorSubmit(XHR) {
    var formGroup = $('#form-records-file').find('.form-group');
    formGroup.addClass('has-error');
    formGroup.find('.help-block').remove();
    $('#form-records-file input[type="submit"]').removeAttr('disabled');
    $('#parse-sheet-loader').addClass('hidden');
    formGroup.append(
      '<span class="help-block">' + XHR.responseJSON.message + '</span>'
    );
    HelperModule.flashAlertMsg(XHR.responseJSON.message, 'danger');
  }

  function handleSuccessfulSubmit(data) {
    $('#form-records-file input[type="submit"]').removeAttr('disabled');
    $('#parse-sheet-loader').addClass('hidden');
    $('#modal-import-records').modal('hide');
    $(data.html).appendTo('body').promise().done(function() {
      $('#parse-records-modal').modal('show');
      repositoryRecordsImporter();
    });
  }

  function initTable() {
    RepositoryDatatable.destroy();
    RepositoryDatatable.init('#' + $('.repository-table table').attr('id'));
    RepositoryDatatable.redrawTableOnSidebarToggle();
  }

  function initParseRecordsModal() {
    var form = $('#form-records-file');
    var submitBtn = form.find('input[type="submit"]');
    form.on('ajax:success', function(ev, data) {
      $('#modal-import-records').modal('hide');
      $(data.html).appendTo('body').promise().done(function() {
        repositoryRecordsImporter();
      });
    }).on('ajax:error', function(ev, data) {
      $(this).find('.form-group').addClass('has-error');
      $(this).find('.form-group').find('.help-block').remove();
      $(this).find('.form-group').append("<span class='help-block'>" +
                                         data.responseJSON.message + '</span>');
    });

    submitBtn.on('click', function(event) {
      var data = new FormData();
      submitBtn.attr('disabled', true);
      $('#parse-sheet-loader').removeClass('hidden');
      event.preventDefault();
      event.stopPropagation();
      data.append('file', document.getElementById('file').files[0]);
      data.append('team_id', document.getElementById('team_id').value);
      $.ajax({
        type: 'POST',
        url: form.attr('action'),
        data: data,
        success: handleSuccessfulSubmit,
        error: handleErrorSubmit,
        processData: false,
        contentType: false
      });
    });
  }

  function initImportRecordsModal() {
    $('.repository-show').on('click', '#importRecordsButton', function() {
      $('#modal-import-records').modal('show');
      initParseRecordsModal();
    });
  }

  $('.repository-title-name .inline-editing-container').on('inlineEditing::updated', function(e, value, viewValue) {
    $('.repository-archived-title-name')
      .text(I18n.t('repositories.show.archived_inventory_items', { repository_name: viewValue }));
    $('#toolbarButtonsDatatable .archived-label')
      .text(I18n.t('repositories.show.archived_view_label.active', { repository_name: viewValue }));
  });

  function initArchivingActionsInDropdown() {
    $('.archive-repository-option').on('click', function(event) {
      event.preventDefault();
      animateSpinner(null, true);

      $.ajax({
        type: 'POST',
        url: $(this).attr('href'),
        dataType: 'json',
        data: { repository_ids: [$(this).data('repositoryId')] },
        success: pageReload,
        error: function(ev) {
          if (ev.status === 403) {
            HelperModule.flashAlertMsg(I18n.t('repositories.js.permission_error'), ev.responseJSON.style);
          } else if (ev.status === 422) {
            HelperModule.flashAlertMsg(ev.responseJSON.error, 'danger');
          }
          animateSpinner(null, false);
        }
      });
    });
  }

  function initFilterSaving() {
    $(document).on('click', '#newFilterLink', function() {
      $('#modalSaveRepositoryTableFilter #repository_table_filter_name').val('');
    });

    $('#modalSaveRepositoryTableFilter').on('shown.bs.modal', function() {
      $('#repository_table_filter_name').focus();
    });

    $(document).on('click', '#overwriteFilterLink', function() {
      var $modal = $('#modalSaveRepositoryTableFilter');

      // set overwrite flag
      $modal.data('overwrite', true);

      // revert to 'create' form
      $modal.on('hidden.bs.modal', function() {
        $modal.removeData('overwrite');
      });


      $('#modalSaveRepositoryTableFilter #repository_table_filter_name')
        .val($modal.data('repositoryTableFilterName'));
    });

    $('#saveRepositoryTableFilterButton').on('click', function() {
      var $modal = $('#modalSaveRepositoryTableFilter');
      var $button = $(this);
      var url = $modal.data().saveUrl;
      var method;

      if ($modal.data().overwrite) {
        method = 'PUT';
        url = url + '/' + $modal.data().repositoryTableFilterId;
      } else {
        method = 'POST';
      }

      $button.addClass('disabled');

      $.ajax({
        type: method,
        url: url,
        contentType: 'application/json; charset=utf-8',
        data: JSON.stringify({
          repository_table_filter: {
            name: $('#repository_table_filter_name').val(),
            repository_table_filter_elements_json: $('#repository_table_filter_elements_json').val()
          }
        }),
        success: function(response) {
          var existingFilterIndex = repositoryFilterObject.savedFilters.findIndex((f) => {
            return f.id === response.data.id;
          });

          var $overwriteLink = $('#overwriteFilterLink');
          $modal.modal('hide');
          $overwriteLink.removeClass('hidden');
          $modal.data('repositoryTableFilterId', response.data.id);
          $modal.data('repositoryTableFilterName', response.data.attributes.name);
          $('#currentFilterName').text(response.data.attributes.name);


          if (existingFilterIndex > -1) {
            repositoryFilterObject.savedFilters = repositoryFilterObject.savedFilters.map((f) => {
              return f.id === response.data.id ? response.data : f;
            });
          } else {
            repositoryFilterObject.savedFilters = repositoryFilterObject.savedFilters.concat([response.data]);
          }

          repositoryFilterObject.filterName = response.data.attributes.name;
          $button.removeClass('disabled');
        },
        error: function(response) {
          HelperModule.flashAlertMsg(response.responseJSON.message, 'danger');
          $button.removeClass('disabled');
          $modal.modal('hide');
        }
      });
    });
  }

  initImportRecordsModal();
  initTable();
  initArchivingActionsInDropdown();
  initFilterSaving();
}(window));
