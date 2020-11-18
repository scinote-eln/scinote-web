var CommentsSidebar = (function() {
  const SIDEBAR = '.comments-sidebar';

  function initCloseButton() {
    $(document).on('click', `${SIDEBAR} .close-btn`, function() {
      CommentsSidebar.close();
    });
  }

  return {
    init: function() {
      initCloseButton();
    },
    open: function() {
      $(SIDEBAR).find('.comments-subject-title').empty();
      $(SIDEBAR).find('.comments-list').empty();
      $(SIDEBAR).addClass('open loading');
    },
    close: function() {
      $(SIDEBAR).removeClass('open');
    }
  };
}());

CommentsSidebar.init();
