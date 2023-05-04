(function() {
  const handsontableInitDataElem = $('#handson');
  const HANDSONTABLE_INIT_ROWS_CNT = handsontableInitDataElem.data('init-rows-cnt');
  const HANDSONTABLE_INIT_COLS_CNT = handsontableInitDataElem.data('init-cols-cnt');

  $("[data-role='hot-table']").each(function() {
    var hot;
    var $container = $(this).find("[data-role='step-hot-table']");
    var contents = $(this).find('.hot-contents');
    var metadata = $(this).find('.hot-metadata');

    $container.handsontable({
      startRows: HANDSONTABLE_INIT_ROWS_CNT,
      startCols: HANDSONTABLE_INIT_COLS_CNT,
      rowHeaders: true,
      colHeaders: true,
      fillHandle: false,
      formulas: true,
      data: JSON.parse(contents.attr('value')).data,
      cell: JSON.parse(metadata.val() || '{}').cells || [],
      readOnly: true
    });

    hot = $container.handsontable('getInstance');

    setTimeout(() => {
      hot.render();
    }, 500);
  });

  window.print();
}());
