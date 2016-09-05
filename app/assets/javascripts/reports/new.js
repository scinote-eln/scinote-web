// Custom jQuery function that finds elements including
// the parent element
$.fn.findWithSelf = function(selector) {
  return this.filter(selector).add(this.find(selector));
};

var REPORT_CONTENT = "#report-content";
var SIDEBAR_PARENT_TREE = "#report-sidebar-tree";
var ADD_CONTENTS_FORM_ID = "#add-contents-form";
var SAVE_REPORT_FORM_ID = "#save-report-form";

var hotTableContainers = null;
var addContentsModal = null;
var addContentsModalBody = null;
var saveReportModal = null;
var saveReportModalBody = null;

var ignoreUnsavedWorkAlert;

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
    el.handsontable("getInstance").sort(3, order);

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
    } else if (el.hasClass("report-module-samples-element")) {
      sortModuleSamplesElement(el, true);
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
    } else if (el.hasClass("report-module-samples-element")) {
      sortModuleSamplesElement(el, false);
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
        case "my_module":
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
      data: {
        id: parentElementId
      },
      success: function(data, status, jqxhr) {
        // Open modal, set its title
        addContentsModal.find(".modal-title").text(modalTitle);

        // Display module contents
        addContentsModalBody.html(data.html);

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

            // Update sidebar
            initializeSidebarNavigation();
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
            ignoreUnsavedWorkAlert = true;
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
 * Initialize the save to PDF functionality.
 */
function initializeSaveToPdf() {
  var saveToPdfForm = $(".get-report-pdf-form");
  var hiddenInput = saveToPdfForm.find("input[type='hidden']");
  var saveToPdfBtn = saveToPdfForm.find("#get-report-pdf");

  saveToPdfBtn.click(function(e) {
    var content = $(REPORT_CONTENT);

    // Fill hidden input element
    hiddenInput.attr("value", content.html());

    // Fire form submission
    saveToPdfForm.submit();

    // Clear form
    hiddenInput.attr("value", "");

    // Prevent page reload
    e.preventDefault();
    e.stopPropagation();
    return false;
  });
}

function initializeUnsavedWorkDialog() {
  var dh = $("#data-holder");
  var alertText = dh.attr("data-unsaved-work-text");

  ignoreUnsavedWorkAlert = false;

  $(window)
  .on("beforeunload", function(ev) {
    if (ignoreUnsavedWorkAlert) {
      // Remove unload listeners
      $(window).off("beforeunload");
      $(document).off("page:before-change");

      ev.returnValue = undefined;
      return undefined;
    } else {
      return alertText;
    }
  });
  $(document).on("page:before-change", function(ev) {
    var exit;
    if (ignoreUnsavedWorkAlert) {
      exit = true;
    } else {
      exit = confirm(alertText);
    }

    if (exit) {
      // Remove unload listeners
      $(window).off("beforeunload");
      $(document).off("page:before-change");
    }

    return exit;
  });
}

/**
 * SIDEBAR CODE
 */

 /**
  * Get the sidebar <li> element for the specified report element.
  * @param reportEl - The .report-element in the report.
  * @return The corresponding sidebar <li>.
  */
function getSidebarEl(reportEl) {
  var type = reportEl.data("type");
  var id = reportEl.data("id");
  return $(SIDEBAR_PARENT_TREE).find(
    "li" +
    "[data-type='" + type + "']" +
    "[data-id='" + id + "']"
  );
}

/**
 * Get the report <div.report-element> element for the specified
 * sidebar element.
 * @param sidebarEl - The <li> sidebar element.
 * @return The corresponding report element.
 */
function getReportEl(sidebarEl) {
  var type = sidebarEl.data("type");
  var id = sidebarEl.data("id");
  return $(REPORT_CONTENT).find(
    "div.report-element" +
    "[data-type='" + type + "']" +
    "[data-id='" + id + "']"
  );
}

/**
 * Initialize the sidebar navigation pane.
 */
function initializeSidebarNavigation() {
  var reportContent = $(REPORT_CONTENT);
  var treeParent = $(SIDEBAR_PARENT_TREE);

  // Remove existing contents (also remove click listeners)
  treeParent.find(".report-nav-link").off("click");
  treeParent.children().remove();

  // Re-populate the sidebar
  _.each(reportContent.children(".report-element"), function(child) {
    var li = initSidebarElement($(child));
    li.appendTo(treeParent);
  });

  // Add click listener on all links
  treeParent.find(".report-nav-link").click(function(e) {
    var el = $(this).closest("li");
    scrollToElement(el);

    e.preventDefault();
    e.stopPropagation();
    return false;
  });

  // Call to sidebar function to re-initialize tree functionality
  setupSidebarTree();
}

/**
 * Recursive call to initialize sidebar elements.
 * @param reportEl - The report element for which to
 * generate the sidebar.
 * @return A <li> jQuery element containing sidebar entry.
 */
function initSidebarElement(reportEl) {
  var elChildrenContainer = reportEl.children(".report-element-children");
  var type = reportEl.data("type");
  var name = reportEl.data("name");
  var id = reportEl.data("id");
  var iconClass = "glyphicon " + reportEl.data("icon-class");

  // Generate list element
  var newLi = $(document.createElement("li"));
  newLi
  .attr("data-type", type)
  .attr("data-id", id);

  var newSpan = $(document.createElement("span"));
  newSpan.appendTo(newLi);
  var newI = $(document.createElement("i"));
  newI.appendTo(newSpan);
  var newHref = $(document.createElement("a"));
  newHref
  .attr("href", "")
  .addClass("report-nav-link")
  .text(name)
  .appendTo(newSpan);
  var newIcon = $(document.createElement("span"));
  newIcon.addClass(iconClass).prependTo(newHref);

  if (elChildrenContainer.length && elChildrenContainer.length > 0) {
    var elChildren = elChildrenContainer.children(".report-element");
    if (elChildren.length && elChildren.length > 0) {
      var newUl = $(document.createElement("ul"));
      newUl.appendTo(newLi);

      _.each(elChildren, function(child) {
        var li = initSidebarElement($(child));
        li.appendTo(newUl);
      });
    }
  }

  return newLi;
}

/**
 * Scroll to the specified element in the report.
 * @param sidebarEl - The sidebar element.
 */
function scrollToElement(sidebarEl) {
  var el = getReportEl(sidebarEl);

  if (el.length && el.length == 1) {
    var content = $("body");
    content.scrollTo(
      el,
      {
        axis: 'y',
        duration: 500,
        offset: -150
      }
    );
  }
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

  // Reinitialize sidebar
  initializeSidebarNavigation();
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

  // Update sidebar
  var prevEl = null;
  _.each(children, function(child) {
    var sidebarEl = getSidebarEl($(child));
    if (sidebarEl.length && sidebarEl.length == 1) {
      var sidebarParent = sidebarEl.closest("ul");
      sidebarEl.detach();
      if (prevEl === null) {
        sidebarParent.prepend(sidebarEl);
      } else {
        prevEl.after(sidebarEl);
      }
      prevEl = sidebarEl;
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
 * Sort the module samples element (special handling needs
 * to be done in this case).
 * @param el - The module samples element in the report.
 * @param asc - True to sort in ascending order, false to sort
 * in descending order.
 */
function sortModuleSamplesElement(el, asc) {
  var hotEl = el.find(".report-element-body .hot-table-container");
  var hotInstance = hotEl.handsontable("getInstance");

  hotInstance.sort(3, asc);

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

  var sidebarEl;
  if (up) {
    var prevEl = prevNewEl.prev();
    if (!prevEl.length || !prevEl.hasClass("report-element")) {
      return;
    }

    // Move sidebar element up
    sidebarEl = getSidebarEl(el);
    var sidebarPrev = sidebarEl.prev();
    sidebarEl.detach();
    sidebarPrev.before(sidebarEl);

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

    // Move sidebar element up
    sidebarEl = getSidebarEl(el);
    var sidebarNext = sidebarEl.next();
    sidebarEl.detach();
    sidebarNext.after(sidebarEl);

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

  // Remove sidebar entry
  var sidebarEl = getSidebarEl(el);
  sidebarEl.remove();

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

  // Remove sidebar entry
  var sidebarEl = getSidebarEl(el);
  sidebarEl.remove();

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
      "[data-id='" + el.attr("data-id") + "']"
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

/* Initialize the first-time demo tutorial if needed. */
function initializeTutorial() {
  if (showTutorial()) {
    ignoreUnsavedWorkAlert = true;

    introJs()
      .setOptions({
        overlayOpacity: '0.1',
        nextLabel: 'Next',
        doneLabel: 'End tutorial',
        skipLabel: 'End tutorial',
        showBullets: false,
        showStepNumbers: false,
        exitOnOverlayClick: false,
        exitOnEsc: false,
        tooltipClass: 'custom next-page-link',
        disableInteraction: true
      })
      .onafterchange(function (tarEl) {
        Cookies.set('current_tutorial_step', this._currentStep + 18);

        if (this._currentStep == 1) {
          setTimeout(function() {
            $('.next-page-link a.introjs-nextbutton')
              .removeClass('introjs-disabled')
              .attr('href', tarEl.href);
            $('.introjs-disableInteraction').remove();
          }, 500);
        } else {

        }
      })
      .start();

    window.onresize = function() {
      if (Cookies.get('current_tutorial_step') == 18) {
        $(".introjs-tooltip").css("right", ($(".new-element.initial").width() + 60)  + "px");
      }
    };

    // Destroy first-time tutorial cookies when skip tutorial
    // or end tutorial is clicked
    $(".introjs-skipbutton").each(function (){
      $(this).click(function (){
        Cookies.remove('tutorial_data');
        Cookies.remove('current_tutorial_step');
      });
    });
  }
}

function showTutorial() {
  var tutorialData;
  if (Cookies.get('tutorial_data'))
    tutorialData = JSON.parse(Cookies.get('tutorial_data'));
  else
    return false;
  var currentStep = Cookies.get('current_tutorial_step');
  if (currentStep < 16 || currentStep > 18)
    return false;
  var tutorialProjectId = tutorialData[0].project;
  var currentProjectId = $("#data-holder").attr("data-project-id");
  return tutorialProjectId == currentProjectId;
}

$(document).ready(function() {
  /**
  * ACTUAL CODE
  */
  initializeReportElements($(REPORT_CONTENT));

  initializeGlobalReportSort();
  initializePrintPopup();
  initializeSaveToPdf();
  initializeSaveReport();
  initializeAddContentsModal();
  initializeSidebarNavigation();
  initializeUnsavedWorkDialog();
  initializeTutorial();

  $(".report-nav-link").each( function(){
    truncateLongString( $(this), 30);
  });
})

$(document).change(function(){
  setTimeout(function(){
    $(".report-nav-link").each( function(){
      truncateLongString( $(this), 30);
    });
  }, 1000);
});
