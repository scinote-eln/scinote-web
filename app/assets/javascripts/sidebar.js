/* global PerfectScrollbar */

var Sidebar = (function() {
  const SIDEBAR_CONTAINER = '.sidebar-container';

  function showSelectedLeaf() {
    var branchSelectors = $(SIDEBAR_CONTAINER).find('.sidebar-link.selected')
      .parents('.sidebar-leaf')
      .find('> .toggle-branch');
    branchSelectors.removeClass('collapsed fa-caret-right').addClass('fa-caret-down');
  }

  function reloadSidebar(params) {
    let url = $(SIDEBAR_CONTAINER).data('sidebar-url');
  }

  function initSideBar() {
    var sidebarBody = $(SIDEBAR_CONTAINER).find('.sidebar-body');
    var scrollBar = new PerfectScrollbar(sidebarBody[0], {
      wheelSpeed: 0.5, minScrollbarLength: 20
    });
    $(SIDEBAR_CONTAINER).data('scrollBar', scrollBar);
    $(SIDEBAR_CONTAINER).on('click', '.toggle-branch', function() {
      $(this).toggleClass('collapsed fa-caret-down fa-caret-right');
      $(SIDEBAR_CONTAINER).data('scrollBar').update();
    });
  }

  return {
    init: () => {
      if ($(SIDEBAR_CONTAINER).length) {
        initSideBar();
        showSelectedLeaf();
        $('#wrapper').show();
      }
    },

    reload: (params = {}) => {
      reloadSidebar(params);
    }
  };
}());

$(document).on('turbolinks:load', function() {
  Sidebar.init();
});
