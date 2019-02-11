'use strict';

(function() {
  $(window).scroll(function() {
    SystemNotificationsMarkAsSeen();
  });
  initSystemNotificationsButton();
  SystemNotificationsMarkAsSeen();
}());

// update selected notiifcations
function SystemNotificationsMarkAsSeen() {
  var WindowSize = $(window).height();
  var DefaultNotificaitonSize = 75;
  var NotificationsToUpdate = [];

  _.each($('.system-notification[data-new="1"]'), function(el) {
    var NotificationTopPosition = el.getBoundingClientRect().top;
    if (NotificationTopPosition > 0 && NotificationTopPosition < (WindowSize - DefaultNotificaitonSize)){
      NotificationsToUpdate.push(el.dataset.systemNotificationId);
      el.dataset.new = 0;
    }
  });
  if (NotificationsToUpdate.length > 0) {
    $.post('system_notifications/mark_as_seen', { notifications: JSON.stringify(NotificationsToUpdate) });
  }
}

function initSystemNotificationsButton() {
  $('.btn-more-notifications')
    .on('ajax:success', function(e, data) {
      $(data.html).insertAfter($('.notifications-container .system-notification').last());
      if (data.more_url) {
        $(this).attr('href', data.more_url);
      } else {
        $(this).remove();
      }
    });
}
