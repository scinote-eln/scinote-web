(function() {
  const formErrors = $('#resource-error-data').data('form-errors');
  $('form').renderFormErrors('user', formErrors, false);
}());
