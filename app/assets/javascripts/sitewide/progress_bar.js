
var progressBar = (function() {
  function resizeProgressBars() {
    $.each($('.progress'), (i, progress) => {
      $(progress).find('.progress-bar-text').css('width', $(progress).width() + 'px');
    });
  }


  return {
    init: () => {
      resizeProgressBars();
      $(window).on('resize', () => {
        resizeProgressBars();
      });
    }
  };
}());

$(document).on('turbolinks:load', function() {
  progressBar.init();
});
