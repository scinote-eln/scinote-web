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
  console.log(val);
  val = JSON.parse(val);
  val = val.filter(Number);
 console.log(val);
  return val;
}

/**
 * Collapse a specified element in the sidebar.
 * @param id - The collapsed element's ID.
 */
function sessionCollapseSidebarElement(id) {
  var ids = sessionGetCollapsedSidebarElements();
  if (_.indexOf(ids, id) === -1) {
    ids.push(id);
    sessionStorage.setItem(STORAGE_TREE_KEY, JSON.stringify(ids));
  }
}

/**
 * Expand a specified element in the sidebar.
 * @param id - The expanded element's ID.
 */
function sessionExpandSidebarElement(id) {
  var ids = sessionGetCollapsedSidebarElements();
  var index = _.indexOf(ids, id);
  if (index !== -1) {
    ids.splice(index, 1);
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
  var i = 1;
  _.each($(".tree li.parent_li"), function(el) {
    $(el).attr("data-toggle-id", i++);
  });

  // Collapse session-stored elements
  var collapsedIds = sessionGetCollapsedSidebarElements();
  console.log($(".line-wrap").parent());
  _.each($(".line-wrap").parent(), function(el) {
    console.log(collapsedIds);
    var id = $(el).data("toggle-id");
    var li = $(".tree li.parent_li[data-toggle-id='" + id + "']");
    if( li.hasClass("active") ){
      // Only collapse element if it's descendants don't contain the currently
      // active element
      toggleLi(li,
        false,
        false);
        sessionCollapseSidebarElement(id);
    } else if ($.inArray( id, collapsedIds) === 0 ) {
      console.log("in");
      console.log(id);
      toggleLi(li,
        true,
        false);
        sessionExpandSidebarElement(id);
    } else {
      console.log("-------- last -----");
      console.log(id);
      console.log("-------------------");
      // collapse all element
      toggleLi(li,
        true,
        false);
      sessionCollapseSidebarElement(id);
    }
  });

  // Add onclick callback to every triangle icon
  $(".tree li.parent_li ")
  .find("> span i")
  .on("click", function (e) {
    var el = $(this)
    .parent("span")
    .parent("li.parent_li");

    if (el.find(" > ul > li").is(":visible")) {
      toggleLi(el, true, true);
      sessionCollapseSidebarElement(el.data("toggle-id"));
    } else {
      toggleLi(el, false, true);
      sessionExpandSidebarElement(el.data("toggle-id"));
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
    } else {
      wrapper.removeClass("toggled");
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
