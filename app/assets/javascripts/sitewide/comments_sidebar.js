/* global SmartAnnotation */

var CommentsSidebar = (function() {
  const SIDEBAR = '.comments-sidebar';

  function initCloseButton() {
    $(document).on('click', `${SIDEBAR} .close-btn`, function() {
      CommentsSidebar.close();
    });
  }

  function loadCommentsList() {
    var commentsUrl = $(SIDEBAR).data('comments-url');
    $.get(commentsUrl, {
      object_type: $(SIDEBAR).data('object-type'),
      object_id: $(SIDEBAR).data('object-id')
    }, function(result) {
      $(SIDEBAR).removeClass('loading');
      $(SIDEBAR).find('.comments-subject-title').text(result.object_name);
      $(SIDEBAR).find('.comments-list').html(result.comments);
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
        }
      });
    });
  }

  function initCancelButton() {
    $(document).on('click', `${SIDEBAR} .cancel-button`, function() {
      $(SIDEBAR).find('.comment-input-field').val('');
      $(SIDEBAR).find('.sidebar-footer').removeClass('update');
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
      $(SIDEBAR).find('.comment-input-field')
        .val($(this).data('comment-raw'))
        .data('update-url', $(this).data('update-url'));
    });
  }

  function initInputField() {
    $(document).on('ready', function() {
      SmartAnnotation.init($(SIDEBAR).find('.comment-input-field'));
    });
  }

  return {
    init: function() {
      initCloseButton();
      initSendButton();
      initDeleteButton();
      initInputField();
      initEditButton();
      initCancelButton();
    },
    open: function(objectType, objectId) {
      $(SIDEBAR).find('.comments-subject-title').empty();
      $(SIDEBAR).find('.comments-list').empty();
      $(SIDEBAR).find('.comment-input-field').val('');
      $(SIDEBAR).find('.sidebar-footer').removeClass('update');
      $(SIDEBAR).data('object-type', objectType).data('object-id', objectId);
      $(SIDEBAR).addClass('open loading');
      loadCommentsList();
    },
    close: function() {
      $(SIDEBAR).removeClass('open');
    }
  };
}());

CommentsSidebar.init();
