/* global tableColRowName*/

(function() {
  const handsontableInitDataElem = $('#handson');
  const HANDSONTABLE_INIT_ROWS_CNT = handsontableInitDataElem.data('init-rows-cnt');
  const HANDSONTABLE_INIT_COLS_CNT = handsontableInitDataElem.data('init-cols-cnt');

  $("[data-role='hot-table']").each(function() {
    var hot;
    var $container = $(this).find("[data-role='step-hot-table']");
    var contents = $(this).find('.hot-contents');
    var metadataJson = $(this).find('.hot-metadata');
    var metadata = JSON.parse(metadataJson.val() || '{}');

    $container.handsontable({
      startRows: HANDSONTABLE_INIT_ROWS_CNT,
      startCols: HANDSONTABLE_INIT_COLS_CNT,
      rowHeaders: tableColRowName.tableRowHeaders(metadata.plateTemplate),
      colHeaders: tableColRowName.tableColHeaders(metadata.plateTemplate),
      fillHandle: false,
      formulas: true,
      data: JSON.parse(contents.attr('value')).data,
      cell: metadata.cells || [],
      readOnly: true
    });

    hot = $container.handsontable('getInstance');

    setTimeout(() => {
      hot.render();
    }, 500);
  });

  window.print();
}());
