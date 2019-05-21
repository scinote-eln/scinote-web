/* global animateSpinner FilePreviewModal */

var Assets = (function() {
  function refreshAssets() {
    var elements = $("[data-status='asset-loading']");

    if (!elements.length) {
      return false;
    }

    $.each(elements, function(_, el) {
      var $el = $(el);

      // Perform an AJAX call to present URL
      // to check if file already exists
      $.ajax({
        url: $el.data('present-url'),
        type: 'GET',
        dataType: 'json',
        success: function(data) {
          if (data.processing === true) {
            return;
          }

          if (data.processing === false) {
            $el.html(data.placeholder_html);
            $el.attr('data-status', 'asset-loaded');
            animateSpinner(null, false);
            FilePreviewModal.init();
          }
        },
        error: function() {
          animateSpinner(null, false);
        }
      });
    });

    return true;
  }

  function finalizeAssets() {
    var elements = $("[data-status='asset-loading']");

    $.each(elements, function(_, el) {
      var $el = $(el);
      $el.attr('data-status', 'asset-failed');
      if ($el.data('filename')) {
        $el.html($el.data('filename'));
      }
    });
  }

  function setupAssetsLoading() {
    var DELAY = 5000;
    var REPETITIONS = 60;
    var cntr = 0;
    var intervalId;

    if (window.assetsPollingIsRunning) return;

    intervalId = window.setInterval(function() {
      cntr += 1;
      if (cntr >= REPETITIONS || !refreshAssets()) {
        finalizeAssets();
        window.clearInterval(intervalId);
        window.assetsPollingIsRunning = false;
      }
    }, DELAY);

    window.assetsPollingIsRunning = true;
  }

  return Object.freeze({
    setupAssetsLoading: setupAssetsLoading
  });
}());
