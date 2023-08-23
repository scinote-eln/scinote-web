$.fn.clearFormErrors = function () {
  $(this).find('.nav.nav-tabs li').removeClass('has-error');
  $(this).find('.form-group').removeClass('has-error');
  $(this).find('span.help-block').remove();
};

$.fn.clearFormFields = function () {
  $(this).find("input")
    .not("button")
    .not('input[type="submit"], input[type="reset"], input[type="hidden"]')
    .not('input[type="radio"]') // Leave out radios as this messes up Bootstrap btn-groups
    .val('')
    .attr('checked', false)
    .attr('selected', false);
};

$.fn.removeBlankFileForms = function () {
  $(this).find("input[type='file']").each(function () {
    if (!this.files[0]) {
      $(this).closest("fieldset").remove();
    }
  });
}
