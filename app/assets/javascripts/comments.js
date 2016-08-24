function initCommentOptions(scrollableContainer) {
  document.addEventListener('scroll', function (event) {
    var $target = $(event.target);

    if ($target.length && $target.is(scrollableContainer)) {
      scrollCommentOptions($target.find(".dropdown-comment"));
    }
  }, true);
}

function scrollCommentOptions(selector) {
  _.each(selector, function(el) {
    var $el = $(el);
    $el.find(".dropdown-menu-fixed").css("top", $el.offset().top + 20);
  });
}

function initDeleteComment(parent) {
  $(parent).on("click", "[data-action=delete-comment]", function(e) {
    var $this = $(this);
    if (confirm($this.attr("data-confirm-message"))) {
      $.ajax({
        url: $this.attr("data-url"),
        type: "DELETE",
        dataType: "json",
        success: function (data) {
          // There are 3 possible actions:
          // - (A) comment is the last comment in project (not handled differently)
          // - (B) comment is the last comment inside specific date (remove the date separator)
          // - (C) comment is a usual comment
          var commentEl = $this.closest(".comment");
          var otherComments = commentEl.siblings(".comment");
          if (commentEl.prev(".comment-date-separator").length > 0 && commentEl.next(".comment").length == 0) {
            // Case B
            commentEl.prev(".comment-date-separator").remove();
          }
          commentEl.remove();

          scrollCommentOptions($(parent).find(".dropdown-comment"));
        },
        error: function (data) {
          // Display alert
          alert(data.responseJSON.message);
        }
      });
    }
  });
}