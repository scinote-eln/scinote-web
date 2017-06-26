(function(global) {
  'use strict';

  global.repositoryRecordsImporter = function() {
    var previousIndex, disabledOptions, loadingRecords;
    loadingRecords = false;
    $('select').focus(function() {
      previousIndex = $(this)[0].selectedIndex;
    }).change(function() {
      var currSelect = $(this);
      var currIndex = $(currSelect)[0].selectedIndex;

      $('select').each(function() {
        var el = $(this);
        if (currSelect !== el && currIndex > 0) {
          el.children().eq(currIndex).attr('disabled', 'disabled');
        }

        el.children().eq(previousIndex).removeAttr('disabled');
      });

      previousIndex = currIndex;
    });

    //  Create import repository records ajax
    $('form#form-import').submit(function(e) {
      // Check if we already uploading repository records
      if (loadingRecords) {
        return false;
      }
      disabledOptions = $("option[disabled='disabled']");
      disabledOptions.removeAttr('disabled');
      loadingRecords = true;
      animateSpinner();
    }).on('ajax:success', function(ev, data, status) {
      // Simply reload page to show flash and updated repository records list
      loadingRecords = false;
      location.reload();
    }).on('ajax:error', function(ev, data, status) {
      loadingRecords = false;
      if (_.isUndefined(data.responseJSON.html)) {
        // Simply reload page to show flash
        location.reload();
      } else {
        // Re-disable options
        disabledOptions.attr('disabled', 'disabled');

        // Populate the errors container
        $('#import-errors-container').html(data.responseJSON.html);
        animateSpinner(null, false);
      }
    });
  }
})(window);
