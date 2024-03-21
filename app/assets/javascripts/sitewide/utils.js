/*
 * Converts JSON data received from the server to flat array of values.
 */
function jsonToValuesArray(jsonData) {
  var errMsgs = [];
  for (var key in jsonData) {
  	var values = jsonData[key];
    $.each(values, function (idx, val) {
      errMsgs.push(val);
	});
  }
  return errMsgs;
}

/*
 * Calls callback function on AJAX success (because built-in functions don't
 * work!)
 */
$.fn.onAjaxComplete = function (cb) {
  $(this)
  .on('ajax:success', function () {
	cb();
  })
  .on('ajax:error', function () {
	cb();
  });
}

/**
 * Checkbox on/off logic. For each checkbox hierarchy add 'checkbox-tree' class
 * to a parent 'div' surrounding the checkbox hierarchy, represented with 'ul',
 * and apply this function to some ancestor tag.
 * @param  {object} dependencies Hash of checkbox IDs (as keys), on whose
 * children and itself the corresponding checkbox object (as value) and its'
 * children depend on, BUT are in a seperate 'tree branch'
 * @param {boolean} checkAll Whether to check all the checkboxes by default,
 * otherwise leave them as is (the parameter can be left out)
 */
$.fn.checkboxTreeLogic = function(dependencies, checkAll) {
  var $checkboxTree = $(this).find('.checkbox-tree').addBack('.checkbox-tree');
  var $checkboxTreeCheckboxes = $checkboxTree.find('input:checkbox');

  if (checkAll) {
    $checkboxTreeCheckboxes.prop('checked', true);
  }

  $checkboxTreeCheckboxes.change(function() {
    // Update descendent checkboxes
    var $checkbox = $(this);
    var checkboxChecked = $checkbox.prop('checked');
    var $childCheckboxes = $checkbox.closest('li').find('ul input:checkbox');
    $childCheckboxes.each(function() {
      $(this).prop('checked', checkboxChecked);
    });

    // Update ancestor checkboxes
    // Loop until topmost checkbox is reached or until there's no parent
    // checkbox
    while ($checkbox.length) {
      var $checkboxesContainer = $checkbox.closest('ul');
      var $parentCheckbox = $checkboxesContainer.siblings()
                                                .find('input:checkbox');
      var $checkboxes = $checkboxesContainer.find('input:checkbox');
      var $checkedCheckboxes = $checkboxes.filter(':checked');

      $parentCheckbox.prop('checked',
       $checkboxes.length === $checkedCheckboxes.length);
      $checkbox = $parentCheckbox;
    }

    // Disable/enable dependent checkboxes
    $.each(dependencies, function(responsibleParentID, $dependentParent) {
      var $responsibleParent = $checkboxTree.find('#' + responsibleParentID);
      if ($responsibleParent.length) {
        var enable = $responsibleParent.closest('li')
                                       .find('input:checkbox:checked').length
        $dependentParent.closest('li').find('input:checkbox')
                        .prop('disabled', !enable);
      }
    });
  }).trigger('change');
};

/**
 * Show modal on link click and handle its' submition and validation.
 *
 * On link click it gets HTTP reponse with modal partial, shows it, and then on
 * submit gets JSON response, displays errors if any or either refreshes the
 * page or redirects it (if 'url' parameter is specified in JSON response).
 * @param  {string} modalID Modal ID
 * @param  {string} modelName Modal Name
 * @param  {object} $fn     Link objects for opening the modal (can have more
 *         links for same modal)
 */
$.fn.initSubmitModal = function(modalID, modelName) {
  /**
   * Popup modal validator
   * @param  {object} $modal Modal object
   */
  function modalResponse($modal) {
    var $modalForm = $modal.find('form');
    $modalForm
      .on('ajax:success', function(ev, data) {
        if (_.isUndefined(data)) {
          location.reload();
        } else {
          $(location).attr('href', data.url);
        }
      })
      .on('ajax:error', function(e, data) {
        $(this).renderFormErrors(modelName, data.responseJSON);
      })
      .animateSpinner(true);
  }

  var $linksToModal = $(this);
  $linksToModal
    .on('ajax:success', function(e, data) {
      // Add and show modal
      $('body').append($.parseHTML(data.html));
      $(modalID).modal('show', {
        backdrop: true,
        keyboard: false
      });
      $(".modal-body").find("input[type='text']").focus();
      modalResponse($(modalID));

      // Remove modal when it gets closed
      $(modalID).on('hidden.bs.modal', function() {
        $(modalID).remove();
      });
    })
    .on('ajax:error', function() {
      // TODO
    })
    .animateSpinner();
};

/**
 * Wraps tables in HTML with a specified wrapper.
 * @param {string || Element} htmlStringOrDomEl - HTML containing tables to be wrapped.
 * @returns {string} - HTML with tables wrapped.
 */
function wrapTables(htmlStringOrDomEl) {
  if (typeof htmlStringOrDomEl === 'string') {
    const container = $(`<span class="text-base">${htmlStringOrDomEl}</span>`);
    container.find('table').toArray().forEach((table) => {
      if ($(table).parent().hasClass('table-wrapper')) return;
      $(table).css('float', 'none').wrapAll(`
          <div class="table-wrapper" style="overflow: auto; width: 100%"></div>
        `);
    });
    return container.prop('outerHTML');
  }
  // Check if the value is a DOM element
  if (htmlStringOrDomEl instanceof Element) {
    const tableElement = $(htmlStringOrDomEl).find('table');
    if (tableElement.length > 0) {
      tableElement.wrap('<div class="table-wrapper" style="overflow: auto; width: 100%"></div>');
      const updatedHtml = $(htmlStringOrDomEl).html();
      $(htmlStringOrDomEl).replaceWith(updatedHtml);
    }
  }
}
