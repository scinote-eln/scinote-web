function initHandsOnTables(root) {
  root.find("div.hot-table").each(function()  {
    var $container = $(this).find(".step-result-hot-table");
    var contents = $(this).find('.hot-contents');

    $container.handsontable({
      width: '100%',
      startRows: 5,
      startCols: 5,
      rowHeaders: true,
      colHeaders: true,
      fillHandle: false,
      formulas: true,
      cells: function (row, col, prop) {
        var cellProperties = {};

        if (col >= 0)
          cellProperties.readOnly = true;
        else
          cellProperties.readOnly = false;

        return cellProperties;
      }
    });
    var hot = $container.handsontable('getInstance');
    var data = JSON.parse(contents.attr("value"));
    hot.loadData(data.data);
  });
}

$(document).ready(function(){
  initHandsOnTables($(document));
});
