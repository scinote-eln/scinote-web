var REPORT_CONTENT = '#report-content';
var ADD_CONTENTS_FORM_ID = '#add-contents-form';
var SAVE_REPORT_FORM_ID = '#save-report-form';

var addContentsModal = null;
var addContentsModalBody = null;
var saveReportModal = null;
var saveReportModalBody = null;

var ignoreUnsavedWorkAlert;

// Custom jQuery function that finds elements including
// the parent element
$.fn.findWithSelf = function(selector) {
  return this.filter(selector).add(this.find(selector));
};

/**
 * INITIALIZATION FUNCTIONS
 */

/**
 * Initialize the hands on table on the given
 * element with the specified data.
 * @param el - The jQuery element/s selector.
 */
function initializeHandsonTable(el) {
  var input = el.siblings("input.hot-table-contents");
  var inputObj = JSON.parse(input.attr("value"));
  var data = inputObj.data;

  // Special handling if this is a samples table
  if (input.hasClass("hot-samples")) {
    var headers = inputObj.headers;
    var parentEl = el.closest(".report-module-samples-element");
    var order = parentEl.attr("data-order") === "asc";

    el.handsontable({
      disableVisualSelection: true,
      rowHeaders: true,
      colHeaders: headers,
      columnSorting: true,
      editor: false,
      copyPaste: false,
      formulas: true
    });
    el.handsontable("getInstance").loadData(data);
    el.handsontable('getInstance').getPlugin('columnSorting').sort(3, order);

    // "Hack" to disable user sorting rows by clicking on
    // header elements
    el.handsontable("getInstance")
    .addHook("afterRender", function() {
      el.find(".colHeader.columnSorting")
      .removeClass("columnSorting");
    });
  } else {
    el.handsontable({
      disableVisualSelection: true,
      rowHeaders: true,
      colHeaders: true,
      editor: false,
      copyPaste: false,
      formulas: true
    });
    el.handsontable("getInstance").loadData(data);
  }
}

/**
* Initialize the controls for the specified report element.
* @param el - The element in the report.
*/
function initializeElementControls(el) {
  var controls = el.find(".report-element-header:first .controls");
  controls.find("[data-action='sort-asc']").click(function(e) {
    var el = $(this).closest(".report-element");
    if (el.hasClass("report-comments-element")) {
      sortCommentsElement(el, true);
    } else if (el.hasClass("report-module-activity-element")) {
      sortModuleActivityElement(el, true);
    } else if (el.is("[data-sort-hot]")) {
      sortModuleHotElement(el, true);
    } else {
      sortElementChildren(el, true, false);
    }
    e.preventDefault();
    e.stopPropagation();
    return false;
  });
  controls.find("[data-action='sort-desc']").click(function(e) {
    var el = $(this).closest(".report-element");
    if (el.hasClass("report-comments-element")) {
      sortCommentsElement(el, false);
    } else if (el.hasClass("report-module-activity-element")) {
      sortModuleActivityElement(el, false);
    } else if (el.is("[data-sort-hot]")) {
      sortModuleHotElement(el, false);
    } else {
      sortElementChildren(el, false, false);
    }
    e.preventDefault();
    e.stopPropagation();
    return false;
  });
  controls.find("[data-action='move-up']").click(function(e) {
    var el = $(this).closest(".report-element");
    moveElement(el, true);
    e.preventDefault();
    e.stopPropagation();
    return false;
  });
  controls.find("[data-action='move-down']").click(function(e) {
    var el = $(this).closest(".report-element");
    moveElement(el, false);
    e.preventDefault();
    e.stopPropagation();
    return false;
  });
  controls.find("[data-action='remove']").click(function(e) {
    var el = $(this).closest(".report-element");
    if (el.hasClass("report-result-comments-element")) {
      removeResultCommentsElement(el);
    } else {
      removeElement(el);
    }
    e.preventDefault();
    e.stopPropagation();
    return false;
  });
}

/**
 * Initialize all the neccesary report elements stuff for all
 * descendants of the provided parent DOM element.
 * @param parentElement - The parent DOM element.
 */
