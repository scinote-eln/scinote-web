(function() {
  $('.api-key-input').on('keyup change', function() {
    var initialValue = this.dataset.originalValue;
    if (initialValue.length) {
      if (initialValue !== this.value) {
        $('.api-key-container').addClass('warning');
        $('.save-button').removeClass('hidden');
        $('.saved-button').addClass('hidden');
      } else {
        $('.api-key-container').removeClass('warning');
        $('.save-button').addClass('hidden');
        $('.saved-button').removeClass('hidden');
      }
    }
  });
}());
