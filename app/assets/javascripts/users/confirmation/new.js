(function() {
  const formErrors = JSON.parse($('#form-error-data').data('form-errors'));
  $('.confimation-form').render_form_errors('user', formErrors, false);
}());
