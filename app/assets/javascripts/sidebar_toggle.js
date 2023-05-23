var SideBarToggle = (function() {
  var LAYOUT = ".sci--layout";
  var WRAPPER = '#wrapper'
  var SIDEBAR_CONTAINER = ".sidebar-container"


  function show() {
    $(LAYOUT).attr("data-navigator-collapsed", false);
    $(SIDEBAR_CONTAINER).removeClass('collapsed');
    $(WRAPPER).css('paddingLeft', 'var(--wrapper-width)');
    $('.navbar-secondary').removeClass("navbar-without-sidebar");
    $(WRAPPER).trigger('sideBar::show');
    $(WRAPPER).one("transitionend", function() {
      $(WRAPPER).trigger('sideBar::shown');
    })
  }

  function hide() {
    $(LAYOUT).attr("data-navigator-collapsed", true);
    $(SIDEBAR_CONTAINER).addClass('collapsed');
    $(WRAPPER).css('paddingLeft', '0');
    $('.navbar-secondary').addClass("navbar-without-sidebar");
    $(WRAPPER).trigger('sideBar::hide');
    $(WRAPPER).one("transitionend", function() {
      $(WRAPPER).trigger('sideBar::hidden');
    })
  }

  $(document).on('click', `.sidebar-container .close-sidebar`, function() {
    hide();
  }).on('click', `.sidebar-container .show-sidebar`, function() {
    show();
  }).on('turbolinks:load', function() {
    if ($(LAYOUT).attr("data-navigator-collapsed") === "true") {
      hide();
    } else {
      show();
    }
    $(WRAPPER).show();
  })

  return Object.freeze({
    show: show,
    hide: hide
  })
}());

