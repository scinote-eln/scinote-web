$(document).on('click', '.dropdown-submenu-item', function(e) {
  e.preventDefault();
  e.stopPropagation();

  $(this).toggleClass('active');
});
