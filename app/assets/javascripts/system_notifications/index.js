'use strict';

// update selected notiifcations
function SystemNotificationsMarkAsSeen(container = window) {
  var WindowSize = $(container).height();
  var NotificationsToUpdate = [];
  _.each($('.system-notification[data-new="1"]'), function(el) {
    var NotificationTopPosition = el.getBoundingClientRect().top;
    if (NotificationTopPosition > 0 && NotificationTopPosition < WindowSize) {
      NotificationsToUpdate.push(el.dataset.systemNotificationId);
      el.dataset.new = 0;
    }
  });
  if (NotificationsToUpdate.length > 0) {
    $.post('system_notifications/mark_as_seen', { notifications: JSON.stringify(NotificationsToUpdate) });
  }
}

function bindSystemNotificationAjax() {
  var SystemNotificationModal = null;
  var SystemNotificationModalBody = null;
  var SystemNotificationModalTitle = null;

  SystemNotificationModal = $('#manage-module-system-notification-modal');
  SystemNotificationModalBody = SystemNotificationModal.find('.modal-body');
  SystemNotificationModalTitle = SystemNotificationModal.find('#manage-module-system-notification-modal-label');

  $('.modal-system-notification')
    .on('ajax:success', function(ev, data) {
      var SystemNotification = $('.system-notification[data-system-notification-id=' + data.id + ']')[0];
      SystemNotificationModalBody.html(data.modal_body);
      SystemNotificationModalTitle.text(data.modal_title);
      $('.dropdown.system-notifications')[0].dataset.closable = false;
      // Open modal
      SystemNotificationModal.modal('show');
      if (SystemNotification.dataset.unread === '1') {
        $.post('system_notifications/' + data.id + '/mark_as_read');
      }
    });
}

function initSystemNotificationsButton() {
  $('.btn-more-notifications')
    .on('ajax:success', function(e, data) {
      $(data.html).insertAfter($('.notifications-container .system-notification').last());
      bindSystemNotificationAjax();
      if (data.more_url) {
        $(this).attr('href', data.more_url);
      } else {
        $(this).remove();
      }
    });
}

$(window).scroll(function() {
  SystemNotificationsMarkAsSeen();
});
initSystemNotificationsButton();
SystemNotificationsMarkAsSeen();
bindSystemNotificationAjax();
