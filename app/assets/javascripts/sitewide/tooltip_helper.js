(function() {
  'use strict';

  $.initTooltips = function() {
    if ($(document.body).data("tooltips-enabled") === true || $(document.body).data("tooltips-enabled") == null) {
      var popoversArray = [];
      $('.tooltip_open').remove(); // Destroy all (if any) old open popovers
      $('.help_tooltips').each(function(i, obj) {
        var popoverObject = obj;
        popoversArray.push(popoverObject);
      });
      $('.help_tooltips').each(function(i, obj) {
        var link = $(obj).data('tooltiplink');
        var textData = $(obj).data('tooltipcontent');

        $(obj).popover({
          html: true,
          container: 'body',
          placement: 'auto right',
          trigger: 'manual',
          content: 'popovers will not display if empty',
          template: '<div class="popover tooltip_' + i + '_window tooltip-open" role="tooltip" >' +
            '<div class="popover-body" >' + textData + '</div>' +
            '<br><br><br>' +
            '<div class="popover-footer">' +
            '<a class="btn btn-link text-nowrap" href="' + link + '" target="_blank" rel="noopener noreferrer" >' +
            'Read more&nbsp;&nbsp;&nbsp;<i class="fas fa-external-link-alt"></i>' +
            '</a>' +
            '</div>' +
            '</div>'
        }).off("shown.bs.popover").on("shown.bs.popover", function() {
          // hide all other popovers
          popoversArray.forEach(function(arrayItem) {
            if (obj !== arrayItem) {
              $(arrayItem).popover("hide");
            }
          });
        }).off("mouseleave").on("mouseleave", function() {
          setTimeout(function() {
            if (!$(".tooltip_" + i + "_window:hover").length) {
              $(obj).popover("hide");
            }
          }, 100);
        }).off("mouseenter").on("mouseenter", function() {
          setTimeout(function() {
            if ($(obj).hover().length > 0) {
              $(obj).popover("show");
              $(".tooltip_" + i + "_window").removeClass("tooltip-enter");
              var top = $(obj).offset().top;
              $('.tooltip_' + i + '_window').css({
                top: (top) + 'px'
              });
              $(".tooltip_" + i + "_window").off("mouseleave").on("mouseleave", function() {
                $(".tooltip_" + i + "_window").removeClass("tooltip-enter");
                $(obj).popover('hide');
              });
              $(".tooltip_" + i + "_window").off("mouseenter").on("mouseenter", function() {
                $(".tooltip_" + i + "_window").addClass("tooltip-enter");
              });
            }
          }, 1000);
        });
      })
    }
  }

  $(document).ready(function() {
    $.initTooltips();
  });

}());
