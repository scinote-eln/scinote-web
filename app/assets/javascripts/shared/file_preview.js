/* global ActiveStoragePreviews */
(function() {
  $('.asset-image')
    .on('load', (event) => ActiveStoragePreviews.showPreview(event))
    .on('error', (event) => ActiveStoragePreviews.reCheckPreview(event));

  // Force load event for image on firefox browser.
  if (/firefox/i.test(navigator.userAgent)) {
    $('.asset-image').trigger('load');
  }
}());
