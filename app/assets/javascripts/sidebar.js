/**
 * The functions here are global because they need to be
 * accesed from outside (in reports view).
 */

/* global PerfectSb */

var Sidebar = (function() {
  const SIDEBAR_ID = '#slide-panel';
  const STORAGE_TREE_KEY = 'scinote-sidebar-tree-state';
  const STORAGE_SCROLL_TREE_KEY = 'scinote-sidebar-tree-scroll-state';

  function toggleTree($treeChildren) {
    $treeChildren.toggleClass('hidden');
    $.each($treeChildren, (i, treeChild) => {
      $(treeChild).closest('.branch').find('.tree-toggle').first()
        .toggleClass('fa-caret-down')
        .toggleClass('fa-caret-right');
    });
  }

  function saveCurrentState() {
    var config = [];
    $.each($(SIDEBAR_ID).find('.tree-child:not(:hidden)'), (i, branch) => {
      config.push(`[data-branch-id=${branch.dataset.branchId}]`);
    });
    sessionStorage.setItem(STORAGE_TREE_KEY, config.join(','));
  }

  function loadLastState() {
    toggleTree($(SIDEBAR_ID).find('.tree-child[data-active="true"]'));
    toggleTree($(SIDEBAR_ID).find('.tree-child.hidden').filter(sessionStorage.getItem(STORAGE_TREE_KEY)));
    PerfectSb().update_all();
    $(SIDEBAR_ID).find('.tree').scrollTo(sessionStorage.getItem(STORAGE_SCROLL_TREE_KEY));
  }

  function initSideBar() {
    $(SIDEBAR_ID).on('click', '.tree-toggle', function() {
      var $treeChild = $(this).closest('.branch').find('.tree-child').first();
      toggleTree($treeChild);
      saveCurrentState();
      PerfectSb().update_all();
    });

    $(SIDEBAR_ID).find('.tree').scroll(function() {
      sessionStorage.setItem(STORAGE_SCROLL_TREE_KEY, $(this).scrollTop());
    });

    $('#wrapper').show();
    loadLastState();
  }

  return {
    init: () => {
      if ($(SIDEBAR_ID).length) {
        initSideBar();
      }
    },

    loadLastState: () => {
      loadLastState();
    }
  };
}());

$(document).on('turbolinks:load', function() {
  Sidebar.init();
});
