(function(global) {
  'use strict';
  global.SideBarToggle = (function() {
    var STORAGE_TOGGLE_KEY = "scinote-sidebar-toggled";

    function show() {
      $('#wrapper').removeClass('hidden2');
      $('#wrapper').css('paddingLeft', '280px');
      $('.navbar-secondary').css(
        { 'margin-left': '-280px', 'padding-left': '294px' }
      );
      $('#sidebar-arrow').attr('data-shown', '');
      sessionStorage.setItem(STORAGE_TOGGLE_KEY, "un-toggled");
    }

    function hide() {
      $('#wrapper').addClass('hidden2');
      $('#wrapper').css('paddingLeft', '0');
      $('.navbar-secondary').css({
        'margin-left': '0',
        'padding-left': '14px'
      });
      $('#sidebar-arrow').removeAttr('data-shown');
      sessionStorage.setItem(STORAGE_TOGGLE_KEY, "toggled");
    }

    function toggle() {
      var btn = $('#sidebar-arrow');
      if (btn.is('[data-shown]')) {
        hide();
      } else {
        show();
      }
    }

    function isShown() {
      var btn = $('#sidebar-arrow');
      return btn.is('[data-shown]');
    }

    function isToggledStorage() {
      var val = sessionStorage.getItem(STORAGE_TOGGLE_KEY);
      if (val === null) {
        return null;
      }
      return val === "toggled";
    }

    return Object.freeze({
      show: show,
      hide: hide,
      toggle: toggle,
      isShown: isShown,
      isToggledStorage: isToggledStorage
    })
  })();

  if (SideBarToggle.isToggledStorage()) {
    SideBarToggle.hide();;
  }
})(window);
