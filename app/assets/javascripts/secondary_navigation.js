(function() {
  'use strict';

  function initRepositoriesDropDown() {
    var dropDown = $('.repositories-dropdown');
    var dropDownMenu = $('.repositories-dropdown-menu');
    dropDown.on('show.bs.dropdown', function() {
      dropDownMenu
        .find('.assigned-items-counter')
        .html('<i class="fas fa-spinner fa-spin"></i>');
      $.ajax({
        url: dropDown.data('url'),
        type: 'GET',
        dataType: 'json',
        success: function(data) {
          dropDownMenu.html(data.html);
        },
        error: function() {
          dropDownMenu.find('.assigned-items-counter').html('');
        }
      });
    });
  }

  // init
  initRepositoriesDropDown();
}());
