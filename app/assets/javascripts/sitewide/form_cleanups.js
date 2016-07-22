$.fn.clear_form_errors = function() {
  $(this).find('.nav.nav-tabs li').removeClass('has-error');
  $(this).find('.form-group').removeClass('has-error');
  $(this).find('span.help-block').remove();
};

$.fn.clear_form_fields = function() {
  $(this).find("input")
    .not("button")
    .not('input[type="submit"], input[type="reset"], input[type="hidden"]')
    .not('input[type="radio"]') // Leave out radios as this messes up Bootstrap btn-groups
    .val('')
    .removeAttr('checked')
    .removeAttr('selected');
};

function removeBlankFileForms(form) {
  $(form).find("input[type='file']").each(function () {
    if (!this.files[0]) {
      $(this).closest("fieldset").remove();
    }
  });
}

// Not the actual Excel tables, but are similar
function removeBlankExcelTables(tables, editMode) {
  if(!editMode) {
		// In edit mode, tables can't be blank
	  tables.each(function () {
	    if (!$(this).find("td:not(:empty)").length) {
	      $(this).closest("fieldset").remove();
	    }
	  });
	}
}