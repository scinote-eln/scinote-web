
var progressBar = (function() {

  function resizeProgressBars() {
    $.each($('.progress'), (i, progress_bar) => {
      $(progress_bar).find('.progress-bar-text').css('width', $(progress_bar).width() + 'px');
    })
  }


  return {
    init: () => {
      resizeProgressBars();
      $(window).on('resize', () => {
        resizeProgressBars();
      })
    }
  };
}());

$(document).on('turbolinks:load', function() {
  progressBar.init();
});