/*
 * Define AJAX methods for handling errors on forms.
 */

/*
* Render errors specified in array of strings format (or string if
* just one error) for a single form element.
*
* Show error message/s and mark error input (if errMsgs is defined)
* and, if present, mark and show the tab where the error occured and
* focus/scroll to the error input, if it is the first one to be
* specified or if errMsgs is undefined.
*
* @param {string} errAttributes Span element (error) attributes
* @param {boolean} clearErr Set clearErr to true if this is the only
* error that can happen/show.
*/
var renderFormError = function(ev, input, errMsgs, clearErr, errAttributes) {
  // console.log(input)
  clearErr = _.isUndefined(clearErr) ? false : clearErr;
  errAttributes = _.isUndefined(errAttributes) ? '' : ' ' + errAttributes;
  var $form = $(input).closest('form');

  if (!_.isUndefined(errMsgs)) {
    if (clearErr) {
      $form.clearFormErrors();
    }

    // Add error message/s
    var errorText = ($.makeArray(errMsgs).map(function(m) {
      if( m instanceof Array ) {
        return m.join(', ').strToErrorFormat();
      } else {
        return m.strToErrorFormat();
      }

    })).join('<br />');

    // Mark error form group
    var $formGroup = $(input).closest('.form-group');
    $formGroup.each(function() {
      if (!$(this).hasClass('has-error')) {
        $(this).addClass('has-error');
      }
    });

    var $errSpan = "<span class='help-block'" +
      errAttributes + '>' + errorText + '.' + '</span>';
    $(input).after($errSpan);
    $(input).closest('.modal').modal('handleUpdate');
  }

  var $parent;
  var $tab = $(input).closest('.tab-pane');
  if ($tab.length) {
    // Mark error tab
    tabsPropagateErrorClass($form);
    $parent = $tab;
  } else {
    $parent = $form;
  }

  // Focus and scroll to the error if it is the first (most upper) one
  if ($parent.find('.form-group.has-error').length === 1 ||
      _.isUndefined(errMsgs)) {
    goToFormElement(input);
  }

  if (!_.isUndefined(ev)) {
    // Don't submit form
    ev.preventDefault();
    ev.stopPropagation();
    ev.stopImmediatePropagation();
  }
};

/*
 * Render errors specified in JSON format for many form elements.
 */
$.fn.renderFormErrors = function(modelName, errors, clear, ev) {
  clear = _.isUndefined(clear) ? true : clear;
  if (clear) {
    this.clearFormErrors();
  }
  var $form = $(this);
  $.each(errors, function(field, messages) {
    // Special exception for file uploads in steps and results
    if (field === 'assets.file') {
      field = 'assets_attributes';
    } else if (field === 'asset.file') {
      field = 'asset_attribute';
    }
    var types = 'input, file, select, textarea';
    var $input = $(_.filter($form.find(types), function(el) {
      var name = $(el).attr('name');
      if (name) {
        return name.match(new RegExp(modelName + '\\[' + field + '\\(?'));
      }
      return false;
    }));

    renderFormError(ev, $input, messages);
  });
};

/*
 * If any of form tabs (if exist) has errors, mark it and
 * and show the first erroneous tab.
 */
function tabsPropagateErrorClass($form) {
  var $contents = $form.find('div.tab-pane');
  _.each($contents, function(tab) {
    var $tab = $(tab);
    var $errorFields = $tab.find('.has-error');
    if ($errorFields.length) {
      var id = $tab.attr('id');
      var navLink = $form.find("a[href='#" + id + "'][data-toggle='tab']");
      if (navLink.parent().length) {
        navLink.parent().addClass('has-error');
      }
    }
  });
  $form.find('.nav-tabs .has-error:first > a', $form).tab('show');
}
