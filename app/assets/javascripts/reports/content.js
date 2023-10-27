(function() {

  function tableColHeaders(isPlateTemplate) {
    if (isPlateTemplate) {
      return function(visualColumnIndex) {
        return visualColumnIndex + 1;
      };
    }

    return true;
  }

  function tableRowHeaders(isPlateTemplate) {
    if (isPlateTemplate) {
      return function(visualColumnIndex) {
        var ordA = 'A'.charCodeAt(0);
        var ordZ = 'Z'.charCodeAt(0);
        var len = (ordZ - ordA) + 1;
        var num = visualColumnIndex;

        var colName = '';
        while (num >= 0) {
          colName = String.fromCharCode((num % len) + ordA) + colName;
          num = Math.floor(num / len) - 1;
        }
        return colName;
      };
    }

    return true;
  }

  /**
   * Initialize the hands on table on the given
   * element with the specified data.
   * @param el - The jQuery element/s selector.
   */
  function initializeHandsonTable(el) {
    var input = el.siblings('input.hot-table-contents');
    var inputObj = JSON.parse(input.attr('value'));
    var metadataJson = el.siblings('input.hot-table-metadata');
    var data = inputObj.data;
    var headers;
    var parentEl;
    var order;
    var metadata;

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
      metadata = metadataJson.val() || {};
      el.handsontable({
        disableVisualSelection: true,
        rowHeaders: tableRowHeaders(JSON.parse(metadata).plateTemplate),
        colHeaders: tableColHeaders(JSON.parse(metadata).plateTemplate),
        editor: false,
        copyPaste: false,
        formulas: true,
        data: data,
        cell: metadata.cells || []
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
