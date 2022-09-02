$(document).on('click', '.dropdown-async button', function(e) {
  var $parent = $(e.currentTarget).parent();

  $.get($parent.data('dropdown-url'), function(data) {
    $parent.find('ul').replaceWith(data.html);
  });
});
