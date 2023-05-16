(function() {
  const formErrors = JSON.parse($('#form-error-data').data('form-errors'));
  $('form').render_form_errors('team', formErrors, false);
}());
