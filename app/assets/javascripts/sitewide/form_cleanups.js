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
    .removeAttr('checked')
    .removeAttr('selected');
};

$.fn.removeBlankFileForms = function () {
  $(this).find("input[type='file']").each(function () {
    if (!this.files[0]) {
      $(this).closest("fieldset").remove();
    }
  });
}

/*
 * Not the actual Excel tables, but are similar.
 */
$.fn.removeBlankExcelTables = function (editMode) {
  if(editMode) {
    $tables = $(this).find(".handsontable");
		// In edit mode, tables can't be blank
	  $tables.each(function () {
	    if (!$(this).find("td:not(:empty)").length) {
	      $(this).closest("fieldset").remove();
	    }
	  });
	}
}