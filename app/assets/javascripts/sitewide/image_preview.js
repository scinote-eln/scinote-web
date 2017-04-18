function initPreviewModal() {
  $('.image-preview-link').off();
  $('.image-preview-link').click(function(e) {
    e.preventDefault();
    var name = $(this).find('p').text();
    var url = $(this).find('img').data('preview-url');
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
    success: function(data) {
      modal.find('.modal-body img').remove();
      modal.find('.image-name').text(name);
      var link = modal.find('.image-download-link');
      link.attr('href', downloadUrl);
      link.attr('data-no-turbolink', true);
      link.attr('data-status', 'asset-present');
      modal.find('.modal-body').append($('<img>')
                               .attr('src', data['large-preview-url'])
                               .attr('alt', name)
                               .click(function(ev) {
                                 ev.stopPropagation();
                               }));
      modal.find('.modal-footer .image-description').text(description);
      modal.find('.modal-body').click(function() {
        modal.modal('hide');
      });
      modal.modal();
      $('.modal-backdrop').last().css('z-index', modal.css('z-index') - 1);
    },
    error: function(ev) {
      // TODO
    }
  });
}
