/* global SmartAnnotation */

var CommentsSidebar = (function() {
  const SIDEBAR = '.comments-sidebar';
  var commentsCounter;
  var closeCallback;

  function loadCommentsList() {
    var commentsUrl = $(SIDEBAR).data('comments-url');
    $.get(commentsUrl, {
      object_type: $(SIDEBAR).data('object-type'),
      object_id: $(SIDEBAR).data('object-id')
    }, function(result) {
      $(SIDEBAR).removeClass('loading');
      $(SIDEBAR).find('.comments-subject-title').text(result.object_name);
      $(SIDEBAR).find('.comments-subject-url').html(result.object_url);
      $(SIDEBAR).find('.comments-list').html(result.comments);

      if (result.comment_addable) {
        $(SIDEBAR).find('.comment-input-container').removeClass('hidden');
      } else {
        $(SIDEBAR).find('.comment-input-container').addClass('hidden');
        $(SIDEBAR).find('.comment-input-container').addClass('update-only');
      }
    });
  }

  function updateCounter() {
    var commentsAmount = $(SIDEBAR).find('.comments-list .comment-container').length;
    if (commentsCounter.length) {
      // Replace the number in comment element
      commentsCounter.text(commentsCounter.text().replace(/[\d\\+]+/g, commentsAmount));
      commentsCounter.removeClass('hidden');
      commentsCounter.css('display', 'flex');
    }
  }

  function initOpenButton() {
    $(document).on('click', '.open-comments-sidebar', function(e) {
      commentsCounter = $(`#comment-count-${$(this).data('objectId')}`);
      closeCallback = $(this).data('closeCallback');
      CommentsSidebar.open($(this).data('objectType'), $(this).data('objectId'));
      $(this).parent().find('.unseen-comments').remove();
      e.preventDefault();
    });
  }

  function initCloseButton() {
    $(document).on('click', `${SIDEBAR} .close-btn`, function() {
      CommentsSidebar.close();
      if (closeCallback) closeCallback();
    });
  }

  function initScrollButton() {
    $(document).on('click', `${SIDEBAR} .scroll-page-with-anchor`, function(e) {
      e.preventDefault();
      $($(this).attr('href'))[0].scrollIntoView();
      window.scrollBy(0, -130);
    });
  }

  function initSendButton() {
    $(document).on('click', `${SIDEBAR} .send-comment, ${SIDEBAR} .update-comment`, function() {
      var requestUrl;
      var requestType;
      var updateMode = $(SIDEBAR).find('.sidebar-footer').hasClass('update');
      var inputField = $(SIDEBAR).find('.comment-input-field');
      if (updateMode) {
        requestType = 'PATCH';
        requestUrl = inputField.data('update-url');
      } else {
        requestType = 'POST';
        requestUrl = $(SIDEBAR).data('comments-url');
      }
      $.ajax({
        url: requestUrl,
        type: requestType,
        dataType: 'json',
        data: {
          object_type: $(SIDEBAR).data('object-type'),
          object_id: $(SIDEBAR).data('object-id'),
          message: inputField.val()
        },
        success: (result) => {
          if (updateMode) {
            $('.comment-container.edit').replaceWith(result.html);
          } else {
            $(result.html).appendTo(`${SIDEBAR} .comments-list`);
          }
          $(SIDEBAR).find('.comment-input-field').val('');
          $(SIDEBAR).find('.sidebar-footer').removeClass('update');
          if ($(SIDEBAR).find('.comment-input-container').hasClass('update-only')) {
            $(SIDEBAR).find('.comment-input-container').addClass('hidden');
          }
          $('.error-container').empty();
          updateCounter();
        },
        error: (result) => {
          $('.error-container').text(result.responseJSON.errors.message);
        }
      });
    });
  }

  function initCancelButton() {
    $(document).on('click', `${SIDEBAR} .cancel-button`, function() {
      $(SIDEBAR).find('.comment-input-field').val('');
      $(SIDEBAR).find('.sidebar-footer').removeClass('update');
      if ($(SIDEBAR).find('.comment-input-container').hasClass('update-only')) {
        $(SIDEBAR).find('.comment-input-container').addClass('hidden');
      }
    });
  }

  function initDeleteButton() {
    $(document).on('click', `${SIDEBAR} .delete-comment`, function(e) {
      var deleteUrl = $(this).data('delete-url');
      var commentContainer = $(this).closest('.comment-container');
      e.preventDefault();
      $.ajax({
        url: deleteUrl,
        type: 'DELETE',
        dataType: 'json',
        success: () => {
          commentContainer.remove();
          updateCounter();
        }
      });
    });
  }

  function initEditButton() {
    $(document).on('click', `${SIDEBAR} .edit-comment`, function(e) {
      e.preventDefault();

      $('.comment-container').removeClass('edit');
      $(this).closest('.comment-container').addClass('edit');
      $(SIDEBAR).find('.sidebar-footer').addClass('update');
      if ($(SIDEBAR).find('.comment-input-container').hasClass('hidden')) {
        $(SIDEBAR).find('.comment-input-container').removeClass('hidden');
      }
      $(SIDEBAR).find('.comment-input-field')
        .val($(this).data('comment-raw'))
        .data('update-url', $(this).data('update-url'));
    });
  }

  function initInputField() {
    if ($(SIDEBAR).find('.comment-input-field').length) {
      SmartAnnotation.init($(SIDEBAR).find('.comment-input-field'), false);
    }
  }

  return {
    init: function() {
      initOpenButton();
      initCloseButton();
      initSendButton();
      initDeleteButton();
      initEditButton();
      initCancelButton();
      initScrollButton();
    },
    open: function(objectType, objectId) {
      $(SIDEBAR).find('.comments-subject-title').empty();
      $(SIDEBAR).find('.comments-list').empty();
      $(SIDEBAR).find('.comment-input-field').val('').focus();
      $('.error-container').empty();
      $(SIDEBAR).find('.sidebar-footer').removeClass('update');
      $(SIDEBAR).data('object-type', objectType).data('object-id', objectId);
      $(SIDEBAR).addClass('open loading');
      initInputField();
      loadCommentsList();
    },
    close: function() {
      $(SIDEBAR).removeClass('open');
    }
  };
}());

CommentsSidebar.init();
