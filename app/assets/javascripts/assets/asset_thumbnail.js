/* global ActiveStoragePreviews */

(function() {
  $('.asset-thumbnail-image')
    .on('load', (event) => ActiveStoragePreviews.showPreview(event))
    .on('error', (event) => ActiveStoragePreviews.reCheckPreview(event));
})();
