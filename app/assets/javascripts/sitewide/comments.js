/* global inlineEditing PerfectScrollbar HelperModule I18n */
/* eslint-disable no-restricted-globals, no-alert */
var Comments = (function() {
  function changeCounter(comment, value) {
    var currentCount = $('#comment-counter-' + comment.closest('.comments-container').attr('data-object-id'));
    var newValue = parseInt(currentCount.html(), 10) + value;
    currentCount.text(newValue);
    if (newValue === 0) {
      currentCount.addClass('hidden');
    } else {
      currentCount.removeClass('hidden');
    }
  }

  function scrollBottom(container) {
    container.scrollTop(container[0].scrollHeight);
  }

  function newCommentValidation(textarea, submitBtn) {
    textarea.off().on('focus', function() {
      $(this).addClass('border');
      if (this.value.trim().length > 0) {
        submitBtn.addClass('show');
      }
    }).on('blur', function() {
      if (this.value.trim().length === 0) {
        $(this).removeClass('border');
        submitBtn.removeClass('show');
      }
    }).on('keyup', function() {
      if (this.value.trim().length > 0) {
        submitBtn.addClass('show');
      } else {
        submitBtn.removeClass('show');
      }
    });
  }

  function initDeleteComment() {
    $('.comment-container .delete-button').off().click(function(e) {
      var $this = $(this);
      if (confirm($this.attr('data-confirm-message'))) {
        $.ajax({
          url: $this.attr('data-url'),
          type: 'DELETE',
          dataType: 'json',
          success: () => {
            changeCounter($this, -1);
            $this.closest('.comment-container').remove();
          },
          error: (error) => {
            if (error.status === 403) {
              HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
            } else {
              alert(error.responseJSON.errors.message);
            }
          }
        });
      }
      e.preventDefault();
      e.stopPropagation();
    });
  }

  function initCreateComment() {
    $.each($('.new-message-container'), (index, el) => {
      var $el = $(el);
      newCommentValidation(
        $el.find('textarea'),
        $el.find('.new-comment-button')
      );
      $el.find('.new-comment-button').off('click').click(() => {
        var errorField = $el.find('.new-message-error');
        var newButton = this;
        if (newButton.disable) return;
        newButton.disable = true;
        $.post(el.dataset.createUrl, {
          comment: { message: $el.find('#message').val() }
        }, (result) => {
          $el.parent().find('.comments-list').append(result.html);
          changeCounter($el, 1);
          inlineEditing.init();
          initDeleteComment();
          scrollBottom($el.parent().find('.content-comments'));
          errorField.html('');
          $el.find('#message').val('');
          $el.find('.new-comment-button').removeClass('show');
          newButton.disable = false;
          $el.find('textarea').focus().blur();
        }).fail((error) => {
          if (error.status === 403) {
            HelperModule.flashAlertMsg(I18n.t('general.no_permissions'), 'danger');
          }
          errorField.text(error.responseJSON.errors.message);
          newButton.disable = false;
        });
      });
    });
  }

  function initMoreButton() {
    $('.comments-container .btn-more-comments-new').off()
      .on('ajax:success', function(e, result) {
        var moreBtn = $(this);
        if (result.moreUrl) {
          moreBtn.closest('.comments-container').find('.comments-list').prepend(result.html);
          inlineEditing.init();
          initDeleteComment();
          if (result.resultsNumber < result.perPage) {
            moreBtn.remove();
          } else {
            moreBtn.attr('href', result.moreUrl);
            moreBtn.trigger('blur');
          }
        } else {
          moreBtn.remove();
        }
      });
  }

  function checkContainerSize(mode) {
    if (mode === 'simple') {
      $('.comments-container').addClass('simple');
    }
  }

  function initPerfectScroll() {
    $.each($('.comments-container .content-comments'), function(index, object) {
      var ps = new PerfectScrollbar(object, { wheelSpeed: 0.5 });
      $(document).ajaxComplete(() => {
        ps.update();
      });
    });
  }

  return {
    init: (mode) => {
      if ($('.comments-container').length > 0) {
        initCreateComment();
        initDeleteComment();
        initMoreButton();
        checkContainerSize(mode);
        setTimeout(() => {
          scrollBottom($('.content-comments'));
        }, 500);
        initPerfectScroll();
      }
    },
    scrollBottom: () => {
      scrollBottom($('.content-comments'));
    }
  };
}());

$(document).on('turbolinks:load', function() {
  Comments.init();
});
