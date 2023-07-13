/* global tableColRowName*/

(function() {
  'use strict';

  function initWelcomeModal() {
    $('#shareable-link-welcome-modal').modal('show');
  }

  function initStepsExpandCollapse() {
    $('.steps-collapse').on('click', function() {
      $('.step-container .collapse').collapse('hide');
    });

    $('.steps-expand').on('click', function() {
      $('.step-container .collapse').collapse('show');
    });
  }

  function initStepComments() {
    $('.shareable-link-open-comments-sidebar').on('click', function(e) {
      e.preventDefault();
      $('.comments-sidebar.open').removeClass('open');
      $('.showing-comments').removeClass('showing-comments');

      $($(this).data('objectTarget')).addClass('open');
      $(`#stepContainer${$(this).data('objectId')}`).addClass('showing-comments');
    });
  }

  function initializeHandsonTable(el) {
    var input = el.siblings('input.hot-table-contents');
    var inputObj = JSON.parse(input.attr('value'));
    var metadataJson = el.siblings('input.hot-table-metadata');
    var data = inputObj.data;
    var metadata;

    metadata = JSON.parse(metadataJson.val() || '{}');
    el.handsontable({
      disableVisualSelection: true,
      rowHeaders: tableColRowName.tableRowHeaders(metadata.plateTemplate),
      colHeaders: tableColRowName.tableColHeaders(metadata.plateTemplate),
      editor: false,
      copyPaste: false,
      formulas: true,
      data: data,
      cell: metadata.cells || []
    });
  }

  function initMyModuleProtocolShow() {
    initWelcomeModal();
    initStepsExpandCollapse();
    initStepComments();

    $('.hot-table-container').each(function() {
      initializeHandsonTable($(this));
    });
  }

  initMyModuleProtocolShow();
}());
