(function() {
  'use strict';

  $('.create-repository').initializeModal('#create-repo-modal');
  loadRepositoryTab();
})();

function loadRepositoryTab() {
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