function initializeReportElements(parentElement) {
  // Initialize handsontable containers
  _.each(parentElement.findWithSelf(".hot-table-container"), function(el) {
    initializeHandsonTable($(el));
    reportHandsonTableConverter();
  });

  // Add event listeners element to controls
  _.each(parentElement.findWithSelf(".report-element"), function(el) {
    initializeElementControls($(el));
    updateElementControls($(el));
  });

  // Initialize new element click actions
  _.each(parentElement.findWithSelf(".new-element"), function(el) {
    initializeNewElement($(el));
  });
}

/**
 * Initialize the new element click action.
 * @param newEl - The "new element" element in the report.
 */
function initializeNewElement(newEl) {
  newEl.click(function(e) {
    var el = $(this);
    var dh = $("#data-holder");
    var parent = el.closest(".report-element");

    var parentElementId;
    var url;
    var modalTitle;

    if (!parent.length) {
      // No parent, this means adding is done on report level
      parentElementId = "null";
      url = dh.data("add-project-contents-url");
      modalTitle = dh.data("project-modal-title");
    } else {
      parentElementId = parent.data("id");
      modalTitle = parent.data("modal-title");

      // Select correct AJAX URL based on type
      switch (parent.data("type")) {
        case "experiment":
          url = dh.data("add-experiment-contents-url"); break;
        case 'my_module':
          url = dh.data("add-module-contents-url"); break;
        case "step":
          url = dh.data("add-step-contents-url"); break;
        case "result_asset":
        case "result_table":
        case "result_text":
          url = dh.data("add-result-contents-url"); break;
      }
    }

    // Send AJAX request to retrieve the modal contents
    $.ajax({
      url: url,
      type: "GET",
      dataType: "json",
      data: parentElementId,
      success: function(data, status, jqxhr) {
        // Open modal, set its title, and display module contents
        addContentsModal.find(".modal-title").text(modalTitle);
        addContentsModalBody.html(data.html);

        // Add logic for checkbox hierarchies
        var dependencies = { '_module_steps': $('#_step_all'),
                             '_module_results': $('#_result_comments')}
        addContentsModalBody.checkboxTreeLogic(dependencies, true);

        // Bind to the ajax events of the modal form in its body
        $(ADD_CONTENTS_FORM_ID)
        .on("ajax:beforeSend", function(){
          animateSpinner(this);
        })
        .on("ajax:success", function(e, xhr, opts, data) {
          if (data.status == 204) {
            // No content was added, simply hide modal
          } else if (data.status == 200) {
            // Add elements
            addElements(el, data.responseJSON.elements);
          }
        })
        .on("ajax:error", function(e, xhr, settings, error) {
          // TODO
        })
        .on("ajax:complete", function(){
          animateSpinner(this, false);
          addContentsModal.modal("hide");
        });

        // Execute any JS code the response might contain
        _.each(addContentsModalBody.find("script"), function (script) {
          eval(script.text);
        });

        // Finally, show the modal
        addContentsModal.modal("show");
      },
      error: function(jqxhr, status, error) {
        // TODO
      }
    });

    // Prevent page reload
    e.preventDefault();
    e.stopPropagation();
    return false;
  });
}

/**
 * Initialize the modal window for adding content.
 */
function initializeAddContentsModal() {
  addContentsModal = $("#add-contents-modal");
  addContentsModalBody = addContentsModal.find(".modal-body");

  // Remove "add contents" modal content when modal
  // window is closed
  addContentsModal.on("hidden.bs.modal", function () {
    addContentsModalBody.html("");
  });

  // Bind click action of "add" button in modal footer to
  // submit the form in the modal body
  addContentsModal.find(".modal-footer button[data-action='add']")
  .click(function(e) {
    $(ADD_CONTENTS_FORM_ID).submit();
  });
}

/**
 * Initialize the save report modal window etc.
 * for saving the report.
 */
