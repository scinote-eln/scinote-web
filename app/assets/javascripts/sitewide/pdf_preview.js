/* global pdfjsLib animateSpinner dropdownSelector pdfjsLibUtils PerfectScrollbar */
/* eslint-disable no-param-reassign, no-use-before-define */

var PdfPreview = (function() {
  const MIN_ZOOM = 0.25;
  const MAX_ZOOM = 3;
  const DEFAULT_ZOOM = 1;
  const ZOOM_STEP = 0.25;
  const MAX_LOAD_ATTEMPTS = 5;

  var pageRendering = false;

  function initActionButtons() {
    $(document)
      // Next page
      .on('click', '.pdf-viewer .next-page', function() {
        var $canvas = $(this).closest('.pdf-viewer').find('.pdf-canvas');
        renderPdfPage($canvas[0], $canvas.data('current-page') + 1);
      })
      // Previous field
      .on('click', '.pdf-viewer .prev-page', function() {
        var $canvas = $(this).closest('.pdf-viewer').find('.pdf-canvas');
        renderPdfPage($canvas[0], $canvas.data('current-page') - 1);
      })
      // Page change field
      .on('change', '.pdf-viewer .current-page', function() {
        var page = parseInt($(this).val(), 10) || 1;
        var $canvas = $(this).closest('.pdf-viewer').find('.pdf-canvas');
        var totalPage = $canvas.data('total-page');
        if (page < 1) page = 1;
        if (page > totalPage) page = totalPage;
        renderPdfPage($canvas[0], page);
      })
      // Zoom out button
      .on('click', '.pdf-viewer .zoom-out', function() {
        var zoomSelector = $(this).closest('.pdf-viewer').find('.zoom-page-selector');
        var $canvas = $(this).closest('.pdf-viewer').find('.pdf-canvas');
        var zoomValue = dropdownSelector.getValues(zoomSelector);
        if (zoomValue === 'auto') {
          dropdownSelector.selectValues(zoomSelector, DEFAULT_ZOOM);
        } else {
          dropdownSelector.selectValues(zoomSelector, parseFloat(zoomValue) - ZOOM_STEP);
        }
        renderPdfPage($canvas[0], $canvas.data('current-page'));
      })
      // Zoom in button
      .on('click', '.pdf-viewer .zoom-in', function() {
        var zoomSelector = $(this).closest('.pdf-viewer').find('.zoom-page-selector');
        var $canvas = $(this).closest('.pdf-viewer').find('.pdf-canvas');
        var zoomValue = dropdownSelector.getValues(zoomSelector);
        if (zoomValue === 'auto') {
          dropdownSelector.selectValues(zoomSelector, DEFAULT_ZOOM);
        } else {
          dropdownSelector.selectValues(zoomSelector, parseFloat(zoomValue) + ZOOM_STEP);
        }
        renderPdfPage($canvas[0], $canvas.data('current-page'));
      })
      // Zoom dropdown
      .on('change', '.pdf-viewer .zoom-page-selector', function() {
        var $canvas = $(this).closest('.pdf-viewer').find('.pdf-canvas');
        renderPdfPage($canvas[0], $canvas.data('current-page'));
      })
      // Load big pdf
      .on('click', '.pdf-viewer .load-blocked-pdf', function() {
        var $viewer = $(this).closest('.pdf-viewer');
        $viewer.removeClass('blocked');
        $viewer.find('.pdf-canvas').addClass('ready');
        PdfPreview.initCanvas();
      });
  }

  function initZoomDropdown($canvas) {
    var zoomSelector = $canvas.closest('.pdf-viewer').find('.zoom-page-selector');
    dropdownSelector.init(zoomSelector, {
      noEmptyOption: true,
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple',
      disableSearch: true
    });
  }

  function refreshPageCounter(canvas) {
    var $canvas = $(canvas);
    var currentPage = $canvas.data('current-page');
    var totalPage = $canvas.data('total-page');
    var counterContainer = $canvas.closest('.pdf-viewer').find('.page-counter');
    counterContainer.find('.current-page').val(currentPage);
    counterContainer.find('.total-page').text(totalPage);
    $canvas.closest('.pdf-viewer').find('.prev-page')
      .attr('disabled', currentPage === 1);
    $canvas.closest('.pdf-viewer').find('.next-page')
      .attr('disabled', currentPage === totalPage);
  }

  function refreshZoomButtons(canvas) {
    var $viewer = $(canvas).closest('.pdf-viewer');
    var zoomSelector = $viewer.find('.zoom-page-selector');
    var zoomValue = parseFloat(dropdownSelector.getValues(zoomSelector));
    $viewer.find('.zoom-out').attr('disabled', zoomValue === MIN_ZOOM);
    $viewer.find('.zoom-in').attr('disabled', zoomValue === MAX_ZOOM);
  }

  function renderPdfPreview(canvas) {
    $(canvas).removeClass('ready');
    initZoomDropdown($(canvas));
    animateSpinner($(canvas).closest('.pdf-viewer'), true);
    $(canvas).data(
      'custom-scrollbar',
      new PerfectScrollbar($(canvas).closest('.page-container')[0])
    ).data('load-attempts', 0);
    pdfjsLib.GlobalWorkerOptions.workerSrc = canvas.dataset.pdfWorkerUrl;
    loadPdfDocument(canvas);
  }


  function loadPdfDocument(canvas, page = 1) {
    var loadingPdf = pdfjsLib.getDocument(canvas.dataset.pdfUrl);
    $(canvas).data('load-attempts', $(canvas).data('load-attempts') + 1);
    loadingPdf.promise
      .then(function(pdfDocument) {
        $(canvas).data('pdfDocument', pdfDocument);
        return renderPdfPage(canvas, page);
      })
      .catch(function(reason) {
        pageRendering = false;
        if (reason.status === 202) {
          setTimeout(function() {
            loadPdfDocument(canvas, page);
          }, 5000);
        }
      });
  }

  function renderPdfPage(canvas, page = 1) {
    var pdfDocument = $(canvas).data('pdfDocument');
    if (pageRendering) return false;
    pageRendering = true;
    pdfDocument.getPage(page).then(function(pdfPage) {
      var ctx;
      var renderTask;
      var userScale = dropdownSelector.getValues($(canvas).closest('.pdf-viewer').find('.zoom-page-selector'));
      var $layersContainer = $(canvas).closest('.pdf-viewer').find('.layers-container');
      var scale = userScale === 'auto' ? DEFAULT_ZOOM : userScale;
      var viewport = pdfPage.getViewport({ scale: scale });
      var previewContainer = $(canvas).closest('.page-container')[0];
      var $textLayer = $(canvas).closest('.pdf-viewer').find('.textLayer');
      if (previewContainer.clientHeight < viewport.height && userScale === 'auto') {
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

      // Text layer draw
      $layersContainer.css({
        height: viewport.height + 'px',
        width: viewport.width + 'px'
      });

      pdfPage.getTextContent().then(function(textContent) {
        var textLayer = new pdfjsLibUtils.TextLayerBuilder({
          textLayerDiv: $textLayer[0],
          pageIndex: page - 1,
          viewport: viewport
        });
        textLayer.eventBus = new pdfjsLibUtils.EventBus();
        textLayer.setTextContent(textContent);
        textLayer.render();
      });

      $(canvas)
        .data('current-page', page)
        .data('total-page', pdfDocument.numPages);
      $(canvas).data('custom-scrollbar').update();
      animateSpinner($(canvas).closest('.pdf-viewer'), false);
      refreshPageCounter(canvas);
      refreshZoomButtons(canvas);
      pageRendering = false;
      return renderTask.promise;
    }).catch(function() {
      pageRendering = false;
      if ($(canvas).data('load-attempts') <= MAX_LOAD_ATTEMPTS) {
        setTimeout(function() {
          loadPdfDocument(canvas, page);
        }, 5000);
      }
    });

    return true;
  }

  return {
    initCanvas: function() {
      $.each($('.pdf-canvas.ready'), function(i, canvas) {
        renderPdfPreview(canvas);
      });
    },
    init: function() {
      initActionButtons();
    }
  };
}());

PdfPreview.init();
