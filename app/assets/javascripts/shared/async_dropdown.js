/* eslint-disable no-unused-vars */

var AsyncDropdown = {
  init: function($container) {
    $container.on('click', '.dropdown-async button', function(e) {
      var $parent = $(e.currentTarget).parent();

      if ($parent.data('async-dropdown-initialized')) return;

      $parent.on('show.bs.dropdown', function() {
        $parent.find('ul').empty().hide();
        $.get($parent.data('dropdown-url'), function(data) {
          $parent.find('ul').replaceWith(data.html);
        });
      });

      $parent.data('async-dropdown-initialized', true);
    });
  }
};
