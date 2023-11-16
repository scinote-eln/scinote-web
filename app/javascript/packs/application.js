require('jquery-ujs');
require('jquery-mousewheel');
require('jquery-autosize');
require('jquery-ui/ui/widget');
require('jquery-ui/ui/widgets/mouse');
require('jquery-ui/ui/widgets/sortable');
require('jquery-ui/ui/widgets/draggable');
require('jquery-ui/ui/widgets/droppable');
require('jquery-ui/ui/effects/effect-slide');
require('hammerjs');
import 'bootstrap';
require('bootstrap-select/js/bootstrap-select');
import '@vuepic/vue-datepicker/dist/main.css';
import 'vue3-draggable-resizable/dist/Vue3DraggableResizable.css'

window.bwipjs = require('bwip-js');
window.Decimal = require('decimal.js');

$(document).on('click', '.sci--layout--menu-item[data-submenu=true]', (e) => {
  const item = $(e.currentTarget);
  const caret = item.find('.show-submenu');
  const submenu = item.next();
  e.preventDefault();
  if (submenu.attr('data-collapsed') === 'true') {
    caret.removeClass('sn-icon-right').addClass('sn-icon-down');
    submenu.attr('data-collapsed', false);
  } else {
    caret.removeClass('sn-icon-down').addClass('sn-icon-right');
    submenu.attr('data-collapsed', true);
  }
});

$(document).on('click', '.sci--layout--navigator-open', (e) => {
  navigatorContainer.toggleNavigatorState(false);
});

$(document).on('click', '.btn', function() {
  $(this).blur();
});

$(document).on('turbolinks:load', () => {
  $(window).on('scroll', () => {
    const navbarHeight = 116;
    let scrollPosition = $(window).scrollTop();
    if (scrollPosition > navbarHeight) {
      scrollPosition = navbarHeight;
    }
    $('.sci--layout').css(
      '--navbar-height',
      `calc(var(--top-navigation-height) + var(--breadcrumbs-navigation-height) - ${scrollPosition}px)`
    );
    $('.sci--layout-navigation-navigator').css(
      '--navigator-top-margin',
      ((scrollPosition / navbarHeight) * 16) + 'px'
    );
  });
});

// Needed to support Turbolinks redirect_to responses as unsafe-inline is blocked by the CSP
$.ajaxSetup({
  converters: {
    'text script': function(text) {
      $.globalEval(text, { nonce: document.querySelector('meta[name="csp-nonce"]').getAttribute('content') });
      return text;
    }
  }
});

$(document).on('click', 'a[rel*=external]', function(e) {
  e.preventDefault();
  window.open(this.href, '_blank', 'noopener');
});
