'use strict';

(function() {
  function initActivitiesButton() {
    $(document).ready(function() {
      $(document).find('.btn-more-activities')
        .on('ajax:success', function(e, data) {
          $(data.html).insertAfter($('#list-activities li').last());
          if(data.more_url) {
            $(this).attr('href', data.more_url);
          } else {
              $(this).remove();
          }
        });
    });
  }
  initActivitiesButton();

})();
