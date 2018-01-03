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
      .find('.dropdown-menu .change-team')
      .on('click', function(){
        $('#user_current_team_id')
          .val($(this).attr('data-id'));

        teamSwitch
          .find('form')
          .submit();
      });
  }

  function focusSearchInput() {
    var searchIco = $('#search-ico');
    searchIco
      .on('shown.bs.dropdown', function() {
        searchIco
          .find('input.form-control')
          .focus();
      });
  }

  function initActivitiesButton() {
    $(document.body).ready(function() {
      // Activity feed modal in main navigation menu
      var activityModal = $('#activity-modal');
      var activityModalBody = activityModal.find('.modal-body');
      var initMoreBtn = function() {
        activityModalBody.find('.btn-more-activities')
          .on('ajax:success', function(e, data) {
            $(data.html).insertBefore($(this).parents('li'));
            if(data.more_url) {
              $(this).attr('href', data.more_url);
            } else {
                $(this).remove();
            }
          });
      };

      notificationAlertClose();

      $('#main-menu .btn-activity')
        .on('ajax:before', function() {
          activityModal.modal('show');
        })
        .on('ajax:success', function(e, data) {
          activityModalBody.html(data.html);
          initMoreBtn();
        });

      activityModal.on('hidden.bs.modal', function() {
        activityModalBody.html('');
      });
    });

    $(document).ajaxComplete(function() {
      notificationAlertClose();
    });

    function notificationAlertClose() {
      $('#notifications .alert').on('closed.bs.alert', function() {
        $('#content-wrapper')
          .addClass('alert-hidden')
          .removeClass('alert-shown');
      });
    }
  }

  // init
  loadDropdownNotifications();
  loadUnseenNotificationsNumber();
  toggleNotificationBellPosition();
  focusSearchInput();
  initGlobalSwitchForm();
  initActivitiesButton();
})();
