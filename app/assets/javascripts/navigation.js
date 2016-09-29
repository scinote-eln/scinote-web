(function(){
  'use strict';

  /* Loading overlay for search */
  $("#search-bar").submit(function (){
    if( $("#update-canvas") ){
      $(document.body).spin(true);
      setTimeout(function(){
        $(".spinner").remove();
      }, 1000);
    } else {
      animateSpinner();
    }
  });

  function loadDropdownNotifications() {
    var button = $('#notifications-dropdown');
    button
      .on('click', function() {
        $.ajax({
          url: button.attr('data-href'),
          type: 'GET',
          dataType: 'json',
          success: function(data) {
            $('.notifications-dropdown-header')
              .nextAll('li.notification')
              .remove();
            $('.notifications-dropdown-header')
              .after(data.html);
          }
        });
      });
  }

  function loadUnseenNotificationsNumber() {
    var notificationCount = $('#count-notifications');
    $.ajax({
      url: notificationCount.attr('data-href'),
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        notificationCount.html('');
        notificationCount.html(data.notificationNmber);
      }
    });
  }

  // init
  loadDropdownNotifications();
  loadUnseenNotificationsNumber();
})();
