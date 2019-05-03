//= require repositories/import/records_importer.js

/*
  global animateSpinner repositoryRecordsImporter getParam RepositoryDatatable
*/

(function(global) {
  'use strict';

  global.pageReload = function() {
    animateSpinner();
    location.reload();
  }

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

  function initParseRecordsModal() {
    var form = $('#form-records-file');
    var submitBtn = form.find('input[type="submit"]');
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

  function loadRepositoryTab() {
    var param = getParam('repository');
    $('#repository-tabs a').on('click', function(e) {
      var pane = $(this);
      e.preventDefault();
      $.ajax({
        url: $(this).attr('data-url'),
        type: 'GET',
        dataType: 'json',
        success: function(data) {
          var tabBody = $(pane.context.hash).find('.tab-content-body');
          tabBody.html(data.html);
          pane.tab('show').promise().done(function(el) {
            initImportRecordsModal();
            RepositoryDatatable.destroy();
            RepositoryDatatable.init(el.attr('data-repo-table'));
          });
        },
        error: function() {
          // TODO
        }
      });
    });

    // on page load
    if (param) {
      // load selected tab
      $('a[href="#custom_repo_' + param + '"]').click();
    } else {
      // load first tab content
      $('#repository-tabs a:first').click();
    }

    // clean tab content
    $('a[data-toggle="tab"]').on('hide.bs.tab', function() {
      $('.tab-content-body').html('');
    });
  }

  $('#create-new-repository').initializeModal('#create-repo-modal');
  loadRepositoryTab();
  initImportRecordsModal();
}(window));
