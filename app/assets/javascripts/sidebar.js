/**
 * The functions here are global because they need to be
 * accesed from outside (in reports view).
 */

var STORAGE_TREE_KEY = "scinote-sidebar-tree-collapsed-ids";
var STORAGE_TOGGLE_KEY = "scinote-sidebar-toggled";
var SCREEN_SIZE_LARGE = 928;

/**
 * Get all collapsed sidebar elements.
 * @return An array of sidebar element IDs.
 */
function sessionGetCollapsedSidebarElements() {
  var val = sessionStorage.getItem(STORAGE_TREE_KEY);
  if (val === null) {
    val = "[]";
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
  var stored_projects = _.pluck(ids, 'prid');

  if ( _.contains(stored_projects, project ) ){
    if ( item && _.indexOf(item.ids, id) === -1 ) {
      _.findWhere(ids, { prid: project }).ids.push(id);
    }
  } else {
    collapsed.ids.push(id);
    ids.push(collapsed);
  }
  sessionStorage.setItem(STORAGE_TREE_KEY, JSON.stringify(ids));
}

/**
 * Expand a specified element in the sidebar.
 * @param id - The expanded element's ID.
 */
function sessionExpandSidebarElement(project, id) {
  var ids = sessionGetCollapsedSidebarElements();
  var item = _.findWhere(ids, { prid: project});
  var index = -1;
  if ( item ) {
  index = _.indexOf(item.ids, id);
  }

  if ( index !== -1 ) {
    item.ids.splice(index, 1);
    sessionStorage.setItem(STORAGE_TREE_KEY, JSON.stringify(ids));
  }
}

/**
 * Get the session stored toggled boolean or null value if
 * sidebar toggle state was not changed by user. It allow for
 * automatic toggling for small devices.
 *
 * @return True if sidebar is toggled; false otherwise.
 */
function sessionIsSidebarToggled() {
  var val = sessionStorage.getItem(STORAGE_TOGGLE_KEY);

  if (val === null) {
    return null;
  }

  return val === "toggled";
}

/**
 * Store the sidebar toggled boolean to session storage.
 */
function sessionToggleSidebar() {
  if (sessionIsSidebarToggled()) {
    sessionStorage.setItem(STORAGE_TOGGLE_KEY, "not_toggled");
  } else {
    sessionStorage.setItem(STORAGE_TOGGLE_KEY, "toggled");
  }
}

/**
 * Setup the sidebar collapsing & expanding functionality.
 */
function setupSidebarTree() {
  function toggleLi(el, collapse, animate) {
    var children = el
    .find(" > ul > li");

    if (collapse) {
      if (animate) {
      children.hide("fast");
      } else {
        children.hide();
      }
      el
      .find(" > span i")
      .attr("title", "Expand this branch")
      .removeClass("expanded");
    } else {
      if (animate) {
        children.show("fast");
      } else {
        children.show();
      }
      el
      .find(" > span i")
      .attr("title", "Collapse this branch")
      .addClass("expanded");
    }
  }

  // Add triangle icons and titles to every parent node
  $(".tree li:has(ul)")
  .addClass("parent_li")
  .find(" > span i")
  .attr("title", "Collapse this branch");
  $(".tree li.parent_li ")
  .find("> span i")
  .addClass("glyphicon glyphicon-triangle-right expanded");

  // Add IDs to all parent <lis>
  var i = 0;
  _.each($('[data-parent="candidate"]'), function(el) {
    $(el).attr("data-toggle-id", i++);
  });

  // Gets the current project and the session-stored elements
  var project = $('[data-project-id]').data('projectId');
  var collapsedIds = sessionGetCollapsedSidebarElements();

  // Get the current project stered elements
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
      } else if ( $.inArray( id.toString(), currentProjectIds.ids.split(", ")) !== -1 ) {
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
      sessionExpandSidebarElement(project, el.data("toggle-id"));
    } else {
      toggleLi(el, false, true);
      sessionCollapseSidebarElement(project, el.data("toggle-id"));
    }
    e.stopPropagation();
    return false;
  });
}

/**
 * Initialize the show/hide toggling of sidebar.
 */
function initializeSidebarToggle() {
  var wrapper = $("#wrapper");
  var toggled = sessionIsSidebarToggled();

  if (toggled || toggled === null && $(window).width() < SCREEN_SIZE_LARGE) {
    wrapper.addClass("no-animation");
    wrapper.addClass("toggled");
    // Cause reflow of the wrapper element
    wrapper[0].offsetHeight;
    wrapper.removeClass("no-animation");
    $(".navbar-secondary").addClass("navbar-without-sidebar");
  }

  $("#toggle-sidebar-link").on("click", function() {
    $("#wrapper").toggleClass("toggled");
    sessionToggleSidebar();
    $(".navbar-secondary").toggleClass("navbar-without-sidebar", sessionIsSidebarToggled());
    return false;
  });
}

// Resize the sidebar to accomodate to the page size
function resizeSidebarContents() {
  var wrapper = $("#wrapper");
  var tree = $("#sidebar-wrapper .tree");
  var toggled = sessionIsSidebarToggled();
  var navbar = $(".navbar-secondary");

  if (tree.length && tree.length == 1) {
    tree.css(
      "height",
      ($(window).height() - tree.position().top - 50) + "px"
    );
  }
  // Automatic toggling of sidebar for smaller devices
  if (toggled === null) {
    if ($(window).width() < SCREEN_SIZE_LARGE) {
      wrapper.addClass("toggled");
      navbar.addClass("navbar-without-sidebar");
    } else {
      wrapper.removeClass("toggled");
      navbar.removeClass("navbar-without-sidebar");
    }
  }
}

(function () {
  // Initialize click listeners
  setupSidebarTree();
  initializeSidebarToggle();

  // Actually display wrapper, which is, up to now,
  // hidden
  $("#wrapper").show();

  // Resize the sidebar automatically
  resizeSidebarContents();

  // Bind onto window resize function
  $(window).resize(function() {
    resizeSidebarContents();
  });
}());
