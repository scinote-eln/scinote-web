window.bwipjs = require('bwip-js');
window.Decimal = require('decimal.js');

$(document).on('click', '.sci--layout--menu-item[data-submenu=true]', (e) => {
  const item = $(e.currentTarget);
  const caret = item.find('.show-submenu');
  const submenu = item.next();
  e.preventDefault();
  if (submenu.attr('data-collapsed') === 'true') {
    caret.removeClass('fa-caret-right').addClass('fa-caret-down');
    submenu.attr('data-collapsed', false);
  } else {
    caret.removeClass('fa-caret-down').addClass('fa-caret-right');
    submenu.attr('data-collapsed', true);
  }
});

$(document).on('click', '.sci--layout--navigator-open', (e) => {
  navigatorContainer.$data.navigatorCollapsed = false
});
