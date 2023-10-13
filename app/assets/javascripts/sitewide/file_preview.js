/* eslint no-underscore-dangle: ["error", { "allowAfterThis": true }]*/
/* eslint no-use-before-define: ["error", { "functions": false }]*/
/* eslint-disable no-underscore-dangle */
/* global PdfPreview */
var FilePreviewModal = (function() {
  'use strict';

  function initPreviewModal() {
    $(document).on('click', '.file-preview-link', function(e) {
      var params = {};
      var galleryViewId = $(this).data('gallery-view-id');
      e.preventDefault();
      e.stopPropagation();
      if ($(this).closest('.attachments').data('preview')) params.preview = true;
      params.gallery = Array.from(new Set(
        $(`.file-preview-link[data-gallery-view-id=${galleryViewId}]`)
          .toArray()
          .sort((a, b) => $(a).closest('.asset').css('order') - $(b).closest('.asset').css('order'))
          .map(i => i.dataset.id)
      ));
      $.get($(this).data('preview-url'), params, function(result) {
        $('#filePreviewModal .modal-content').html(result.html);
        $('#filePreviewModal').modal('show');
        $('.modal-backdrop').last().css('z-index', $('#filePreviewModal').css('z-index') - 1);
        PdfPreview.initCanvas();
      });
    });

    $(document).on('click', '#filePreviewModal .gallery-switcher', function(e) {
      e.preventDefault();
      e.stopPropagation();
      $.get($(this).attr('href'), { gallery: $(this).data('gallery-elements') }, function(result) {
        $('#filePreviewModal .modal-content').html(result.html);
        PdfPreview.initCanvas();
      });
    });
  }

  return Object.freeze({
    init: initPreviewModal
  });
}());

FilePreviewModal.init();
