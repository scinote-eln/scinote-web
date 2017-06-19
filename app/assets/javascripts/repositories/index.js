//= require repositories/import/records_importer.js

(function() {
  'use strict';

  function showNewRepository() {
    $('#create-repo-modal').on('ajax:success', function(data) {
      var location = data.url;
      window.location.replace(location);
    });
  }

  function initCreateRepository() {
    $('.create-repository').off().on('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      e.stopImmediatePropagation();
      $.ajax({
        url: $(this).attr('href'),
        type: 'GET',
        dataType: 'json',
        success: function(data) {
          $(data.html).appendTo('body').promise().done(function() {
            $('#create-repo-modal').modal('show');
          });
        },
        error: function() {
          location.reload();
        }
      })
    });
  }

  function loadRepositoryTab() {
    var param, pane;
    $('#repository-tabs a').on("click", function(e) {
      e.preventDefault();
      e.stopPropagation();
      e.stopImmediatePropagation();
      pane = $(this);
      $.ajax({
        url: pane.attr('data-url'),
        type: 'GET',
        dataType: 'json',
        success: function(data) {
        	var tabBody = $(pane.context.hash).find('.tab-content-body');
          tabBody.html(data.html);
          pane.tab('show').promise().done(function() {
            initImportRecordsModal();
          });
        },
        error: function (error) {
          // TODO
        }
      });
    });

    // on page load
    if( param = getParam('repository') ){
      // load selected tab
      $('a[href="#custom_repo_' + param + '"]').click();
    }
    else {
      // load first tab content
      $('#repository-tabs a:first').click();
    }

    // clean tab content
    $('a[data-toggle="tab"]').on('hide.bs.tab', function(e) {
      $(".tab-content-body").html("");
    })
  }

  function initImportRecordsModal() {
    $('#importRecordsButton').off().on('click', function() {
      $('#modal-import-records').modal('show');
      initParseRecordsModal();
    });
  }

  function initParseRecordsModal() {
    $('#form-records-file').on('ajax:success', function(ev, data) {
      $('#modal-import-records').modal('hide');
      $(data.html).appendTo('body').promise().done(function() {
        $('#parse-records_modal').modal('show');
        repositoryRecordsImporter();
      });
    });
  };

  $('.delete-repo-option').initializeModal('#delete-repo-modal');
  $('.rename-repo-option').initializeModal('#rename-repo-modal');
  $('.copy-repo-option').initializeModal('#copy-repo-modal');
  // $('.create-repository').initializeModal('#create-repo-modal');

  $(document).ready(function() {
    loadRepositoryTab();
    // showParsedRecords();
    initCreateRepository();
  });

})();
