$(document).on(
  'focus',
  'textarea.smart-text-area:not([readonly]):not([disabled])',
  function() {
    var $this = $(this);
    var height = $this.height();

    if ($this.hasClass('textarea-sm-present')) {
      $this
        .removeClass('textarea-sm-present')
        .addClass('textarea-sm');
      $this.attr('rows', '1');
    } else if ($this.hasClass('textarea-sm')) {
      // Set the nr. of rows to 1 if small textarea
      $this.attr('rows', '1');
    } else {
      $this.removeAttr('rows');
    }

    // Initialize autosize plugin if it's not initialized yet
    if (_.isUndefined($this.data('autosize'))) {
      $this.autosize({ append: '' });

      // Restore previous height!
      $this.height(height);
    }

    $this.trigger('autosize.resize');
  }
);
