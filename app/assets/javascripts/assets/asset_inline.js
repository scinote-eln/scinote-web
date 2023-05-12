/* global ActiveStoragePreviews */

(function() {
  $('.asset-inline-image')
    .on('load', (event) => ActiveStoragePreviews.showPreview(event))
    .on('error', (event) => ActiveStoragePreviews.reCheckPreview(event));
})();
