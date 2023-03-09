(function() {
  /**
   * Initialize the hands on table on the given
   * element with the specified data.
   * @param el - The jQuery element/s selector.
   */
  function initializeHandsonTable(el) {
    var input = el.siblings('input.hot-table-contents');
    var inputObj = JSON.parse(input.attr('value'));
    var metadata = el.siblings('input.hot-table-metadata');
    var data = inputObj.data;
    var headers;
    var parentEl;
    var order;

    // Special handling if this is a repository table
    if (input.hasClass('hot-repository-items')) {
      headers = inputObj.headers;
      parentEl = el.closest('.report-module-repository-element');
      order = parentEl.attr('data-order') === 'asc';

      el.handsontable({
        disableVisualSelection: true,
        rowHeaders: false,
        colHeaders: headers,
        columnSorting: false,
        editor: false,
        copyPaste: false,
        formulas: true,
        data: data
      });

      el.handsontable('getInstance').getPlugin('columnSorting').sort(3, order);
    } else {
      el.handsontable({
        disableVisualSelection: true,
        rowHeaders: true,
        colHeaders: true,
        editor: false,
        copyPaste: false,
        formulas: true,
        data: data,
        cell: JSON.parse(metadata.val() || '{}').cells || []
      });
    }
  }

  /** Convert Handsone table to normal table **/
  function reportHandsonTableConverter() {
    $.each($('.hot-table-container'), function(index, value) {
      var table = $(value);
      var header = table.find('.ht_master thead');
      var body = table.find('.ht_master tbody');
      table.next().append(header).append(body);
      table.remove();
    });
  }

  $('.hot-table-container').each(function() {
    initializeHandsonTable($(this));
  });
  reportHandsonTableConverter();
}());
