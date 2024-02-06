/* global ActiveStoragePreviews */

(function() {
  $('.asset-image')
    .on('load', (event) => ActiveStoragePreviews.showPreview(event))
    .on('error', (event) => ActiveStoragePreviews.reCheckPreview(event));
}());
