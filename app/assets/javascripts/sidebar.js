/**
 * The functions here are global because they need to be
 * accesed from outside (in reports view).
 */

/* global I18n _ */
(function(global) {
  var STORAGE_TREE_KEY = 'scinote-sidebar-tree-collapsed-ids';

  /**
   * Get all collapsed sidebar elements.
   * @return An array of sidebar element IDs.
   */
  global.sessionGetCollapsedSidebarElements = function() {
    var val = sessionStorage.getItem(STORAGE_TREE_KEY);
    if (val === null) {
      val = '[]';
      sessionStorage.setItem(STORAGE_TREE_KEY, val);
    }
    return JSON.parse(val);
  };

  /**
   * Collapse a specified element in the sidebar.
   * @param id - The collapsed element's ID.
   */
  global.sessionCollapseSidebarElement = function(project, id) {
    var ids = global.sessionGetCollapsedSidebarElements();
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
  };

  /**
   * Expand a specified element in the sidebar.
   * @param id - The expanded element's ID.
   */
  global.sessionExpandSidebarElement = function(project, id, elements) {
    var ids = global.sessionGetCollapsedSidebarElements();
    var item = _.findWhere(ids, { prid: project});
    var index = -1;

    if (item) {
      index = _.indexOf(item.ids, id);
      global.recalculateElementsPositions(ids, item, elements);
    }

    if (index !== -1) {
      item.ids.splice(index, 1);
      sessionStorage.setItem(STORAGE_TREE_KEY, JSON.stringify(ids));
    }
  };

  /**
   * Recalculate the position of the elements after an experiment
   * is added or archived.
   */
  global.recalculateElementsPositions = function(ids, item, elements) {
    var diff;

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
   * Setup the sidebar collapsing & expanding functionality.
   */
  global.setupSidebarTree = function() {
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
    var i = 0;
    _.each($('[data-parent="candidate"]'), function(el) {
      $(el).attr('data-toggle-id', i += 1);
    });

    // Get the current project
    var project = $('[data-project-id]').data('projectId');

    // Set number of elements
    sessionExpandSidebarElement(
      project, null, $('[data-parent="candidate"]').length
    );

    // Get the session-stored elements
    var collapsedIds = global.sessionGetCollapsedSidebarElements();

    // Get the current project stored elements
    var currentProjectIds = _.findWhere(collapsedIds, { prid: project });
    if ( currentProjectIds ){
      currentProjectIds.ids = _.filter(currentProjectIds.ids,
                                  function(val) {
                                    return val !== null;
                                  }).join(", ");

      // Collapse session-stored elements
      _.each($('li.parent_li[data-parent="candidate"]'), function(el) {
        var id = $(el).data("toggle-id");
        var li = $(".tree li.parent_li[data-toggle-id='" + id + "']");

        if( li.hasClass("active") ||  li.find(".active").length > 0){
          // Always expand the active element
          toggleLi(li,
            false,
            false);
        } else if ( $.inArray( id.toString(),
                               currentProjectIds.ids.split(", ")) !== -1 ) {
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
        var id = $(el).data("toggle-id");
        var li = $(".tree li.parent_li[data-toggle-id='" + id + "']");

        if( li.hasClass("active") ){
          // Always expand the active element
          toggleLi(li,
            false,
            false);
          sessionCollapseSidebarElement(project, id);
        } else {
          // Element collapsed by default
          toggleLi(li,
            true,
            false);
        }
      });
    }

    // Add onclick callback to every triangle icon
    $(".tree li.parent_li ")
    .find("> span i")
    .on("click", function (e) {
      var el = $(this)
      .parent("span")
      .parent("li.parent_li");

      if (el.find(" > ul > li").is(":visible")) {
        toggleLi(el, true, true);
        sessionExpandSidebarElement(project,
                                    el.data("toggle-id"),
                                    $('[data-parent="candidate"]').length );
      } else {
        toggleLi(el, false, true);
        sessionCollapseSidebarElement(project, el.data("toggle-id"));
      }
      e.stopPropagation();
      return false;
    });

    // Add bold style to all levels of selected element
    $(".tree li.active ")
    .parents('.parent_li[data-parent="candidate"]')
    .find("> span a")
    .css("font-weight", "bold");

    // Add custom borders to tree links
    $(".tree li span.tree-link ").after("<div class='border-custom'></div>");
  }

  // Resize the sidebar to accomodate to the page size
  global.resizeSidebarContents = function() {
    var tree = $("#sidebar-wrapper .tree");

    // Set vertical scrollbar on navigation tree
    if (tree.length && tree.length == 1) {
      tree.css(
        "height",
        ($(window).height() - tree.position().top - 50) + "px"
      );
    }
  }

  function scrollToSelectedItem() {
    var offset;
    if ($('#slide-panel .active').length) {
      offset = $('#slide-panel .active').offset().top - 50;
      $('#slide-panel .tree').scrollTo(offset, 10);
    }
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
