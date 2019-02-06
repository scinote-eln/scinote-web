'use strict';

(function() {
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
  function initSystemNotificationsScrollCheck(){
    $(window).scroll(function() {
    	SystemNotificationsMarkAsSeen()
    })
  }
  initSystemNotificationsButton();
  initSystemNotificationsScrollCheck()
  SystemNotificationsMarkAsSeen()
}());

// update selected notiifcations
function SystemNotificationsMarkAsSeen(){
	var notifications=SystemNotificationsCheckVisible()
    	if (notifications.length > 0){
    		$.post('system_notifications/mark',{notifications: JSON.stringify(notifications)})
    	}
}

// prepare notificaitons to update
function SystemNotificationsCheckVisible(){
  var window_size= $(window).height()
  var defaul_notifications_size = 75
  var notifications_to_update=[]
  _.each($('.system-notification[data-new="1"]'), function(el) {
    if (el.getBoundingClientRect().top > 0 && el.getBoundingClientRect().top < (window_size - defaul_notifications_size)){
      notifications_to_update.push(el.id)
      el.dataset.new=0
    }
  })
  return notifications_to_update
}