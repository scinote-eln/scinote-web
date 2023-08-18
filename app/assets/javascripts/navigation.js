/* globals animateSpinner PerfectScrollbar */

(function() {
  'use strict';

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

  function loadUnseenNotificationsNumber(element = 'notifications', icon = '.fa-bell') {
    var notificationCount = $('#count-' + element);
    if (!notificationCount.length) return;

    $.ajax({
      url: notificationCount.attr('data-href'),
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        notificationCount.html('');
        if (data.notificationNmber > 0) {
          notificationCount.text(data.notificationNmber);
          notificationCount.show();
          toggleNotificationBellPosition(element, icon);
        } else {
          notificationCount.hide();
        }
      }
    });
  }

  function toggleNotificationBellPosition(element = 'notifications', icon = '.fa-bell') {
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
    var dropDownMenu = teamSwitch.find('.dropdown-menu');
    var dropDownHeight;
    var teamContainter = teamSwitch.find('.team-container')[0];
    var ps;

    if (typeof teamContainter === 'undefined') return;

    ps = new PerfectScrollbar(teamContainter, { scrollYMarginOffset: 5 });
    teamSwitch.click(() => {
      if (teamSwitch.find('.new-team').length === 0) {
        teamSwitch.find('.edit_user').css('height', '100%');
      }
      setTimeout(() => {
        ps.update();
      }, 0);
    });
    teamSwitch.find('.ps__rail-y').click((e) => {
      e.preventDefault();
      e.stopPropagation();
    });
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
    var noRecentText = $('.system-notifications-no-recent');
    button
      .on('click', function() {
        noRecentText.hide();
        $('.dropdown-system-notifications .system-notification').remove();
        $.ajax({
          url: button.attr('data-href'),
          type: 'GET',
          dataType: 'json',
          beforeSend: animateSpinner($('.system-notifications-dropdown-header'), true),
          success: function(data) {
            var ul = $('.dropdown-system-notifications');
            $('.system-notifications-dropdown-header')
              .nextAll('.system-notification')
              .remove();
            $('.system-notifications-dropdown-header')
              .after(data.html);
            animateSpinner($('.system-notifications-dropdown-header'), false);
            if (ul.find('.system-notification').length === 0) {
              noRecentText.show();
            }
            bindSystemNotificationAjax();
          }
        });
        $('#count-system-notifications').hide();
        toggleNotificationBellPosition('system-notifications', '.fa-gift');
      });
  }

  // init
  loadDropdownSystemNotifications();
  loadUnseenNotificationsNumber('system-notifications', '.fa-gift');
}());
