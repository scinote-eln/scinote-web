/* global animateSpinner FilePreviewModal */

var Assets = (function() {
  var DELAY = 5000;
  var REPETITIONS_LIMIT = 30;

  function finalizeAsset(element) {
    var $el = $(element);

    $el.attr('data-status', 'asset-failed');
    if ($el.data('filename')) {
      $el.html($el.data('filename'));
    }
  }

  function refreshAsset(element) {
    var $el = $(element);

    if ($el.data('refreshCounter') > REPETITIONS_LIMIT) {
      finalizeAsset($el);
      return;
    }

    // Perform an AJAX call to present URL
    // to check if file already exists
    $.ajax({
      url: $el.data('present-url'),
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        if (data.processing === true) {
          setTimeout(function() {
            refreshAsset($el);
          }, DELAY);
        }

        if (data.processing === false) {
          $el.html(data.placeholder_html);
          $el.attr('data-status', 'asset-loaded');
          animateSpinner($el, false);
          FilePreviewModal.init();
        }
      },
      error: function() {
        animateSpinner(null, false);
      }
    });

    $el.data().refreshCounter += 1;
  }

  function setupAssetsLoading() {
    var elements = $("[data-status='asset-loading']");

    if (!elements.length) {
      return;
    }

    $.each(elements, function(_, el) {
      var $el = $(el);

      if ($el.data('refreshIsRunning') === true) return;

      $el.data('refreshCounter', 1);
      $el.data('refreshIsRunning', true);

      setTimeout(function() {
        refreshAsset($el);
      }, DELAY);
    });
  }

  return Object.freeze({
    setupAssetsLoading: setupAssetsLoading
  });
}());
