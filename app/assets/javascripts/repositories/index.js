//= require repositories/import/records_importer.js
(function() {
  'use strict';

  function initImportRecordsModal() {
    $('#importRecordsButton').off().on('click', function() {
      $('#modal-import-records').modal('show');
      _initParseRecordsModal();
    });
  }

  function _initParseRecordsModal() {
    $('#form-records-file').on('ajax:success', function(ev, data) {
      $('#modal-import-records').modal('hide');
      $(data.html).appendTo('body').promise().done(function() {
        $('#parse-records_modal').modal('show');
        repositoryRecordsImporter();
      });
    });
  }

  function loadRepositoryTab() {
    var param;
    $('#repository-tabs a').on("click", function(e) {
      e.preventDefault();
      var pane = $(this);
      $.ajax({
        url: $(this).attr("data-url"),
        type: "GET",
        dataType: "json",
        success: function (data) {
        	var tabBody = $(pane.context.hash).find(".tab-content-body");
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
      $('a[href="#custom_repo_'+param+'"]').click();
    }
    else {
      // load first tab content
      $('#repository-tabs a:first').click();
    }

    // clean tab content
    $('a[data-toggle="tab"]').on('hide.bs.tab', function (e) {
      $(".tab-content-body").html("");
    })
  }

  $('.create-repository').initializeModal('#create-repo-modal');

  $(document).ready(function() {
    loadRepositoryTab();
    initImportRecordsModal();
  });
})();
