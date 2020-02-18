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
        obj.dataset.tooltipId = i;

        $(obj)
          .popover({
            html: true,
            container: 'body',
            placement: 'auto right',
            trigger: 'manual',
            content: 'popovers will not display if empty',
            template:
              '<div class="popover tooltip_' + i + '_window tooltip-open" '
              + 'role="tooltip" style="' + customStyle + '" data-popover-id="' + i + '">'
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
            // hide popup if object element hidden
            if (!$(obj).is(':visible') || $(obj).is(':disabled')) {
              $(obj).popover('hide');
            }
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

    $(document.body).on('click', function() {
      $('.help_tooltips').each(function(i, obj) {
        $(obj).popover('hide');
      });
      $('.popover.tooltip-open').each(function(i, obj) {
        if ($('*[data-tooltip-id="' + obj.dataset.popoverId + '"]').length === 0) {
          $(obj).remove();
        }
      });
    });
    $(document.body).on('mousemove', function(e) {
      var mouse = { x: e.clientX, y: e.clientY };
      $('.popover.tooltip-open').each(function(i, obj) {
        var tooltipObj = '*[data-tooltip-id="' + obj.dataset.popoverId + '"]';
        var objHeight;
        var objWidth;
        var objLeft;
        var objTop;
        var objCorners;
        if ($(tooltipObj).length === 0) return;
        objHeight = $(tooltipObj)[0].clientHeight;
        objWidth = $(tooltipObj)[0].clientWidth;
        objLeft = $(tooltipObj)[0].offsetLeft;
        objTop = $(tooltipObj)[0].offsetTop;
        objCorners = {
          tl: { x: objLeft, y: objTop },
          tr: { x: (objLeft + objWidth), y: objTop },
          bl: { x: objLeft, y: (objTop + objHeight) },
          br: { x: (objLeft + objWidth), y: (objTop + objHeight) }
        };
        if (
          !(mouse.x > objCorners.tl.x && mouse.x < objCorners.br.x)
          || !(mouse.y > objCorners.tl.y && mouse.y < objCorners.br.y)
        ) {
          $(tooltipObj).popover('hide');
        }
      });
    });
  };

  $(document).on('turbolinks:load', function() {
    $.initTooltips();
  });
}());