function initializeSaveReport() {
  var dh = $("#data-holder");
  var saveReportLink = $("#save-report-link");

  saveReportModal = $("#save-report-modal");
  saveReportModalBody = saveReportModal.find(".modal-body");

  var modalContentsUrl = dh.data("save-report-url");

  var reportId = dh.data("report-id");

  // Remove "save report" modal content when modal
  // window is closed
  saveReportModal.on("hidden.bs.modal", function () {
    saveReportModalBody.html("");
  });

  saveReportLink.click(function(e) {
    // Send AJAX request to retrieve the modal contents
    $.ajax({
      url: modalContentsUrl,
      type: "POST",
      global: false,
      dataType: "json",
      data: {
        id: reportId,
        contents: JSON.stringify(constructReportContentsJson())
      },
      success: function(data, status, jqxhr) {
        // Display module contents
        saveReportModalBody.html(data.html);

        // Bind to the ajax events of the modal form in its body
        $(SAVE_REPORT_FORM_ID)
        .on("ajax:beforeSend", function() {
          animateSpinner(this);
        })
        .on("ajax:success", function(e, xhr, opts, data) {
          if (data.status == 200) {
            // Redirect back to index

            // Turn off all hooks related to alert window
            ignoreUnsavedWorkAlert = true;
            $(window).off('beforeunload');
            $(document).off('page:before-change');

            $(location).attr("href", xhr.url);
          }
        })
        .on("ajax:error", function(e, xhr, settings, error) {
          // Display errors
          if (xhr.status == 422) {
            $(this).renderFormErrors("report", xhr.responseJSON);
          } else {
            // TODO
          }
        })
        .on("ajax:complete", function () {
          animateSpinner(this, false);
        });

        // Finally, show the modal
        saveReportModal.modal("show");
      },
      error: function(jqxhr, status, error) {
        // TODO
      }
    });
  });

  // Bind click action of "save" button in modal footer to
  // submit the form in the modal body
  saveReportModal.find(".modal-footer button[data-action='save']")
  .click(function(e) {
    $(SAVE_REPORT_FORM_ID).submit();
  });
}

/**
 * Initialize global report sorting action.
 */
function initializeGlobalReportSort() {
  $("#sort-report .dropdown-menu a[data-sort]").click(function(ev) {
    var dh = $("#data-holder");
    var $this = $(this);
    var asc = true;

    if ($(ev.target).data("sort") == "desc") {
      asc = false;
    }

    if (confirm(dh.data("global-sort-text"))) {
      sortWholeReport(asc);
    }
  });
}

/**
 * Initialize the print popup functionality.
 */
function initializePrintPopup() {
  $("#print-report").click(function() {
    var html = $(REPORT_CONTENT).html();
    var dh = $("#data-holder");

    var print_window = window.open(
      "",
      "_blank",
      "width=" + screen.width +
      ",height=" + screen.height +
      ",fullscreen=yes" +
      ",scrollbars=yes"
    );

    print_window.document.open();
    print_window.document.write(
      "<html><head>" +
      "<link rel='stylesheet' href='" +
      dh.data("stylesheet-url") +
      "' />" +
      "<title>" +
      dh.data("print-title") +
      "</title>" +
      "</head>" +
      "<body class='print-report-body' onload='window.print();'>" +
      "<div class='print-report'>" +
      html +
      "</div>" +
      "</body>" +
      "</html>"
    );
    print_window.document.close();
  });
}

/**
 * Initialize the save to File functionality.
 */
function initializeSaveToFile(format) {
  var saveToFileBtn = $('#get-report-' + format);

  saveToFileBtn.click(function(e) {
    var content;
    var $form = $('<form target="_blank" action="' + saveToFileBtn[0].href + '" accept-charset="UTF-8" method="post"></form>');
    if (format === 'pdf') {
      content = $(REPORT_CONTENT).html();
    } else if (format === 'docx') {
      content = JSON.stringify(constructReportContentsJson());
    }
    $form.append('<input type="hidden" name="data" value="">');
    $form.find('input').attr('value', content);
    $form.appendTo('body').submit().remove();
    e.preventDefault();
    e.stopPropagation();
    return false;
  });
}


function initializeUnsavedWorkDialog() {
  var dh = $('#data-holder');
  var alertText = dh.attr('data-unsaved-work-text');

  ignoreUnsavedWorkAlert = false;

  /**
   * Before unload event logic
   */
  function beforeUnload() {
    var exit;
    if (ignoreUnsavedWorkAlert) {
      exit = true;
    } else {
      exit = confirm(alertText);
    }
    if (exit) {
      // We leave the page so remove all listeners
      $(document).off('turbolinks:before-visit');
    }
    return exit;
  }

  $(document).on('turbolinks:before-visit', beforeUnload);
}

/**
 * Initializes page
 */
function init() {
  initializeReportElements($(REPORT_CONTENT));
  initializeGlobalReportSort();
  initializePrintPopup();
  initializeSaveToFile('pdf');
  initializeSaveToFile('docx');
  initializeSaveReport();
  initializeAddContentsModal();
  initializeUnsavedWorkDialog();

  // Automatically display the "Add content" modal
  $('.new-element.initial').click();
}

