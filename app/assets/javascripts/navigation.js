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
          beforeSend: animateSpinner($('.notifications-dropdown-header'), true),
          success: function(data) {
            $('.notifications-dropdown-header')
              .nextAll('li.notification')
              .remove();
            $('.notifications-dropdown-header')
              .after(data.html);
            animateSpinner($('.notifications-dropdown-header'), false);
          }
        });
        $('#count-notifications').hide();
        toggleNotificationBellPosition();
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
        if ( data.notificationNmber > 0 ) {
          notificationCount.html(data.notificationNmber);
          notificationCount.show();
          toggleNotificationBellPosition();
        } else {
          notificationCount.hide();
        }

      }
    });
  }

  function toggleNotificationBellPosition() {
    var notificationCount = $('#count-notifications');
    var button = $('#notifications-dropdown');

    if ( notificationCount.is(":hidden") ) {
      button
        .find('.fa-bell')
        .css('position', 'relative');
    } else {
      button
        .find('.fa-bell')
        .css('position', 'absolute');
    }

  }

  // init
  loadDropdownNotifications();
  loadUnseenNotificationsNumber();
  toggleNotificationBellPosition();
})();
