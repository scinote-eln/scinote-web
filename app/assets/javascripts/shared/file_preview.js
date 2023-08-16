/* global ActiveStoragePreviews */

(function() {
  $('.asset-image, .asset-preview-image')
    .on('load', (event) => ActiveStoragePreviews.showPreview(event))
    .on('error', (event) => ActiveStoragePreviews.reCheckPreview(event));
}());
