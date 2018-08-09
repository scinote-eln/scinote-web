(function() {
  'use strict';

  $('.btn-more-notifications')
    .on('ajax:success', function(e, data) {
      var list = $('.notifications-list');
      var moreBtn = $('.btn-more-notifications');
      if (data.html) {
        // Remove button if all notifications are shown
        if (data.results_number < data.per_page) {
          moreBtn.remove();
        //  Otherwise update reference
        } else {
          moreBtn.attr('href', data.more_notifications_url);
        }
        $(list).append(data.html);
      } else if (data.results_number < 1) {
        moreBtn.remove();
      }
    });
}());
