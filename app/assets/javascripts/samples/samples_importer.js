var previousIndex;
var disabledOptions;
var loadingSamples = false;
$('select').focus(function() {
  previousIndex = $(this)[0].selectedIndex;
}).change(function() {
  var currSelect = $(this);
  var currIndex = $(currSelect)[0].selectedIndex;

  $('select').each(function() {
    if (currSelect !== $(this) && currIndex > 0) {
      $(this).children().eq(currIndex).attr('disabled', 'disabled');
    }

    $(this).children().eq(previousIndex).removeAttr('disabled');
  });

  previousIndex = currIndex;
});

//  Create import samples ajax
$('form#form-import')
.submit(function(e) {
  // Check if we already uploading samples
  if (loadingSamples) {
    return false;
  }
  disabledOptions = $("option[disabled='disabled']");
  disabledOptions.removeAttr('disabled');
  loadingSamples = true;
  animateSpinner();
})
.on('ajax:success', function(ev, data, status) {
  // Simply reload page to show flash and updated samples list
  loadingSamples = false;
  location.reload();
})
.on('ajax:error', function(ev, data, status) {
  loadingSamples = false;
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