/**
 * INDIVIDUAL ELEMENTS SORTING/MODIFYING FUNCTIONS
 */

 /**
  * Update the enabled/disabled state of element controls.
  * @param el - The element in the report.
  */
function updateElementControls(el) {
  var controls = el.find(".report-element-header:first .controls");

  var isFirst = !el.prevAll(".report-element:not(.report-project-header-element)").length;
  var isLast = !el.nextAll(".report-element").length;

  controls.find("[data-action='move-up']")
  .css("display", isFirst ? "none" : "");
  controls.find("[data-action='move-down']")
  .css("display", isLast ? "none" : "");
}

/**
 * Sort the whole report with all of its elements.
 * @param asc - True to sort in ascending order, false to sort
 * in descending order.
 */
function sortWholeReport(asc) {
  animateLoading();
  var reportContent = $(REPORT_CONTENT);
  var experimentElements = reportContent.children(".report-experiment-element");
  var newEls = reportContent.children(".new-element");

  if (
  experimentElements.length === 0 || // Nothing to sort
  experimentElements.length != newEls.length - 1 // This should never happen
  ) {
    return;
  }

  experimentElements = _.sortBy(experimentElements, function(el) {
    if (!asc)
    {
      return -$(el).data("ts");
    }
    return $(el).data("ts");
  });

  newEls.detach();
  experimentElements = $(experimentElements);
  experimentElements.detach();

  // Re-insert the children into DOM
  reportContent.append(newEls[0]);
  for (var i = 0; i < experimentElements.length; i++) {
    reportContent.append(experimentElements[i]);
    reportContent.append(newEls[i + 1]);
  }

  // Finally, fix their controls
  _.each(experimentElements, function(el) {
    updateElementControls($(el));
    sortElementChildren($(el), asc, true);
  });

  animateLoading(false);
}

/**
 * Sort the element's children.
 * @param el - The element in the report.
 * @param asc - True to sort in ascending order, false to sort
 * in descending order.
 * @param recursive - True to recursively sort the element's
 * children; false otherwise.
 */
function sortElementChildren(el, asc, recursive) {
  var childrenEl = el.find(".report-element-children:first");
  var newEls = childrenEl.children(".new-element");
  var children = childrenEl.children(".report-element");

  if (
  children.length === 0 || // No children, keep things
  children.length != newEls.length - 1 // This should never happen
  ) {
    return;
  }

  children = _.sortBy(children, function(child) {
    if (!asc)
    {
      return -$(child).data("ts");
    }
    return $(child).data("ts");
  });

  newEls.detach();
  children = $(children);
  children.detach();

  // Re-insert the children into DOM
  childrenEl.append(newEls[0]);
  for (var i = 0; i < children.length; i++) {
    childrenEl.append(children[i]);
    childrenEl.append(newEls[i + 1]);
  }

  // Finally, fix their controls
  _.each(children, function(child) {
    updateElementControls($(child));
    if (recursive) {
      sortElementChildren($(child), asc, true);
    }
  });
}

/**
 * Sort the comments element (special handling needs to be
 * done in this case).
 * @param el - The comments element in the report.
 * @param asc - True to sort in ascending order, false to sort
 * in descending order.
 */
function sortCommentsElement(el, asc) {
  var commentsList = el.find(".comments-list:first");
  var comments = commentsList.children(".comment");

  comments = _.sortBy(comments, function(comment) {
    if (!asc)
    {
      return -$(comment).data("ts");
    }
    return $(comment).data("ts");
  });

  comments = $(comments);
  comments.detach();
  _.each(comments, function(comment) {
    commentsList.append(comment);
  });

  // Update data attribute on sorting on the element
  el.attr("data-order", asc ? "asc" : "desc");
}

/**
 * Sort the module activity element (special handling needs
 * to be done in this case).
 * @param el - The module activity element in the report.
 * @param asc - True to sort in ascending order, false to sort
 * in descending order.
 */
function sortModuleActivityElement(el, asc) {
  var activityList = el.find(".activity-list:first");
  var activities = activityList.children(".activity");

  activities = _.sortBy(activities, function(activity) {
     if (!asc)
    {
      return -$(activity).data("ts");
    }
    return $(activity).data("ts");
  });

  activities = $(activities);
  activities.detach();
  _.each(activities, function(activity) {
    activityList.append(activity);
  });

  // Update data attribute on sorting on the element
  el.attr("data-order", asc ? "asc" : "desc");
}

