'use strict';

// update selected notiifcations
function SystemNotificationsMarkAsSeen() {
  if ($('.system-notification[data-new="1"]').length > 0) {
    $.post('/system_notifications/mark_as_seen');
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
      var SystemNotification = $('.system-notification[data-system-notification-id=' + data.id + ']');
      SystemNotificationModalBody.html(data.modal_body);
      SystemNotificationModalTitle.text(data.modal_title);
      $('.dropdown.system-notifications').removeClass('open');
      // Open modal
      SystemNotificationModal.modal('show');
      if (SystemNotification[0].dataset.unread === '1') {
        $.each(SystemNotification, (index, e) => { e.dataset.unread = '0'; });
        SystemNotification.find('.status-icon').addClass('seen');
        $.post('/system_notifications/' + data.id + '/mark_as_read');
      }
    });
}

function initSystemNotificationsButton() {
  $('.btn-more-system-notifications')
    .on('ajax:success', function(e, data) {
      $(data.html).insertAfter($('.system-notifications-container .system-notification').last());
      bindSystemNotificationAjax();
      if (data.more_url) {
        $(this).attr('href', data.more_url);
      } else {
        $(this).remove();
      }
    });
}

initSystemNotificationsButton();
SystemNotificationsMarkAsSeen();
bindSystemNotificationAjax();
