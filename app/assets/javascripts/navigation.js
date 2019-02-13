/* globals animateSpinner */

(function() {
  'use strict';

  /* Init about modal */
  $("[data-trigger='about-modal']").on('click', function(ev) {
    ev.preventDefault();
    $('[data-role=about-modal]').modal('show');
  });

  /* Loading overlay for search */
  $('#search-bar').submit(function() {
    if ($('#update-canvas')) {
      $(document.body).spin(true);
      setTimeout(function() {
        $('.spinner').remove();
      }, 1000);
    } else {
      animateSpinner();
    }
  });

  function loadDropdownNotifications() {
    var button = $('#notifications-dropdown');
    var noRecentText = $('.dropdown-notifications .notifications-no-recent');
    button
      .on('click', function() {
        noRecentText.hide();
        $.ajax({
          url: button.attr('data-href'),
          type: 'GET',
          dataType: 'json',
          beforeSend: animateSpinner($('.notifications-dropdown-header'), true),
          success: function(data) {
            var ul = $('.dropdown-menu.dropdown-notifications');

            $('.notifications-dropdown-header')
              .nextAll('li.notification')
              .remove();
            $('.notifications-dropdown-header')
              .after(data.html);
            animateSpinner($('.notifications-dropdown-header'), false);
            if (ul.children('.notification').length === 0) {
              noRecentText.show();
            }
          }
        });
        $('#count-notifications').hide();
        toggleNotificationBellPosition();
      });
  }

  function loadUnseenNotificationsNumber(element='notifications',icon='.fa-bell') {
    var notificationCount = $('#count-' + element);
    $.ajax({
      url: notificationCount.attr('data-href'),
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        notificationCount.html('');
        if (data.notificationNmber > 0) {
          notificationCount.html(data.notificationNmber);
          notificationCount.show();
          toggleNotificationBellPosition(element,icon);
        } else {
          notificationCount.hide();
        }
      }
    });
  }

  function toggleNotificationBellPosition(element='notifications',icon='.fa-bell') {
    var notificationCount = $('#count-' + element);
    var button = $('#' + element + '-dropdown');

    if (notificationCount.is(':hidden')) {
      button
        .find(icon)
        .css('position', 'relative');
    } else {
      button
        .find(icon)
        .css('position', 'absolute');
    }
  }

  function initGlobalSwitchForm() {
    var teamSwitch = $('#team-switch');
    teamSwitch
      .find('.dropdown-menu .change-team')
      .on('click', function() {
        $('#user_current_team_id')
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

  // System notifications

  function loadDropdownSystemNotifications() {
    var button = $('#system-notifications-dropdown');
    var noRecentText = $('.dropdown-system-notifications .system-notifications-no-recent');
    button
      .on('click', function() {
        noRecentText.hide();
        $.ajax({
          url: button.attr('data-href'),
          type: 'GET',
          dataType: 'json',
          beforeSend: animateSpinner($('.system-notifications-dropdown-header'), true),
          success: function(data) {
            var ul = $('.dropdown-menu.dropdown-system-notifications');
            $('.system-notifications-dropdown-header')
              .nextAll('.system-notification')
              .remove();
            $('.system-notifications-dropdown-header')
              .after(data.html);
            animateSpinner($('.system-notifications-dropdown-header'), false);
            if (ul.children('.system-notification').length === 0) {
              noRecentText.show();
            }
            bindSystemNotificationAjax();
            SystemNotificationsMarkAsSeen('.dropdown-system-notifications');
          }
        });
        $('#count-system-notifications').hide();
        toggleNotificationBellPosition('system-notifications','.fa-gift');
      }); 
  }

  // init
  loadDropdownSystemNotifications()
  $('.dropdown-system-notifications').scroll(function() { 
    SystemNotificationsMarkAsSeen('.dropdown-system-notifications');
  });
  $('.dropdown').on('hide.bs.dropdown', function () {
    if ($('.modal.in').length > 0){
      return false;
    }
  });
  loadUnseenNotificationsNumber('system-notifications','.fa-gift')
})();
