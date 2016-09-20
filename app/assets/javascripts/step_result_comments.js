(function(){
  "use strict";

  /**
    * Initializes the comments
    *
    */
  function initializeComments(){
    var comments;
    if ( $(".step-comment") && $(".step-comment").length > 0 ) {
      comments = $(".step-comment");
    } else if ( $(".result-comment") && $(".result-comment").length > 0 ) {
      comments = $(".result-comment");
    }
    $.each(comments, function(){
      var that = $(this);
      var link = that.attr("data-href");
      $.ajax({ method: 'GET',
               url: link,
               beforeSend: animateSpinner(that, true) })
        .done(function(data) {
          that.html(data.html);
          initCommentForm(that);
          initCommentsLink(that);
          scrollBottom(that.find(".content-comments"));
          animateSpinner(that, false);
        })
        .always(function(data) {
          animateSpinner(that, false);
        });
    });
  }

  // scroll to the botttom
  function scrollBottom(id) {
    var list;
    if ( id.hasClass("content-comments")) {
      list = id;
    } else {
      list = id.find(".content-comments");
    }
    if ( list && list.length > 0) {
      list.scrollTop($(list)[0].scrollHeight);
    }
  }

  // Initialize show more comments link.
  function initCommentsLink($el) {

    $el.find(".btn-more-comments")
    .on("ajax:success", function (e, data) {
      if (data.html) {
        var list = $(this).parents("ul");
        var moreBtn = list.find(".btn-more-comments");
        var listItem = moreBtn.parents('li');
        $(data.html).insertAfter(listItem);
        if (data.results_number < data.per_page) {
          moreBtn.remove();
        } else {
          moreBtn.attr("href", data.more_url);
          moreBtn.trigger("blur");
        }

        // Reposition dropdown comment options
        scrollCommentOptions(listItem.closest(".content-comments").find(".dropdown-comment"));
      }
    });
  }

  // Initialize comment form.
  function initCommentForm($el) {

    var $form = $el.find("ul form");

    $(".help-block", $form).addClass("hide");

    $form.on("ajax:send", function (data) {
      $("#comment_message", $form).attr("readonly", true);
    })
    .on("ajax:success", function (e, data) {
      if (data.html) {
        var list = $form.parents("ul");

        // Remove potential "no comments" element
        list.parent().find(".content-comments")
          .find("li.no-comments").remove();

        list.parent().find(".content-comments")
          .append("<li class='comment'>" + data.html + "</li>")
          .scrollTop(0);
        list.parents("ul").find("> li.comment:gt(8)").remove();
        $("#comment_message", $form).val("");
        $(".form-group", $form)
          .removeClass("has-error");
        $(".help-block", $form)
            .html("")
            .addClass("hide");
        scrollBottom($el);
      }
    })
    .on("ajax:error", function (ev, xhr) {
      if (xhr.status === 400) {
        var messageError = xhr.responseJSON.errors.message;

        if (messageError) {
          $(".form-group", $form)
            .addClass("has-error");
          $(".help-block", $form)
              .html(messageError[0])
              .removeClass("hide");
        }
      }
    })
    .on("ajax:complete", function () {
      scrollBottom($("#comment_message", $form));
      $("#comment_message", $form)
        .attr("readonly", false)
        .focus();
    });
  }

  // restore comments after update or when new element is created
  function bindCommentInitializerToNewElement() {
    $(document)
      .ready(function() {
        if( document.getElementById("steps") !== null ) {
          $("#steps")
            .change(function() {
              $('.step-save')
                .on('click', function() {
                  setTimeout(function() {
                    initializeComments();
                  }, 500);
                });
            });
        } else if ( document.getElementById("results") !== null ) {
          $("#results")
            .change(function() {
              $('.save-result')
                .on('click', function() {
                  setTimeout(function() {
                    initializeComments();
                  }, 500);
                });
            });
          }
    });
  }

  bindCommentInitializerToNewElement();
  initializeComments();

})();
