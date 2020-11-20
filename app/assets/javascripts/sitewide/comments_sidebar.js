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

  return {
    init: function() {
      initCloseButton();
    },
    open: function(objectType, objectId) {
      $(SIDEBAR).find('.comments-subject-title').empty();
      $(SIDEBAR).find('.comments-list').empty();
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
