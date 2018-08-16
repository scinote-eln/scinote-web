(function() {
  'use strict';

  $(document).ready(function() {
    var hover_timer
    var text_to_display = $('.popover_v2').data('content')
    $('.popover_v2').popover({
      html: true,
      container: 'body',
      placement: 'auto right',
      trigger: 'manual',
      template: '<div class="popover" role="tooltip"><div class="popover-body">'+text_to_display+'</div></div>',
    }).on("mouseenter", function () {
        hover_timer = setTimeout(function () {
          $('.popover_v2').popover("show")
        }, 1000);
        $('body').find(".popover").on("mouseleave", function () {
            $('.popover_v2').popover('hide');
        });
    }).on("mouseleave", function () {
        clearTimeout(hover_timer)
        setTimeout(function () {
            if (!$(".popover:hover").length) {
                $('.popover_v2').popover("hide")
            }
        }, 500);
    });
  });
}());
