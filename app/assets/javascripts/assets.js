function setupAssetsLoading() {
  var DELAY = 2000;
  var REPETITIONS = 15;

  function refreshAssets() {
    var elements = $("[data-status='asset-loading']");

    if (!elements.length) {
      return false;
    }

    $.each(elements, function(_, el) {
      var $el = $(el);
      var spinner = $el.find(".asset-loading-spinner");
      var type = $el.data("type");

      // Perform an AJAX call to present URL
      // to check if file already exists
      $.ajax({
        url: $el.data("present-url"),
        type: "GET",
        dataType: "json",
        success: function (data) {
          $el.attr("data-status", "asset-loaded");
          $el.find(".asset-loading-spinner").spin(false);
          $el.html("");

          if (type === "image") {
            $el.html(
              "<a href='" + $el.data("download-url") + "'>" +
              "<img src='" + $el.data("preview-url") + "'><br>" +
              $el.data("filename") + "</a>"
            );
          } else {
            $el.html(
              "<a href='" + $el.data("download-url") + "'>" +
              $el.data("filename") + "</a>"
            );
          }
        },
        error: function (ev) {
          if (ev.status == 403) {
            // Image/file exists, but user doesn't have
            // rights to download it
            if (type === "image") {
              $el.html(
                "<img src='" + $el.data("preview-url") + "'><br>" +
                $el.data("filename")
              );
            } else {
              $el.html($el.data("filename"));
            }
          } else {
            // Do nothing, file is not yet present
          }
        }
      });
    });

    return true;
  }

  function finalizeAssets() {
    var elements = $("[data-status='asset-loading']");

    $.each(elements, function(_, el) {
      var $el = $(el);
      $el.attr("data-status", "asset-failed");
      $el.find(".asset-loading-spinner").spin(false);
      $el.html($el.data("filename"));
    });
  }

  var cntr = 0;
  var intervalId = window.setInterval(function() {
    cntr++;
    if (cntr >= REPETITIONS || !refreshAssets()) {
      finalizeAssets();
      window.clearInterval(intervalId);
    }
  }, DELAY);
}
