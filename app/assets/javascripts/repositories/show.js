//= require repositories/import/records_importer.js

/*
  global pageReload animateSpinner repositoryRecordsImporter I18n
  RepositoryDatatable PerfectScrollbar HelperModule
*/

(function(global) {
  'use strict';

  global.pageReload = function() {
    animateSpinner();
    location.reload();
  };

  function handleErrorSubmit(XHR) {
    var formGroup = $('#form-records-file').find('.form-group');
    formGroup.addClass('has-error');
    formGroup.find('.help-block').remove();
    formGroup.append(
      '<span class="help-block">' + XHR.responseJSON.message + '</span>'
    );
  }

  function handleSuccessfulSubmit(data) {
    $('#modal-import-records').modal('hide');
    $(data.html).appendTo('body').promise().done(function() {
      $('#parse-records-modal')
        .modal('show')
        .on('hidden.bs.modal', function() {
          animateSpinner();
          location.reload();
        });
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
        $('#parse-records-modal')
          .modal('show')
          .on('hidden.bs.modal', function() {
            animateSpinner();
            location.reload();
          });
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
    $('#importRecordsButton').off().on('click', function() {
      $('#modal-import-records').modal('show');
      initParseRecordsModal();
    });
  }

  function initShareModal() {
    var form = $('.share-repo-modal').find('form');
    var sharedCBs = form.find("input[name='share_team_ids[]']");
    var permissionCBs = form.find("input[name='write_permissions[]']");
    var permissionChanges = form.find("input[name='permission_changes']");
    var submitBtn = form.find('input[type="submit"]');
    var selectAllCheckbox = form.find('.all-teams .sci-checkbox');

    form.find('.teams-list').find('input.sci-checkbox, .permission-selector')
      .toggleClass('hidden', selectAllCheckbox.is(':checked'));
    form.find('.all-teams .sci-toggle-checkbox')
      .toggleClass('hidden', !selectAllCheckbox.is(':checked'))
      .attr('disabled', !selectAllCheckbox.is(':checked'));

    selectAllCheckbox.change(function() {
      form.find('.teams-list').find('input.sci-checkbox, .permission-selector')
        .toggleClass('hidden', this.checked);
      form.find('.all-teams .sci-toggle-checkbox').toggleClass('hidden', !this.checked)
        .attr('disabled', !this.checked);
    });

    sharedCBs.change(function() {
      var selectedTeams = form.find('.teams-list .sci-checkbox:checked').length;
      form.find('#select_all_teams').prop('indeterminate', selectedTeams > 0);
      $('#editable_' + this.value).toggleClass('hidden', !this.checked)
        .attr('disabled', !this.checked);
    });

    if (form.find('.teams-list').length) new PerfectScrollbar(form.find('.teams-list')[0]);

    permissionCBs.change(function() {
      var changes = JSON.parse(permissionChanges.val());
      changes[this.value] = 'true';
      permissionChanges.val(JSON.stringify(changes));
    });

    submitBtn.on('click', function(event) {
      event.preventDefault();
      $.ajax({
        type: 'POST',
        url: form.attr('action'),
        data: form.serialize(),
        success: function(data) {
          if (data.warnings) {
            alert(data.warnings);
          }
          $(`#slide-panel li.active .repository-share-status,
             #repository-toolbar .repository-share-status
          `).toggleClass('hidden', !data.status);
          HelperModule.flashAlertMsg(form.data('success-message'), 'success');
          $('.share-repo-modal').modal('hide');
        },
        error: function(data) {
          alert(data.responseJSON.errors);
          $('.share-repo-modal').modal('hide');
        }
      });
    });
  }

  function initRepositoryViewSwitcher() {
    var viewSwitch = $('.view-switch');
    viewSwitch.on('click', '.view-switch-archived', function() {
      $('.repository-show').removeClass('active').addClass('archived');
      $('#manage-repository-column').removeClass('active').addClass('archived');
      RepositoryDatatable.reload();
    });
    viewSwitch.on('click', '.view-switch-active', function() {
      $('.repository-show').removeClass('archived').addClass('active');
      $('#manage-repository-column').removeClass('archived').addClass('active');
      RepositoryDatatable.reload();
    });
  }

  $('.repository-title-name .inline-editing-container').on('inlineEditing::updated', function(e, value, viewValue) {
    $('.repository-archived-title-name')
      .text(I18n.t('repositories.show.archived_inventory_items', { repository_name: viewValue }));
    $('#toolbarButtonsDatatable .archived-label')
      .text(I18n.t('repositories.show.archived_view_label.active', { repository_name: viewValue }));
  });

  $('#shareRepoBtn').on('ajax:success', function() {
    initShareModal();
  });

  $('.create-new-repository').initSubmitModal('#create-repo-modal', 'repository');

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
    $(document).on('click', '#overwriteFilterLink', function() {
      var $modal = $('#modalSaveRepositoryTableFilter');

      // set overwrite flag
      $modal.data('overwrite', true);

      // revert to 'create' form
      $modal.on('hidden.bs.modal', function() {
        $modal.removeData('overwrite');
      });
    });

    $(document).on('click', '#saveRepositoryTableFilterButton', function() {
      var $modal = $('#modalSaveRepositoryTableFilter');
      var url = $modal.data().saveUrl;
      var method;

      if ($modal.data().overwrite) {
        method = 'PUT';
        url = url + '/' + $modal.data().repositoryTableFilterId;
      } else {
        method = 'POST';
      }

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
          var $overwriteLink = $('#overwriteFilterLink');
          $modal.modal('hide');
          $overwriteLink.removeClass('hidden');
          $modal.data('repositoryTableFilterId', response.data.id);
          $('#currentFilterName').html(response.data.name);
        },
        error: function(response) {
          HelperModule.flashAlertMsg(response.responseJSON.message, 'danger');
        }
      });
    });
  }

  initImportRecordsModal();
  initTable();
  initRepositoryViewSwitcher();
  initArchivingActionsInDropdown();
  initFilterSaving();
}(window));
