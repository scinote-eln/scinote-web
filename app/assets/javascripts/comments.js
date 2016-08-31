function initCommentOptions(scrollableContainer, useParentOffset) {
  useParentOffset = (typeof useParentOffset !== 'undefined') ? useParentOffset : true;
  scrollCommentOptions($(".dropdown-comment"), useParentOffset);

  // Reposition dropdown to the left
  // (only do this when using parent offset)
  if (useParentOffset) {
    $(document).on("shown.bs.dropdown", ".dropdown-comment", function() {
      var $el = $(this);
      var menu = $el.find(".dropdown-menu");
      var leftPos = $el.offset().left;
      if (leftPos + menu.width() > $(window).width()) {
        menu.offset({ left: leftPos - menu.width() });
      }
    });
  }

  // Reposition dropdowns vertically on scroll events
  document.addEventListener('scroll', function (event) {
    var $target = $(event.target);
    var parent = $(scrollableContainer);

    if ($target.length) {
      scrollCommentOptions(parent.find(".dropdown-comment"), useParentOffset);
    }
  }, true);
}

function scrollCommentOptions(selector, useParentOffset) {
  useParentOffset = (typeof useParentOffset !== 'undefined') ? useParentOffset : true;
  _.each(selector, function(el) {
    var $el = $(el);
    var offset = useParentOffset ? $el.offset().top : $el.position().top;
    $el.find(".dropdown-menu-fixed")
    .offset({ top: (offset + 20) });
  });
}

function initDeleteComments(parent) {
  $(parent).on("click", "[data-action=delete-comment]", function(e) {
    var $this = $(this);
    if (confirm($this.attr("data-confirm-message"))) {
      $.ajax({
        url: $this.attr("data-url"),
        type: "DELETE",
        dataType: "json",
        success: function(data) {
          // There are 3 possible actions:
          // - (A) comment is the last comment in project
          // - (B) comment is the last comment inside specific date (remove the date separator)
          // - (C) comment is a usual comment

          var commentEl = $this.closest(".comment");

          // Case A
          if (commentEl.prevAll(".comment").length == 0 && commentEl.next().length == 0) {
            commentEl.after("<li class='no-comments'><em>" + I18n.t("projects.index.no_comments") + "</em></li>");
          }

          // Case B
          if (commentEl.prev(".comment-date-separator").length > 0 && commentEl.next(".comment").length == 0) {
            commentEl.prev(".comment-date-separator").remove();
          }
          commentEl.remove();

          scrollCommentOptions($(parent).find(".dropdown-comment"));
        },
        error: function(data) {
          // Display alert
          alert(data.responseJSON.message);
        }
      });
    }
  });
}

function initEditComments(parent) {
  $(parent).on("click", "[data-action=edit-comment]", function(e) {
    var $this = $(this);
    $.ajax({
        url: $this.attr("data-url"),
        type: "GET",
        dataType: "json",
        success: function(data) {
          var commentEl = $this.closest(".comment");
          var container = commentEl.find("[data-role=comment-message-container]");
          var oldMessage = container.find("[data-role=comment-message]");
          var optionsBtn = commentEl.find("[data-role=comment-options]");

          // Hide old message, append new HTML
          oldMessage.hide();
          optionsBtn.hide();
          container.append(data.html);

          var form = container.find("[data-role=edit-comment-message-form]");
          var input = form.find("input[data-role=message-input]");
          var submitBtn = form.find("[data-action=save]");
          var cancelBtn = form.find("[data-action=cancel]");

          input.focus();

          form
          .on("ajax:send", function() {
            input.attr("readonly", true);
          })
          .on("ajax:success", function(e, data) {
            var newMessage = input.val();
            oldMessage.html(newMessage);

            form.off("ajax:send ajax:success ajax:error ajax:complete");
            submitBtn.off("click");
            cancelBtn.off("click");
            form.remove();
            oldMessage.show();
            optionsBtn.show();
          })
          .on("ajax:error", function(ev, xhr) {
            if (xhr.status === 422) {
              var messageError = xhr.responseJSON.errors.message;
              if (messageError) {
                $(".form-group", form)
                .addClass("has-error");
                $(".help-block", form)
                .html(messageError[0])
                .removeClass("hide")
                .after(" |");
              }
            }
          })
          .on("ajax:complete", function() {
            input.attr("readonly", false).focus();
          });

          submitBtn.on("click", function() {
            form.submit();
          });

          cancelBtn.on("click", function() {
            form.off("ajax:send ajax:success ajax:error ajax:complete");
            submitBtn.off("click");
            cancelBtn.off("click");
            form.remove();
            oldMessage.show();
            optionsBtn.show();
          });
        },
        error: function(data) {
          // TODO
        }
      });
  });
}