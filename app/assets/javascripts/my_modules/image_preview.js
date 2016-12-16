$(document).ready(function() {
  var modal = $('#imagePreviewModal');

  function initPreviewModal() {
    $('.image-preview-link').click(function(e) {
      e.preventDefault();
      var name = $(this).find('p').text();
      var url = $(this).find('img').data('large-url');
      var downloadUrl = $(this).attr('href');
      var description = $(this).data('description');
      openPreviewModal(name, url, downloadUrl, description);
    });
  }

  function openPreviewModal(name, url, downloadUrl, description) {
    modal.find('.image-name').text(name);
    var link = modal.find('.image-download-link');
    link.attr('href', downloadUrl);
    var image = modal.find('.modal-body img');
    image.attr('src', url);
    image.attr('alt', name);
    modal.find('.modal-footer .image-description').text(description);
    modal.modal();
  }

  initPreviewModal();
});