/**
 * Sort the module HoT element (special handling needs
 * to be done in this case).
 * @param el - The module element in the report that contains handsontables.
 * @param asc - True to sort in ascending order, false to sort
 * in descending order.
 */
function sortModuleHotElement(el, asc) {
  var hotEl = el.find(".report-element-body .hot-table-container");
  var hotInstance = hotEl.handsontable("getInstance");
  var col = el.attr('data-sort-hot');

  hotInstance.sort(col, asc);

  // Update data attribute on sorting on the element
  el.attr("data-order", asc ? "asc" : "desc");
}

/**
 * Move the specified element up or down.
 * @param el - The element in the report.
 * @param up - True to move element up; false to move it down.
 */
function moveElement(el, up) {
  var prevNewEl = el.prev();
  var nextNewEl = el.next();
  if (
    !prevNewEl.length ||
    !prevNewEl.hasClass("new-element") ||
    !nextNewEl.length ||
    !nextNewEl.hasClass("new-element")) {
    return;
  }

  if (up) {
    var prevEl = prevNewEl.prev();
    if (!prevEl.length || !prevEl.hasClass("report-element")) {
      return;
    }

    el.detach();
    nextNewEl.detach();
    prevEl.before(el);
    prevEl.before(nextNewEl);
    updateElementControls(prevEl);

  } else {
    var nextEl = nextNewEl.next();
    if (!nextEl.length || !nextEl.hasClass("report-element")) {
      return;
    }

    prevNewEl.detach();
    el.detach();
    nextEl.after(el);
    nextEl.after(prevNewEl);
    updateElementControls(nextEl);
  }

  updateElementControls(el);
}

/**
 * Remove the specified element (and all its children)
 * from the report.
 * @param el - The element in the report.
 */
function removeElement(el) {
  var prevNewEl = el.prev();
  var nextNewEl = el.next();

  if (
    !prevNewEl.length ||
    !prevNewEl.hasClass("new-element") ||
    !nextNewEl.length ||
    !nextNewEl.hasClass("new-element")) {
    return;
  }

  // TODO Remove event listeners

  prevNewEl.remove();
  el.remove();

  // Fix controls of previous / next element
  var prevEl = prevNewEl.prev();
  var nextEl = nextNewEl.next();

  if (prevEl.length && prevEl.hasClass("report-element")) {
    updateElementControls(prevEl);
  }
  if (nextEl.length && nextEl.hasClass("report-element")) {
    updateElementControls(nextEl);
  }
}

/**
 * Remove the specified comment element from the report.
 * @param el - The comments element in the report.
 */
function removeResultCommentsElement(el) {
  var parent = el.closest(".report-element-children");

  // TODO Remove event listeners

  // Remove element, show the new element container
  el.remove();
  parent.children(".new-element").removeClass("hidden");
}

/**
 * ADDING CONTENT FUNCTIONS
 */

 /**
  * Inject new elements into the place where the "old",
  * new element <div> was previously located. Also take
  * care of everything else.
  * @param newElToBeReplaced - The "new element" to be replaced.
  * @param elements - A JSON array of elements to be injected.
  */
function addElements(newElToBeReplaced, elements) {
  var parent;

  // Remove event listener on the new element to be replaced
  newElToBeReplaced.off("click");

  parent = newElToBeReplaced.parent();
  newElToBeReplaced.addClass("original-new-el");
  var prevEl = newElToBeReplaced;
  var lastChild, secLastChild;
  var newElements = [];
  for (var i = 0; i < elements.length; i++) {
    var newEl = addElement(elements[i], prevEl);
    prevEl = newEl;
    newElements.push(newEl);
  }

  if (parent.length && parent.length > 0) {
    // Remove a potential last new child element remaining
    lastChild = parent.children().last();
    if (lastChild.length && lastChild.length > 0) {
      secLastChild = lastChild.prev();
      if (secLastChild.length && secLastChild.length > 0) {
        if (lastChild.hasClass("new-element") &&
          secLastChild.hasClass("new-element")) {
          // TODO Remove event listeners on existing element

          lastChild.remove();
        }
      }
    }
  }

  // Remove the temporary class from all
  // added new elements
  $(".new-element.added-new-element")
  .removeClass("added-new-element");

  // Remove the "replaced" element
  newElToBeReplaced.remove();

  // Initialize everything on all elements
  _.each(newElements, function(element) {
    initializeReportElements($(element));

    // Update previous and next element controls
    updateElementControls(element.prev())
    updateElementControls(element.next())
  });
}

