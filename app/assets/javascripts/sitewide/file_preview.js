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

        pdfPreviewCanvas = $('#filePreviewModal').find('.pdf-file-preview')[0];
        if (pdfPreviewCanvas) renderPdfPreview(pdfPreviewCanvas);
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

  function renderPdfPreview(canvas, page = 1, userScale = false) {
    var loadingPdf;
    pdfjsLib.GlobalWorkerOptions.workerSrc = canvas.dataset.pdfWorkerUrl
    loadingPdf = pdfjsLib.getDocument(canvas.dataset.pdfUrl);
    loadingPdf.promise
      .then(function (pdfDocument) {
        return pdfDocument.getPage(page).then(function (pdfPage) {
          var ctx;
          var renderTask;
          var scale = userScale || 1.0;
          var viewport = pdfPage.getViewport({ scale: scale });
          var previewContainer = $('#filePreviewModal .file-preview-container')[0]
          if (previewContainer.clientHeight < viewport.height && !userScale) {
            scale = previewContainer.clientHeight / viewport.height;
          }
          viewport = pdfPage.getViewport({ scale: scale });
          canvas.width = viewport.width;
          canvas.height = viewport.height;
          ctx = canvas.getContext("2d");
          renderTask = pdfPage.render({
            canvasContext: ctx,
            viewport: viewport,
          });
          return renderTask.promise;
        });
      })
      .catch(function (reason) {
        console.error("Error: " + reason);
      });
  }

  return Object.freeze({
    init: initPreviewModal
  });
}());

FilePreviewModal.init();
