(function() {
  'use strict';

  $(document).ready(function() {
    $('.popover_v2').popover({
      html: true,
      container: 'body',
      placement: 'auto right',
      trigger: 'manual',
      template: '<div class="popover popover_v2_window" role="tooltip"><div class="popover-body">' +
      $('.popover_v2').data('content') +
      '</div><div class="popover-footer" style="position:absolute;bottom:5px;right:5px;">' +
      '<a class="ax_default link_button" href="https://www.google.si"><i class="fas fa-external-link-alt">nekaj</i></a></div></div>'
    }).on("mouseenter", function () {
        setTimeout(function () {
          $('.popover_v2').popover("show")
          var top = $('.popover_v2').offset().top;
          $('.popover_v2_window').css({
              top: (top) + 'px'
          });
          $(".popover_v2_window").on("mouseleave", function () {
              $('.popover_v2').popover('hide');
          });
        }, 1000);
    }).on("mouseleave", function () {
        setTimeout(function () {
            if (!$(".popover_v2_window:hover").length) {
                $('.popover_v2').popover("hide")
            }
        }, 500);
    });
  });
}());
