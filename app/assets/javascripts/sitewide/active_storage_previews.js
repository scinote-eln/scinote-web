/* eslint-disable no-unused-vars */

var ActiveStoragePreviews = (function() {
  const RETRY_COUNT = 50;
  const RETRY_DELAY = 5000;

  return Object.freeze({
    reCheckPreview: function(ev) {
      var img = ev.target;
      var src = ev.target.src;

      if (img.length === 0) return;

      if (!img.retryCount) {
        img.retryCount = 0;
      }

      if (img.retryCount >= RETRY_COUNT) return;

      if (!$(img).parent().hasClass('processing')) $(img).parent().addClass('processing');

      setTimeout(() => {
        img.src = src;
        img.retryCount += 1;
      }, RETRY_DELAY);
    },
    showPreview: function(ev) {
      $(ev.target).css('opacity', 1);
      $(ev.target).parent().removeClass('processing');
    }
  });
}());

$(document).on('turbolinks:load', function() {
  $('.asset-preview-image')
    .one('load', (event) => ActiveStoragePreviews.showPreview(event))
    .one('error', (event) => ActiveStoragePreviews.reCheckPreview(event))
    .each(function() { 
      if (this.complete) {
        $(this).load();
      } else if (this.error) {
        $(this).error();
      }
    });
});
