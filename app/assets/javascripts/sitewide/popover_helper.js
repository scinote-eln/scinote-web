(function() {
  'use strict';

  $(document).ready(function() {
    $('.popover_v2').each(function(i,obj) {

      $(obj).popover({
        html: true,
        container: 'body',
        placement: 'auto right',
        trigger: 'manual',
        template: '<div class="popover popover_'+i+'_window" role="tooltip"><div class="popover-body">' +
        $(obj).data('content') +
        '</div><br><br><div class="popover-footer" style="position:absolute;bottom:5px;right:5px;background-color: 	#E8E8E8;border-radius: 3px;">' +
        '<a style="color:grey;" class="btn btn-link href="https://www.google.si">Read more &nbsp&nbsp<i class="fas fa-external-link-alt"></i></a></div></div>'
      }).on("mouseenter", function () {
          setTimeout(function () {
            if ($(obj).hover().length) {
              $(obj).popover("show")
              var top = $(obj).offset().top;
              $('body').find('.popover_'+i+'_window').css({
                  top: (top) + 'px'
              });
              $('body').find(".popover_"+i+"_window").on("mouseleave", function () {
                  $(obj).popover('hide');
              });
            }
          }, 1000);
      }).on("mouseleave", function () {
          setTimeout(function () {
              if (!$('body').find(".popover_"+i+"_window:hover").length) {
                  $(obj).popover("hide")
              }
          }, 500);
      });
    })
  });
}());
