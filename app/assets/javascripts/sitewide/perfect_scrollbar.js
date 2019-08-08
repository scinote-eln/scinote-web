/* global PerfectScrollbar */
var activePSB = [];


var PerfectSb = (function() {
  function init() {
    $.each($('.perfect-scrollbar'), function(index, object) {
      var ps;
      activePSB.lenght = 0;
      ps = new PerfectScrollbar(object, { wheelSpeed: 0.5, minScrollbarLength: 20 });
      activePSB.push(ps);
    });
  }

  return Object.freeze({
    update_all: function() {
      $.each(activePSB, function(index, object) {
        object.update();
      });
    },
    init: function() {
      init();
    }
  });
});


$(document).on('turbolinks:load', function() {
  PerfectSb().init();
});
