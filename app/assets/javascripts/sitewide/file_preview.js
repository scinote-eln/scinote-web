(function(global) {
  'use strict';

  global.initPreviewModal = function initPreviewModal() {
    var name;
    var url;
    var downloadUrl;
    $('.file-preview-link').off();
    $('.file-preview-link').click(function(e) {
      e.preventDefault();
      name = $(this).find('p').text();
      url = $(this).data('preview-url');
      downloadUrl = $(this).attr('href');
      openPreviewModal(name, url, downloadUrl);
    });
  }

  function openPreviewModal(name, url, downloadUrl) {
    var modal = $('#filePreviewModal');
    $.ajax({
      url: url,
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        modal.find('.file-preview-container').empty();
        modal.find('.file-wopi-controls').empty();
        if (data.hasOwnProperty('wopi-controls')) {
          modal.find('.file-wopi-controls').html(data['wopi-controls']);
        }
        var link = modal.find('.file-download-link');
        link.attr('href', downloadUrl);
        link.attr('data-no-turbolink', true);
        link.attr('data-status', 'asset-present');
        if (data['type'] === 'image') {
          modal.find('.file-preview-container')
               .append($('<img>')
                 .attr('src', data['large-preview-url'])
                 .attr('alt', name)
                 .click(function(ev) {
                   ev.stopPropagation();
                 })
               );
        } else {
          modal.find('.file-preview-container').html(data['preview-icon']);
        }
        modal.find('.file-name').text(name);
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
})(window);
