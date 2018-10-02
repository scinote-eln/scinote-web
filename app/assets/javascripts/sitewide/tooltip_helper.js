(function() {
  'use strict';

  $.initTooltips = function() {
    var popoversArray = [];
    var leaveTimeout;
    var enterTimeout;

    if ($(document.body).data('tooltips-enabled') === true || $(document.body).data('tooltips-enabled') == null) {
      $('.tooltip_open').remove(); // Destroy all (if any) old open popovers
      $('.help_tooltips').each(function(i, obj) {
        var popoverObject = obj;
        popoversArray.push(popoverObject);
      });
      $('.help_tooltips').each(function(i, obj) {
        var link = $(obj).data('tooltiplink');
        var textData = $(obj).data('tooltipcontent');
        var customStyle = $(obj).data('tooltipstyle');

        $(obj)
          .popover({
            html: true,
            container: 'body',
            placement: 'auto right',
            trigger: 'manual',
            content: 'popovers will not display if empty',
            template:
              '<div class="popover tooltip_' + i + '_window tooltip-open" '
              + 'role="tooltip" style="' + customStyle + '">'
              + '<div class="popover-body" >' + textData + '</div>'
              + '<br><br><br>'
              + '<div class="popover-footer">'
              + '<a class="btn btn-link text-nowrap" href="' + link + '" target="_blank" rel="noopener noreferrer" >'
              + 'Read more&nbsp;&nbsp;&nbsp;<i class="fas fa-external-link-alt"></i>'
              + '</a>'
              + '</div>'
              + '</div>'
          })
          .off('shown.bs.popover')
          .on('shown.bs.popover', function() {
            // hide all other popovers
            popoversArray.forEach(function(arrayItem) {
              if (obj !== arrayItem) {
                $(arrayItem).popover('hide');
              }
            });
          })
          .off('mouseleave')
          .on('mouseleave', function() {
            clearTimeout(enterTimeout);
            leaveTimeout = setTimeout(function() {
              if (!$('.tooltip_' + i + '_window:hover').length > 0) {
                $(obj).popover('hide');
              }
            }, 100);
          })
          .off('mouseenter')
          .on('mouseenter', function() {
            clearTimeout(leaveTimeout);
            enterTimeout = setTimeout(function() {
              var top;

              if ($(obj).hover().length > 0) {
                $(obj).popover('show');
                $('.tooltip_' + i + '_window').removeClass('tooltip-enter');
                top = $(obj).offset().top;
                $('.tooltip_' + i + '_window').css({
                  top: (top) + 'px'
                });
                $('.tooltip_' + i + '_window').off('mouseleave').on('mouseleave', function() {
                  $('.tooltip_' + i + '_window').removeClass('tooltip-enter');
                  $(obj).popover('hide');
                });
                $('.tooltip_' + i + '_window').off('mouseenter').on('mouseenter', function() {
                  $('.tooltip_' + i + '_window').addClass('tooltip-enter');
                });
              }
            }, 1000);
          });
      });
    }
  };

  $(document).on('turbolinks:load', function() {
    $.initTooltips();
  });
}());
