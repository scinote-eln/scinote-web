var Comments = (function() {
  'use strict';

  /**
    * Initializes the comments
    *
    */
  function initializeComments(){
    var comments;
    if ( $('.step-comment') && $('.step-comment').length > 0 ) {
      comments = $('.step-comment');
    } else if ( $('.result-comment') && $('.result-comment').length > 0 ) {
      comments = $('.result-comment');
    }
    if(!_.isUndefined(comments)) {
      $.each(comments, function(){
        var that = $(this);
        var link = that.attr('data-href');
        $.ajax({ method: 'GET',
                 url: link,
                 beforeSend: animateSpinner(that, true) })
          .done(function(data) {
            that.html(data.html);
            initCommentForm(that);
            initCommentsLink(that);
            scrollBottom(that.find('.content-comments'));
          })
          .always(function() {
            animateSpinner(that, false);
          });
      });
    }
  }

  // scroll to the botttom
  function scrollBottom(id) {
    var list;
    if ( id.hasClass('content-comments') ) {
      list = id;
    } else {
      list = id.find('.content-comments');
    }
    if ( list && list.length > 0) {
      list.scrollTop($(list)[0].scrollHeight);
    }
  }

  // Initialize show more comments link.
  function initCommentsLink($el) {

    $el.find('.btn-more-comments')
    .on('ajax:success', function (e, data) {
      if (data.html) {
        var list = $(this).parents('ul');
        var moreBtn = list.find('.btn-more-comments');
        var listItem = moreBtn.parents('li');
        // removes duplicated dates
        if ( list.find($('.comment-date-separator'))
                  .first().find('p').text() ===
                $(data.html).first().find('p').text() ) {
            list.find($('.comment-date-separator'))[0].remove();
              }

        $(data.html).insertAfter(listItem);
        if (data.resultsNumber < data.perPage) {
          moreBtn.remove();
        } else {
          moreBtn.attr('href', data.moreUrl);
          moreBtn.trigger('blur');
        }

        // Reposition dropdown comment options
        scrollCommentOptions(listItem
                              .closest('.content-comments')
                              .find('.dropdown-comment'));
      }
    });
  }

  // Initialize comment form.
  function initCommentForm($el) {

    var $form = $el.find('ul form');

    $('.help-block', $form).addClass('hide');

    $form.on('ajax:send', function () {
      $('#comment_message', $form).attr('readonly', true);
    })
    .on('ajax:success', function (e, data) {
      if (data.html) {
        var list = $form.parents('ul');

        // Remove potential 'no comments' element
        list.parent().find('.content-comments')
          .find('li.no-comments').remove();

        list.parent().find('.content-comments')
          .append('<li class="comment">' + data.html + '</li>')
          .scrollTop(0);
        list.parents('ul').find('> li.comment:gt(8)').remove();
        $('#comment_message', $form).val('');
        $('.form-group', $form)
          .removeClass('has-error');
        $('.help-block', $form)
            .html('')
            .addClass('hide');
        scrollBottom($el);
      }
    })
    .on('ajax:error', function (ev, xhr) {
      if (xhr.status === 400) {
        var messageError = xhr.responseJSON.errors.message;

        if (messageError) {
          $('.form-group', $form)
            .addClass('has-error');
          $('.help-block', $form)
              .html(messageError[0])
              .removeClass('hide');
        }
      }
    })
    .on('ajax:complete', function () {
      scrollBottom($('#comment_message', $form));
      $('#comment_message', $form)
        .attr('readonly', false)
        .focus();
    });
  }

  // restore comments after update or when new element is created
  function bindCommentInitializerToNewElement() {
    $(document)
      .ready(function() {
        if( document.getElementById('steps') !== null ) {
          $('#steps')
            .change(function() {
              $('.step-save')
                .on('click', function() {
                  $(document)
                    .on('ajax:success', function(){
                      initializeComments();
                    });
                });
            });
        } else if ( document.getElementById('results') !== null ) {
          $('#results')
            .change(function() {
              $('.save-result')
                .on('click', function() {
                  $(document)
                    .on('ajax:success', function(){
                      initializeComments();
                    });
                });
            });
          }
    });
  }

  function initCommentOptions(scrollableContainer, useParentOffset) {
    if ( ! _.isUndefined(typeof useParentOffset) ) {
      useParentOffset = useParentOffset;
    } else {
      useParentOffset = true;
    }
    scrollCommentOptions($('.dropdown-comment'), useParentOffset);

    // Reposition dropdown to the left
    // (only do this when using parent offset)
    if (useParentOffset) {
      $(document).on('shown.bs.dropdown', '.dropdown-comment', function() {
        var $el = $(this);
        var menu = $el.find('.dropdown-menu');
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
        scrollCommentOptions(parent.find('.dropdown-comment'), useParentOffset);
      }
    }, true);
  }

  function scrollCommentOptions(selector, useParentOffset) {
    if ( ! _.isUndefined(typeof useParentOffset) ) {
      useParentOffset = useParentOffset;
    } else {
      useParentOffset = true;
    }
    _.each(selector, function(el) {
      var $el = $(el);
      var offset = useParentOffset ? $el.offset().top : $el.position().top;
      $el.find('.dropdown-menu-fixed')
      .offset({ top: (offset + 20) });
    });
  }

  function initDeleteComments(parent) {
    $(parent).on('click', '[data-action=delete-comment]', function() {
      var $this = $(this);
      if (confirm($this.attr('data-confirm-message'))) {
        $.ajax({
          url: $this.attr('data-url'),
          type: 'DELETE',
          dataType: 'json',
          success: function() {
            // There are 3 possible actions:
            // - (A) comment is the last comment in project
            // - (B) comment is the last comment inside specific date
            //   (remove the date separator)
            // - (C) comment is a usual comment

            var commentEl = $this.closest('.comment');

            // Case A
            if (commentEl.prevAll('.comment').length === 0 &&
                  commentEl.next().length === 0) {
              commentEl.after('<li class="no-comments"><em>' +
                I18n.t('projects.index.no_comments') + '</em></li>');
            }

            // Case B
            if (commentEl.prev('.comment-date-separator').length > 0 &&
                  commentEl.next('.comment').length === 0) {
              commentEl.prev('.comment-date-separator').remove();
            }
            commentEl.remove();

            scrollCommentOptions($(parent).find('.dropdown-comment'));
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
    $(parent).on('click', '[data-action=edit-comment]', function() {

      var $this = $(this);
      $.ajax({
          url: $this.attr('data-url'),
          type: 'GET',
          dataType: 'json',
          success: function(data) {
            var commentEl = $this.closest('.comment');
            var container = commentEl
                              .find('[data-role=comment-message-container]');
            var oldMessage = container.find('[data-role=comment-message]');
            var optionsBtn = commentEl.find('[data-role=comment-options]');

            // Hide old message, append new HTML
            oldMessage.hide();
            optionsBtn.hide();
            container.append(data.html);

            var form = container.find('[data-role=edit-comment-message-form]');
            var input = form.find('input[data-role=message-input]');
            var submitBtn = form.find('[data-action=save]');
            var cancelBtn = form.find('[data-action=cancel]');

            input.focus();

            form
            .on('ajax:send', function() {
              input.attr('readonly', true);
            })
            .on('ajax:success', function() {
              var newMessage = input.val();
              oldMessage.html(newMessage);

              form.off('ajax:send ajax:success ajax:error ajax:complete');
              submitBtn.off('click');
              cancelBtn.off('click');
              form.remove();
              oldMessage.show();
              optionsBtn.show();
            })
            .on('ajax:error', function(ev, xhr) {
              if (xhr.status === 422) {
                var messageError = xhr.responseJSON.errors.message;
                if (messageError) {
                  $('.form-group', form)
                  .addClass('has-error');
                  $('.help-block', form)
                  .html(messageError[0] + ' |')
                  .removeClass('hide');
                }
              }
            })
            .on('ajax:complete', function() {
              input.attr('readonly', false).focus();
            });

            submitBtn.on('click', function() {
              form.submit();
            });

            cancelBtn.on('click', function() {
              form.off('ajax:send ajax:success ajax:error ajax:complete');
              submitBtn.off('click');
              cancelBtn.off('click');
              form.remove();
              oldMessage.show();
              optionsBtn.show();
            });
          },
          error: function() {
            // TODO
          }
        });
    });
  }

  return {
    initialize: initializeComments,
    scrollBottom: scrollBottom,
    moreComments: initCommentsLink,
    form: initCommentForm,
    bindNewElement: bindCommentInitializerToNewElement,
    initCommentOptions: initCommentOptions,
    scrollCommentOptions: scrollCommentOptions,
    initDeleteComments: initDeleteComments,
    initEditComments: initEditComments
  };

})();
