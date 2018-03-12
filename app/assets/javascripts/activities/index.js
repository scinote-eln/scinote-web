'use strict';

(function() {
  function initActivitiesButton() {
    $(document).ready(function() {
      // Activity feed modal in main navigation menu
      $(document).find('.btn-more-activities')
        .on('ajax:success', function(e, data) {
          debugger;
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
