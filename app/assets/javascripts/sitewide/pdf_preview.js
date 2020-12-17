/* global pdfjsLib animateSpinner */
/* eslint-disable no-param-reassign, no-use-before-define */

var PdfPreview = (function() {
  function initActionButtons() {
    $(document).on('click', '.pdf-viewer .next-page', function() {
      var $canvas = $(this).closest('.pdf-viewer').find('.pdf-canvas');
      renderPdfPage($canvas[0], $canvas.data('current-page') + 1);
    });

    $(document).on('click', '.pdf-viewer .prev-page', function() {
      var $canvas = $(this).closest('.pdf-viewer').find('.pdf-canvas');
      renderPdfPage($canvas[0], $canvas.data('current-page') - 1);
    });

    $(document).on('change', '.pdf-viewer .zoom-page-selector', function() {
      var $canvas = $(this).closest('.pdf-viewer').find('.pdf-canvas');
      renderPdfPage($canvas[0], $canvas.data('current-page'));
    });
  }

  function refreshPageCounter(canvas) {
    var $canvas = $(canvas);
    var counterContainer = $canvas.closest('.pdf-viewer').find('.page-counter');
    counterContainer.text(`Pages: ${$(canvas).data('current-page')} / ${$(canvas).data('total-page')}`);
  }

  function renderPdfPreview(canvas, page = 1) {
    var loadingPdf;
    $(canvas).addClass('ready');
    animateSpinner($(canvas).closest('.pdf-viewer'), true);
    pdfjsLib.GlobalWorkerOptions.workerSrc = canvas.dataset.pdfWorkerUrl;
    loadingPdf = pdfjsLib.getDocument(canvas.dataset.pdfUrl);
    loadingPdf.promise
      .then(function(pdfDocument) {
        $(canvas).data('pdfDocument', pdfDocument);
        return renderPdfPage(canvas, page);
      })
      .catch(function(reason) {
        if (reason.status === 202) {
          setTimeout(function() {
            animateSpinner($(canvas).closest('.pdf-viewer'), false);
            renderPdfPreview(canvas);
          }, 5000);
        }
        console.error('Error: ' + reason);
      });
  }

  function renderPdfPage(canvas, page = 1) {
    var pdfDocument = $(canvas).data('pdfDocument');
    pdfDocument.getPage(page).then(function(pdfPage) {
      var ctx;
      var renderTask;
      var userScale = $(canvas).closest('.pdf-viewer').find('.zoom-page-selector').val();
      var scale = userScale || 1.0;
      var viewport = pdfPage.getViewport({ scale: scale });
      var previewContainer = $(canvas).closest('.page-container')[0];
      if (previewContainer.clientHeight < viewport.height && !userScale) {
        scale = previewContainer.clientHeight / viewport.height;
      }
      viewport = pdfPage.getViewport({ scale: scale });
      canvas.width = viewport.width;
      canvas.height = viewport.height;
      ctx = canvas.getContext('2d');
      renderTask = pdfPage.render({
        canvasContext: ctx,
        viewport: viewport
      });
      $(canvas)
        .data('current-page', page)
        .data('total-page', pdfDocument.numPages);
      animateSpinner($(canvas).closest('.pdf-viewer'), false);
      refreshPageCounter(canvas);
      return renderTask.promise;
    });
  }

  return {
    initCanvas: function() {
      $.each($('.pdf-canvas:not(.ready)'), function(i, canvas) {
        renderPdfPreview(canvas);
      });
    },
    init: function() {
      initActionButtons();
    }
  };
}());

PdfPreview.init();
