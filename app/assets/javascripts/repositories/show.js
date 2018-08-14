(function() {
  'use strict';

  function initTable() {
    RepositoryDatatable.destroy();
    RepositoryDatatable.init('#' + $('.repository-table table').attr('id'));
    RepositoryDatatable.redrawTableOnSidebarToggle();
  }

  function initParseRecordsModal() {
    $('#form-records-file').on('ajax:success', function(ev, data) {
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
  }

  function initImportRecordsModal() {
    $('#importRecordsButton').off().on('click', function() {
      $('#modal-import-records').modal('show');
      initParseRecordsModal();
    });
  }

  initImportRecordsModal();
  initTable();
}());
