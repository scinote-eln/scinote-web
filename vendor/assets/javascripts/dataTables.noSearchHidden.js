/**
 * @summary     NoSearchHidden
 * @description Prevent searching of cells in hidden columns in DataTables
 * @version     1.0.0
 * @file        dataTables.noSearchHidden.js
 * @author      Brian White
 * @contact     github.com/mscdex/dataTables.noSearchHidden
 * @copyright   Copyright 2014 Brian White
 *
 * License      MIT - http://opensource.org/licenses/MIT
 *
 * This feature plug-in for DataTables will prevent searching of cells located
 * in hidden columns. This behavior is dynamic, so as column visibility
 * changes, so does the search cache.
 *
 * This feature can be enabled by:
 *
 * * Setting the `noSearchHidden` parameter in the DataTables initialization to
 *   be true
 * * Setting the `noSearchHidden` parameter to be true in the DataTables
 *   defaults (thus causing all tables to have this feature) - i.e.
 *   `$.fn.dataTable.defaults.noSearchHidden = true`.
 *
 */

(function(window, document, $) {
  // Listen for DataTables initializations
  $(document).on('init.dt.dth', function(e, settings, json) {
    //console.log("out");
    // prevents colision with the slick slider
    if( settings.hasOwnProperty('unslicked') )  {
      return;
    }

    if (
      settings.oInit.noSearchHidden                       || // option specified
      $.fn.dataTable.defaults.noSearchHidden                 // default set
    ) {
      //console.log("in");
      var table = new $.fn.dataTable.Api(settings),
          aoColumns = table.settings()[0].aoColumns;
      //console.log(table);
      table.on('column-visibility.dt.dth', function(e, settings, column, state) {
        var col = aoColumns[column];
        col.searchable = col.bSearchable = state;
        table.rows().invalidate();
      }).on('destroy', function() {
        // Remove event handler
        table.off('column-visibility.dt.dth');
      });
    }
  });
})(window, document, jQuery);
