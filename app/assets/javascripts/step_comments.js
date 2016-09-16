(function(){
  "use strict";

  // // Initialize comment form.
  // function initStepCommentForm(ev, $el) {
  //   var $form = $el.find("ul form");
  //
  //   var $commentInput = $form.find("#comment_message");
  //
  //   $(".help-block", $form).addClass("hide");
  //
  //   $form
  //   .on("ajax:send", function (data) {
  //     $("#comment_message", $form).attr("readonly", true);
  //   })
  //   .on("ajax:success", function (e, data) {
  //     if (data.html) {
  //       var list = $form.parents("ul");
  //
  //       // Remove potential "no comments" element
  //       list.parent().find(".content-comments")
  //         .find("li.no-comments").remove();
  //
  //       list.parent().find(".content-comments")
  //         .prepend("<li class='comment'>" + data.html + "</li>")
  //         .scrollTop(0);
  //       list.parents("ul").find("> li.comment:gt(8)").remove();
  //       $("#comment_message", $form).val("");
  //       $(".form-group", $form)
  //         .removeClass("has-error");
  //       $(".help-block", $form)
  //           .html("")
  //           .addClass("hide");
  //       scrollCommentOptions(
  //         list.parent().find(".content-comments .dropdown-comment")
  //       );
  //     }
  //   })
  //   .on("ajax:error", function (ev, xhr) {
  //     if (xhr.status === 400) {
  //       var messageError = xhr.responseJSON.errors.message;
  //
  //       if (messageError) {
  //         $(".form-group", $form)
  //           .addClass("has-error");
  //         $(".help-block", $form)
  //             .html(messageError[0])
  //             .removeClass("hide");
  //       }
  //     }
  //   })
  //   .on("ajax:complete", function () {
  //     $("#comment_message", $form)
  //       .attr("readonly", false)
  //       .focus();
  //   });
  // }
  //
  // // Initialize show more comments link.
  // function initStepCommentsLink($el) {
  //   $el.find(".btn-more-comments")
  //   .on("ajax:success", function (e, data) {
  //     if (data.html) {
  //       var list = $(this).parents("ul");
  //       var moreBtn = list.find(".btn-more-comments");
  //       var listItem = moreBtn.parents('li');
  //       $(data.html).insertBefore(listItem);
  //       if (data.results_number < data.per_page) {
  //         moreBtn.remove();
  //       } else {
  //         moreBtn.attr("href", data.more_url);
  //         moreBtn.trigger("blur");
  //       }
  //
  //       // Reposition dropdown comment options
  //       scrollCommentOptions(listItem.closest(".content-comments")
  //       .find(".dropdown-comment"));
  //     }
  //   });
  // }
  //
  // function initStepCommentTabAjax() {
  //   $(".comment-tab-link")
  //   .on("ajax:before", function (e) {
  //     var $this = $(this);
  //     var parentNode = $this.parents("li");
  //     var targetId = $this.attr("aria-controls");
  //
  //     if (parentNode.hasClass("active")) {
  //       return false;
  //     }
  //   })
  //   .on("ajax:success", function (e, data) {
  //     if (data.html) {
  //       var $this = $(this);
  //       var targetId = $this.attr("aria-controls");
  //       var target = $("#" + targetId);
  //       var parentNode = $this.parents("ul").parent();
  //
  //       target.html(data.html);
  //       initStepCommentForm(e, parentNode);
  //       initStepCommentsLink(parentNode);
  //
  //       parentNode.find(".active").removeClass("active");
  //       $this.parents("li").addClass("active");
  //       target.addClass("active");
  //     }
  //   })
  //   .on("ajax:error", function(e, xhr, status, error) {
  //     // TODO
  //   });
  // }

  function initializeComments(){
    var steps = $(".step-comment");
    $.each(steps, function(){
      var that = $(this);
      var link = that.attr("data-href");
      var parentNode = that.parents("ul").parent();
      debugger;
      $.ajax({ method: 'GET',
               url: link,
               beforeSend: animateSpinner(that, true) })
        .done(function(data){
          debugger;
          updateCommentHTML(that, data);
          animateSpinner(that, false);
        })
        .always(function(data){
          debugger;
          animateSpinner(that, false)
        });
    });
  }

  function refreshComments(child){
    var parent = child.closest(".step-comment");
    var link = parent.attr("data-href");
    $.ajax({ method: 'GET',
             url: link,
             beforeSend: animateSpinner(parent, true) })
      .done(function(data){
        debugger;
        updateCommentHTML(parent, data);
        animateSpinner(parent, false);
      })
      .always(animateSpinner(parent, false));

  }

  function commentFormOnSubmitAction(){
    $(".comment-form")
      .each(function() {
        debigger;
        bindCommentAjax("#" + $(this).attr("id"));
      });
  }

  // function bindMoreCommentButton(){
  //   $(".btn-more-comments")
  //     .each(function(){
  //       bindCommentAjax($(this));
  //     });
  // }

  function bindCommentAjax(form){
    $(document)
      .on('ajax:success', function () {
        debugger;
        refreshComments($(form));
      })
      .on('ajax:error', function () {
        refreshComments(form);
      });
  }

  function updateCommentHTML(parent, data) {
    var id = "#" + $(parent.find(".comment-form")).attr("id");
    debugger;
    $(parent.children()[0]).html(data.html);
    bindCommentAjax(id);
  }

  initializeComments();
})();
