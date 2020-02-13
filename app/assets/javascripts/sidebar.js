/**
 * The functions here are global because they need to be
 * accesed from outside (in reports view).
 */

/* global I18n _ */
(function() {
  const SIDEBAR_ID = '#slide-panel';
  const STORAGE_TREE_KEY = 'scinote-sidebar-tree-collapsed-ids';

  /**
   * Get all collapsed sidebar elements.
   * @return An array of sidebar element IDs.
   */
  function sessionGetCollapsedSidebarElements() {
    var val = sessionStorage.getItem(STORAGE_TREE_KEY);
    if (val === null) {
      val = '[]';
      sessionStorage.setItem(STORAGE_TREE_KEY, val);
    }
    return JSON.parse(val);
  }

  /**
   * Collapse a specified element in the sidebar.
   * @param id - The collapsed element's ID.
   */
  function sessionCollapseSidebarElement(project, id) {
    var ids = sessionGetCollapsedSidebarElements();
    var item = _.findWhere(ids, { prid: project });
    var collapsed = { prid: project, ids: [] };
    var storedProjects = _.pluck(ids, 'prid');

    if (_.contains(storedProjects, project)) {
      if (item && _.indexOf(item.ids, id) === -1) {
        _.findWhere(ids, { prid: project }).ids.push(id);
      }
    } else {
      collapsed.ids.push(id);
      ids.push(collapsed);
    }
    sessionStorage.setItem(STORAGE_TREE_KEY, JSON.stringify(ids));
  }

  /**
   * Recalculate the position of the elements after an experiment
   * is added or archived.
   */
  function recalculateElementsPositions(ids, item, elements) {
    let diff;

    if (item.eleNum > elements) {
      diff = item.eleNum - elements;
      _.map(item.ids, function(element, index) {
        item.ids[index] = element - diff;
      });
    } else if (item.eleNum < elements) {
      diff = elements - item.eleNum;
      _.map(item.ids, function(element, index) {
        item.ids[index] = element + diff;
      });
    }

    if (item.eleNum !== elements) {
      item.eleNum = elements;
      sessionStorage.setItem(STORAGE_TREE_KEY, JSON.stringify(ids));
    }
  }

  /**
   * Expand a specified element in the sidebar.
   * @param id - The expanded element's ID.
   */
  function sessionExpandSidebarElement(project, id, elements) {
    var ids = sessionGetCollapsedSidebarElements();
    var item = _.findWhere(ids, { prid: project });
    var index = -1;

    if (item) {
      index = _.indexOf(item.ids, id);
      recalculateElementsPositions(ids, item, elements);
    }

    if (index !== -1) {
      item.ids.splice(index, 1);
      sessionStorage.setItem(STORAGE_TREE_KEY, JSON.stringify(ids));
    }
  }

  /**
   * Setup the sidebar collapsing & expanding functionality.
   */
  function setupSidebarTree() {
    $('.tree a').click(function() {
      var url = new URL($(this).attr('href'));
      url.searchParams.set('scroll', $('.tree').scrollTop());
      $(this).attr('href', url.toString());
    });

    function toggleLi(el, collapse, animate) {
      var children = el.find(' > ul > li');

      if (collapse) {
        if (animate) {
          children.hide('fast');
        } else {
          children.hide();
        }
        el.find(' > span i')
          .attr('title', I18n.t('sidebar.branch_expand'))
          .removeClass('expanded');
      } else {
        if (animate) {
          children.show('fast');
        } else {
          children.show();
        }
        el.find(' > span i')
          .attr('title', I18n.t('sidebar.branch_collapse'))
          .addClass('expanded');
      }
    }

    // Make active current project/experiment/task
    function activateCurrent() {
      var sidebar = $(SIDEBAR_ID);
      var projectId = sidebar.data('current-project');
      var experimentId = sidebar.data('current-experiment');
      var taskId = sidebar.data('current-task');
      var currentPage = sidebar.data('page');
      var link;

      if (currentPage === 'project') {
        link = sidebar.find(`a[data-type="project"][data-id="${projectId}"]`);
      } else if (currentPage === 'experiment') {
        link = sidebar.find(`a[data-type="experiment"][data-id="${experimentId}"]`);
      } else if (currentPage === 'canvas') {
        link = sidebar.find(`a[data-type="experiment"][data-id="${experimentId}"]`);
        let treeLink = link.closest('li').find('.task-tree-link');
        treeLink.find('.canvas-center-on').remove();
        treeLink.append('<a href="" class="canvas-center-on"><span class="fas fa-map-marker-alt"></span></a>');
      } else if (currentPage === 'task') {
        link = sidebar.find(`a[data-type="my_module"][data-id="${taskId}"]`);
      }
      link.addClass('disabled');
      link.closest('li').addClass('active');
    }

    activateCurrent();

    // Add triangle icons and titles to every parent node
    $('.tree li:has(ul)')
      .addClass('parent_li')
      .find(' > span i')
      .attr('title', I18n.t('sidebar.branch_collapse'));
    $('.tree li.parent_li ')
      .find('> span i')
      .removeClass('no-arrow')
      .addClass('fas fa-caret-right expanded');

    // Add IDs to all parent <lis>
    let i = 0;
    _.each($('[data-parent="candidate"]'), function(el) {
      $(el).attr('data-toggle-id', i += 1);
    });

    // Get the current project
    let project = $('[data-current-project]').data('currentProject');

    // Set number of elements
    sessionExpandSidebarElement(
      project, null, $('[data-parent="candidate"]').length
    );

    // Get the session-stored elements
    let collapsedIds = sessionGetCollapsedSidebarElements();

    // Get the current project stored elements
    let currentProjectIds = _.findWhere(collapsedIds, { prid: project });
    if (currentProjectIds) {
      currentProjectIds.ids = _.filter(currentProjectIds.ids, function(val) { return val !== null; }).join(', ');

      // Collapse session-stored elements
      _.each($('li.parent_li[data-parent="candidate"]'), function(el) {
        var id = $(el).data('toggle-id');
        var li = $(".tree li.parent_li[data-toggle-id='" + id + "']");

        if (li.hasClass('active') || li.find('.active').length > 0) {
          // Always expand the active element
          toggleLi(li,
            false,
            false);
        } else if ($.inArray(id.toString(), currentProjectIds.ids.split(', ')) !== -1) {
          // Expande element
          toggleLi(li,
            false,
            false);
        } else {
          // Collapse the session-stored element
          toggleLi(li,
            true,
            false);
        }
      });
    } else {
      // Collapse all
      _.each($('li.parent_li[data-parent="candidate"]'), function(el) {
        var id = $(el).data('toggle-id');
        var li = $(".tree li.parent_li[data-toggle-id='" + id + "']");

        if (li.hasClass('active') || li.find('.active').length > 0) {
          // Always expand the active element
          toggleLi(li, false, false);
          sessionCollapseSidebarElement(project, id);
        } else {
          // Element collapsed by default
          toggleLi(li, true, false);
        }
      });
    }

    // Add onclick callback to every triangle icon
    $('.tree li.parent_li ').find('> span i').on('click', function(e) {
      let el = $(this).parent('span').parent('li.parent_li');

      if (el.find(' > ul > li').is(':visible')) {
        toggleLi(el, true, true);
        sessionExpandSidebarElement(project, el.data('toggle-id'), $('[data-parent="candidate"]').length);
      } else {
        toggleLi(el, false, true);
        sessionCollapseSidebarElement(project, el.data('toggle-id'));
      }
      e.stopPropagation();
      return false;
    });

    // Add bold style to all levels of selected element
    $('.tree li.active ').parents('.parent_li[data-parent="candidate"]').find('> span a').css('font-weight', 'bold');

    // Add custom borders to tree links
    $('.tree li span.tree-link ').after("<div class='border-custom'></div>");
  }

  // Resize the sidebar to accomodate to the page size
  function resizeSidebarContents() {
    var tree = $('#sidebar-wrapper .tree');

    // Set vertical scrollbar on navigation tree
    if (tree.length && tree.length === 1) {
      tree.css('height', ($(window).height() - tree.position().top - 50) + 'px');
    }
  }

  function scrollToSelectedItem() {
    $(`${SIDEBAR_ID} .tree`).scrollTo($('.tree').data('scroll'));
  }

  // Initialize click listeners
  setupSidebarTree();

  // Actually display wrapper, which is, up to now,
  // hidden
  $('#wrapper').show();

  // Resize the sidebar automatically
  resizeSidebarContents();

  // Bind onto window resize function
  $(window).resize(function() {
    resizeSidebarContents();
    scrollToSelectedItem();
  });

  scrollToSelectedItem();
}(window));
