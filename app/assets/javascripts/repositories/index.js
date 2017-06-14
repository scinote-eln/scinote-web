(function() {
  'use strict';

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
          pane.tab('show');
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
    $('a[data-toggle="tab"]').on('hide.bs.tab', function (e) {
      $(".tab-content-body").html("");
    })
  }

  function showParsedRecords() {
    $('#form-records-file').bind('ajax:success', function(evt, data, status, xhr) {
      debugger;
    });
  }

  $('.delete-repo-option').initializeModal('#delete-repo-modal');
  $('.rename-repo-option').initializeModal('#rename-repo-modal');
  $('.copy-repo-option').initializeModal('#copy-repo-modal');
  $('.create-repository').initializeModal('#create-repo-modal');

  $(document).ready(function() {
    loadRepositoryTab();
    showParsedRecords();
  });

})();
