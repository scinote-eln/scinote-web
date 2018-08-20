(function() {
  'use strict';

  $(document).ready(function() {
    //if( user has popovers turned on from settings ){
      var popovers_array = [];

      $('.popover_v2').each(function(i,obj) {
        var popover_object = obj;
        popovers_array.push(popover_object);
      });
      $('.popover_v2').each(function(i,obj) {
        var link = $(obj).data('popoverlink')
        var text_data = $(obj).data('popovercontent')

        $(obj).popover({
          html: true,
          container: 'body',
          placement: 'auto right',
          trigger: 'manual',
          content: 'popovers will not display if empty',
          template: '<div class="popover popover_'+i+'_window" role="tooltip" style="background-color:#F0F0F0;font-family:Lato;font-size:14px;" color="#000000" >' +
          '<div class="popover-body" >' + text_data + '</div>' +
          '<br><br><br>' +
          '<div class="popover-footer" style="position:absolute;bottom:5px;right:5px;background-color:#E8E8E8;border-radius: 3px;">' +
          '<a style="color:grey;" class="btn btn-link text-nowrap" href="'+link+'" target="_blank" rel="noopener noreferrer" ">' +
          'Read more&nbsp;&nbsp;&nbsp;<i class="fas fa-external-link-alt"></i>' +
          '</a>' +
          '</div>' +
          '</div>'
        }).on("mouseenter", function () {
            setTimeout(function () {
              if ($(obj).hover().length) {
                $(obj).popover("show")
                var top = $(obj).offset().top;
                $('.popover_'+i+'_window').css({
                    top: (top) + 'px'
                });
                $(".popover_"+i+"_window").on("mouseleave", function () {
                  $(obj).popover('hide');
                  $(".popover_"+i+"_window").css("background-color","#F0F0F0");
                });
                $(".popover_"+i+"_window").on("mouseenter", function () {
                  $(".popover_"+i+"_window").css("background-color","#DADADA");
                });

              }
            }, 1000);
        }).on("mouseleave", function () {
            setTimeout(function () {
                if (!$(".popover_"+i+"_window:hover").length) {
                    $(obj).popover("hide")
                }
            }, 500);
        }).on("shown.bs.popover", function(){
          // hide all other popovers
          popovers_array.forEach(function (arrayItem) {
            if(obj !== arrayItem){
              $(arrayItem).popover("hide")
            }
          });
        });
      })
  //}
  });
}());

/* copy and paste shortcut
<button class="btn btn-default popover_v2" data-popoverlink="<%= I18n.t('popover_test.link.') %>" data-popovercontent="<%= I18n.t('popover_test.text.') %>">
*/