/**
 * Add a single element to the DOM after the
 * previous element. This function is recursive.
 * @param jsonEl - The JSON element to be inserted.
 * @param prevEl - The jQuery element preceeding
 * the newly injected element.
 * @returns The newly created jQuery element.
 */
function addElement(jsonEl, prevEl) {
  var el = $(jsonEl.html);

  // If such an element already exists in the report, remove it
  // (this only applies to report elements)
  if (el.hasClass("report-element")) {
    var existing = $(REPORT_CONTENT)
    .find(
      ".report-element" +
      "[data-type='" + el.attr("data-type") + "']" +
      "[data-scroll-id='" + el.attr("data-scroll-id") + "']"
    );
    if (existing.length && existing.length > 0) {
      // TODO Remove event listeners on existing element

      // First, remove the "new element" before the existing one
      var prevNewEl = existing.prev();
      if (prevNewEl.hasClass("new-element") &&
        !prevNewEl.hasClass("original-new-el") &&
        !prevNewEl.hasClass("added-new-element")) {
        // TODO Remove event listeners on existing element

        prevNewEl.remove();
      }
      existing.remove();
    }
  } else if (el.hasClass("new-element")) {
    el.addClass("added-new-element");
  }

  // Add the new element after the previous one
  prevEl.after(el);

  // If element has children, recursively add them to the element
  var children = jsonEl.children;
  var childrenContainer = el.find(".report-element-children");
  var child, prevChild;
  var lastChild, secLastChild;
  if (!_.isUndefined(children) && children.length > 0) {
    for (var i = 0; i < children.length; i++) {
      if (i === 0) {
        // Make a "dummy" child so following children
        // can be added after it recursively
        var tmpDiv = $("<div class='hidden'></div>");
        childrenContainer.append(tmpDiv);
        child = addElement(children[i], tmpDiv);
        tmpDiv.remove();
      } else {
        child = addElement(children[i], prevChild);
      }
      prevChild = child;
    }

    // Remove a potential last new child element remaining
    lastChild = childrenContainer.children().last();
    if (lastChild.length && lastChild.length > 0) {
      secLastChild = lastChild.prev();
      if (secLastChild.length && secLastChild.length > 0) {
        if (lastChild.hasClass("new-element") &&
          secLastChild.hasClass("new-element")) {
          // TODO Remove event listeners on existing element

          lastChild.remove();
        }
      }
    }
  }

  return el;
}

/**
 * Construct the report contents JSON. This is used
 * when saving/updating the report.
 * @return The JSON representation of report contents.
 */
function constructReportContentsJson() {
  var res = [];
  var rootEls = $(REPORT_CONTENT).children(".report-element");

  _.each(rootEls, function(el) {
    res.push(constructElementContentsJson($(el)));
  });

  return res;
}

/**
 * Recursive function to retrieve element JSON contents.
 * @return The JSON representation of the element.
 */
function constructElementContentsJson(el) {
  var jsonEl = {};
  jsonEl["type_of"] = el.data("type");
  jsonEl["id"] = el.data("id");
  jsonEl["sort_order"] = null;
  if (!_.isUndefined(el.data("order"))) {
    jsonEl["sort_order"] = el.data("order");
  }

  var jsonChildren = [];
  var childrenContainer = el.children(".report-element-children");
  if (childrenContainer.length && childrenContainer.length == 1) {
    var children = childrenContainer.children(".report-element");
    _.each(children, function(child) {
      jsonChildren.push(constructElementContentsJson($(child)));
    });
  }
  jsonEl["children"] = jsonChildren;

  return jsonEl;
}

// Check if we are actually at new report page
if ($(REPORT_CONTENT).length) {
  init();
}

/** Convert Handsone table to normal table **/
function reportHandsonTableConverter() {
  setTimeout(() => {
    $.each($('.hot-table-container'), function(index, value) {
      var table = $(value);
      var header = table.find('.ht_master thead');
      var body = table.find('.ht_master tbody');
      table.next().append(header).append(body);
      table.remove();
    });
  }, 0);
}
