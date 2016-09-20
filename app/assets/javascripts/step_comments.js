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
  function initStepCommentsLink($el) {
    $el.find(".btn-more-comments")
    .on("ajax:success", function (e, data) {
      if (data.html) {
        var list = $(this).parents("ul");
        var moreBtn = list.find(".btn-more-comments");
        var listItem = moreBtn.parents('li');
        $(data.html).insertBefore(listItem);
        if (data.results_number < data.per_page) {
          moreBtn.remove();
        } else {
          moreBtn.attr("href", data.more_url);
          moreBtn.trigger("blur");
        }

        // Reposition dropdown comment options
        scrollCommentOptions(listItem.closest(".content-comments")
        .find(".dropdown-comment"));
      }
    });
  }
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
      $.ajax({ method: 'GET',
               url: link,
               beforeSend: animateSpinner(that, true) })
        .done(function(data) {
          updateCommentHTML(that, data);
          bindCommentButton();
          initStepCommentsLink(that);
          animateSpinner(that, false);
        })
        .always(function(data) {
          animateSpinner(that, false);
        });
    });
  }

  function refreshComment(child) {
    var parent = child.closest(".step-comment");
    var link = parent.attr("data-href");
    $.ajax({ method: 'GET',
             url: link,
             beforeSend: animateSpinner(parent, true) })
      .done(function(data) {
        updateCommentHTML(parent, data);
        bindCommentButton();
        initStepCommentsLink(parent);
        animateSpinner(parent, false);
      })
      .always(function() {
        animateSpinner(parent, false);
      });
  }

  function scrollBottom(id) {
    var list = id.find(".content-comments");
    if ( list && list.length > 0) {
      list.scrollTop($(list)[0].scrollHeight);
    }
  }

  function bindCommentButton(){
    $.each($(".comment-form"), function() {
      $(this)
        .on("submit", function() {
          bindCommentAjax($(this));
        });
    });
  }

  function bindCommentAjax(id){
    $(id)
      .on('ajax:success', function() {
        refreshComment($(id));
      })
      .on('ajax:error', function(request, status, error) {
        var messageError = status.responseJSON.errors.message.toString();
        if (messageError) {
          $(request.target)
            .addClass("has-error");
          $(".help-block", request.target)
            .html(messageError)
            .removeClass("hide");
        }
      });
  }


  function updateCommentHTML(parent, data) {
    var id;
    if ( $(parent.find(".comment-form")).attr("id") !== undefined ) {
      id = "#" + $(parent.find(".comment-form")).attr("id");
      $(parent.find('[data-info="step-comment"]')).html(data.html);
    } else {
      id = "#" + $( $.parseHTML(data.html) ).find(".comment-form").attr("id");
      $(parent.find('[data-info="step-comment"]')).html(data.html);
    }
    scrollBottom(parent);
  }

  initializeComments();
})();
