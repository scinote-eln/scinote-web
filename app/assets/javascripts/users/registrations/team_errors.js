(function() {
  const formErrors = $('#team-error-data').data('form-errors');
  $('form').renderFormErrors('team', formErrors, false);
}());
