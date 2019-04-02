/* global PerfectScrollbar */
var PerfectSb = (function() {
  (function() {
    $(document).on('turbolinks:load', function() {
      $.each($('.perfect-scrollbar'), function(index, object) {
        var ps = new PerfectScrollbar(object, { wheelSpeed: 0.5 });
        $(object).bind('update_scroll', () => {
          ps.update();
        });
      });
    });
  })();

  return Object.freeze({
    update_all: function() {
      $.each($('.perfect-scrollbar'), function(index, object) {
        $(object).trigger('update_scroll');
      });
    }
  });
});
PerfectSb();
