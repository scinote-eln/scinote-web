$(document).on('focus', 'textarea', function() {
  var $this = $(this);
  var height = $this.css('height');

  // Set the nr. of rows to 1 if small textarea
  if ($this.hasClass('textarea-sm')) {
    $this.attr('rows', '1');
  }

  // Initialize autosize plugin if it's not initialized yet
  if (_.isUndefined($this.data('autosize'))) {
    $this.autosize({append: ''});

    // Restore previous height!
    $this.css('height', height);
  }

  $this.trigger('autosize.resize');
});
