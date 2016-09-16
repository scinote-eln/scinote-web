(function(){

  function initializeComments(){
    var steps = $(".step-comment");
    $.each(steps, function(){
      var that = $(this);
      var link = that.attr("data-href");

      $.ajax({ method: 'GET',
               url: link,
               beforeSend: animateSpinner(that, true) })
        .done(function(data){
          updateCommentHTML(that, data);
          animateSpinner(that, false);
        })
        .always(animateSpinner(that, false));
    });
  }

  function refreshComments(child){
    var parent = child.closest(".step-comment");
    var link = parent.attr("data-href");
    $.ajax({ method: 'GET',
             url: link,
             beforeSend: animateSpinner(parent, true) })
      .done(function(data){
        updateCommentHTML(parent, data);
        animateSpinner(parent, false);
      })
      .always(animateSpinner(parent, false));

  }

  function commentFormOnSubmitAction(){
    $(".comment-form")
      .each(function() {
        bindCommentAjax("#" + $(this).attr("id"));
      });
  }

  function bindCommentAjax(form){
    $(document)
      .on('ajax:success', function () {
         refreshComments($(form));
      })
      .on('ajax:error', function () {
         refreshComments(form);
      });
  }

  function updateCommentHTML(parent, data) {
    $(parent.children()[0]).html(data.html);
    var id = "#" + $(parent.find(".comment-form")).attr("id");
    bindCommentAjax(id);
  }

  initializeComments();
})();
