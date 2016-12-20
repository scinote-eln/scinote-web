function initPreviewModal() {
  $('.image-preview-link').off();
  $('.image-preview-link').click(function(e) {
    e.preventDefault();
    var name = $(this).find('p').text();
    var url = $(this).find('img').data('get-preview-url');
    var downloadUrl = $(this).attr('href');
    var description = $(this).data('description');
    openPreviewModal(name, url, downloadUrl, description);
  });
}

function openPreviewModal(name, url, downloadUrl, description) {
  var modal = $('#imagePreviewModal');
  $.ajax({
    url: url,
    type: 'GET',
    dataType: 'json',
    success: function (data) {
      modal.find('.image-name').text(name);
      var link = modal.find('.image-download-link');
      link.attr('href', downloadUrl);
      link.attr('data-no-turbolink', true);
      link.attr('data-status', 'asset-present');
      var image = modal.find('.modal-body img');
      image.attr('src', data['large-preview-url']);
      image.attr('alt', name);
      modal.find('.modal-footer .image-description').text(description);
      modal.modal();
    },
    error: function (ev) {
      // TODO
    }
  });

}
