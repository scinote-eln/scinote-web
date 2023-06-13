(function() {
  const formErrors = $('#form-error-data').data('form-errors');
  $('form').renderFormErrors('user', formErrors, false);
}());
