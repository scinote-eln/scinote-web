$(document.body).ready(function () {
  $('.btn-more-notifications')
    .on("ajax:success", function (e, data) {
      if (data.html) {
        var list = $('.notifications-list');
        var moreBtn = $('.btn-more-notifications');
        // Remove button if all notifications are shown
        if (data.results_number < data.per_page) {
          moreBtn.remove();
        //  Otherwise update reference
        } else {
          moreBtn.attr('href', data.more_notifications_url);
        }
        $(list).append(data.html);
      }
    });
});
