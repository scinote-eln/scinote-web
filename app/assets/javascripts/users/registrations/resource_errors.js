(function() {
  const formErrors = JSON.parse($('#resource-error-data').data('form-errors'));
  $('form').render_form_errors('user', formErrors, false);
}());
