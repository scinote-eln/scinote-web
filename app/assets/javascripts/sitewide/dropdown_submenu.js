$(document).on('click', '.dropdown-submenu-item', function(e) {
  e.preventDefault();
  e.stopPropagation();
  $(this).toggleClass('active');
});

$(document).on('click', '.dropdown-submenu', function(e) {
  e.preventDefault();
  e.stopPropagation();
  $('.dropdown-submenu-item').removeClass('active');
  $('.dropdown').removeClass('open');
});
