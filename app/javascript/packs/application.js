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
  navigatorContainer.toggleNavigatorState(false)
});

$(document).on('click', '.btn', function() {
  $(this).blur();
});

