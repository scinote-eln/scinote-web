// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.


(function(){

  function initializeComments(){
    var steps = $(".step-comment");
    $.each(steps, function(){
      var that = $(this);
      var link = that.attr("data-href");

      $.ajax({
        method: 'GET',
        url: link,
        beforeSend: animateSpinner(that, true),
        success: function(data){
          $(that.children()[0]).html(data.html);
          animateSpinner(that, false);
        },
        complete: animateSpinner(that, false)
      });
    });
  }

  function refreshComments(child){
    var parent = chils.closest(".step-comment");
    var link = parent.attr("data-href");

    $.ajax({
      method: 'GET',
      url: link,
      beforeSend: animateSpinner(parent, true),
      success: function(data){
        $(parent.children()[0]).html(data.html);
        animateSpinner(parent, false);
      },
      complete: animateSpinner(parent, false)
    });
  }

  function commentFormOnSubmitAction(){
    $(".comment-form")
      .each(function() {
        var obj = $(this);
        debugger;
        obj
          .on('submit', function(){
            refreshComments(obj);
          });
      });
  }

  initializeComments();
  commentFormOnSubmitAction();
})();
