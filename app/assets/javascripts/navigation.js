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
    var noRecentText =
      $('.dropdown-notifications .notifications-no-recent');
    button
      .on('click', function() {
        noRecentText.hide();
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

            var ul = $('.dropdown-menu.dropdown-notifications');
            if (ul.children('.notification').length === 0) {
              noRecentText.show();
            }
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

  function initGlobalSwitchForm() {
    var teamSwitch = $('#team-switch');
    teamSwitch
      .find('.dropdown-menu a')
      .on('click', function(){
        $('#user_current_organization_id')
          .val($(this).attr('data-id'));

        teamSwitch
          .find('form')
          .submit();
      });
  }

  // init
  loadDropdownNotifications();
  loadUnseenNotificationsNumber();
  toggleNotificationBellPosition();
  initGlobalSwitchForm();
})();
