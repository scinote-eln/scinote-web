/* eslint no-underscore-dangle: ["error", { "allowAfterThis": true }]*/
/* eslint no-use-before-define: ["error", { "functions": false }]*/
/* eslint-disable no-underscore-dangle */
var FilePreviewModal = (function() {
  'use strict';

  function initPreviewModal() {
    $(document).on('click', '.file-preview-link', function(e) {
      var params = {};
      var galleryViewId = $(this).data('gallery-view-id');
      e.preventDefault();
      e.stopPropagation();
      if ($(this).closest('.attachments').data('preview')) params.preview = true;
      params.gallery = $(`.file-preview-link[data-gallery-view-id=${galleryViewId}]`)
        .toArray().sort((a, b) => $(a).closest('.asset').css('order') - $(b).closest('.asset').css('order'))
        .map(i => i.dataset.id);
      $.get($(this).data('preview-url'), params, function(result) {
        var pdfPreviewCanvas;
        $('#filePreviewModal .modal-content').html(result.html);
        $('#filePreviewModal').modal('show');
        $('.modal-backdrop').last().css('z-index', $('#filePreviewModal').css('z-index') - 1);

        pdfPreviewCanvas = $('#filePreviewModal').find('.pdf-canvas:not(.ready)')[0];
        PdfPreview.initCanvas();
      });
    });

    $(document).on('click', '#filePreviewModal .gallery-switcher', function(e) {
      e.preventDefault();
      e.stopPropagation();
      $.get($(this).attr('href'), { gallery: $(this).data('gallery-elements') }, function(result) {
        $('#filePreviewModal .modal-content').html(result.html);
      });
    });
  }

  return Object.freeze({
    init: initPreviewModal
  });
}());

FilePreviewModal.init();
