(function() {
  'use strict';

  function initRepositoriesDropDown() {
    var dropDown = $('.repositories-dropdown');
    var dropDownMenu = $('.repositories-dropdown-menu');
    dropDown.on('show.bs.dropdown', function() {
      dropDownMenu.html(
        '<div class="text-center"><i class="fas fa-spinner fa-spin"></i></div>'
      );
      $.ajax({
        url: dropDown.data('url'),
        type: 'GET',
        dataType: 'json',
        success: function(data) {
          dropDownMenu.html(data.html);
        }
      });
    });
  }

  // init
  initRepositoriesDropDown();
}());
