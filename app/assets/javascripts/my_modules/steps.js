// Sets callbacks for toggling checkboxes
function applyCheckboxCallBack()  {
  $("div.checkbox").on('click', function(e){
    var checkboxitem = $(this).find("input");

    var checked = checkboxitem.is(":checked");
    $.ajax({
      url: checkboxitem.data("link-url"),
      type: "POST",
      dataType: "json",
      data: {checklistitem_id: checkboxitem.data("id"), checked: checked},
      success: function (data) {
        checkboxitem.prop("checked", checked);
      },
      error: function (data) {
        checkboxitem.prop("checked", !checked);
      }
    });
  });
}

// Sets callback for completing/uncompleting step
function applyStepCompletedCallBack() {
  $("div.complete-step, div.uncomplete-step").on('click', function(e){
    var button = $(this);
    var step = $(this).parents(".step");
    var completed = !step.hasClass("completed");

    $.ajax({
      url: button.data("link-url"),
      type: "POST",
      dataType: "json",
      data: {completed: completed},
      success: function (data) {
        var button;
        if (completed) {
          step.addClass("completed").removeClass("not-completed");

          button = step.find("div.complete-step");
          button.addClass("uncomplete-step").removeClass("complete-step");
          button.find(".btn").removeClass("btn-primary").addClass("btn-default");
        }
        else {
          step.addClass("not-completed").removeClass("completed");

          button = step.find("div.uncomplete-step");
          button.addClass("complete-step").removeClass("uncomplete-step");
          button.find(".btn").removeClass("btn-default").addClass("btn-primary");
        }

        button.find("button").html(data.new_title);
      },
      error: function (data) {
        console.log ("error");
      }
    });
  });
}

function applyCancelCallBack() {
  //Click on cancel button
  $("#cancel-edit").on("ajax:success", function(e, data) {
    var $form = $(this).closest("form");

    $form.after(data.html);
    var $new_step = $(this).next();
    $(this).remove();

    initCallBacks();
    initHandsOnTable($new_step);
    toggleButtons(true);
  });

  $("#cancel-edit").on("ajax:error", function(e, xhr, status, error) {
    // TODO: error handling

  });
}

// Set callback for click on edit button
function applyEditCallBack() {
  $(".edit-step").on("ajax:success", function(e, data) {
    var $step = $(this).closest(".step");
    var $edit_step = $step.after(data.html);
    var $form = $step.next();
    $step.remove();

    formCallback($form);
    initEditableHandsOnTable($form);
    applyCancelCallBack();
    formEditAjax($form);
    toggleButtons(false);
    initializeCheckboxSorting();

    $("#new-step-checklists fieldset.nested_step_checklists ul").each(function () {
      enableCheckboxSorting(this);
    });
  });
  $(".edit-step").on("ajax:error", function(e, xhr, status, error) {
    // TODO: render errors
  });
}

function formCallback($form) {
  $form
  .on("fields_added.nested_form_fields", function(e, param) {
    if (param.object_class == "table") {
      initEditableHandsOnTable($form);
    }
  })
  .on("fields_removed.nested_form_fields", function(e, param) {
    if (param.object_class == "asset") {
      // Clear file input
      $(e.target).find("input[type='file']").val("");
    }
  });

  // Add asset validation
  $form.add_upload_file_size_check(function() {
    tabsPropagateErrorClass($form);
  });

  // Add hidden fields for tables
  $form.submit(function(){
    $(this).find(".editable-table").each(function() {
      var hot = $(this).find(".hot").handsontable('getInstance');
      if (hot) {
        var contents = $(this).find('.hot-contents');
        var data = JSON.stringify({data: hot.getData()});
        contents.attr("value", data);
      }
    });
    return true;
  });
}

// Init ajax success/error for edit form
function formEditAjax($form) {
  var selectedTabIndex;
  $form
  .on("ajax:beforeSend", function () {
    $(".nested_step_checklists ul").each(function () {
      reorderCheckboxData(this);
    });
  })
  .on("ajax:send", function(e, data) {
    selectedTabIndex = $form.find("li.active").index() + 1;
  });
  $form.on("ajax:success", function(e, data) {
    $(this).after(data.html);
    var $new_step = $(this).next();
    $(this).remove();

    initCallBacks();
    initHandsOnTable($new_step);
    toggleButtons(true);

    // Show the edited step
    $new_step.find(".panel-collapse:first").addClass("collapse in");

    //Rerender tables
    $new_step.find("div.step-result-hot-table").each(function()  {
      $(this).handsontable("render");
    });
  });

  $form.on("ajax:error", function(e, xhr, status, error) {
    $(this).after(xhr.responseJSON.html);
    var $form = $(this).next();
    $(this).remove();

    formCallback($form);
    initEditableHandsOnTable($form);
    applyCancelCallBack();
    formEditAjax($form);
    tabsPropagateErrorClass($form);

    //Rerender tables
    $new_step.find("div.step-result-hot-table").each(function()  {
      $(this).handsontable("render");
    });

    // Select the same tab pane as before
    $form.find("ul.nav-tabs li.active").removeClass("active");
    $form.find(".tab-content div.active").removeClass("active");
    $form.find("ul.nav-tabs li:nth-child(" + selectedTabIndex + ")").addClass("active");
    $form.find(".tab-content div:nth-child(" + selectedTabIndex + ")").addClass("active");
  });
}

function formNewAjax($form) {
  $form
  .on("ajax:beforeSend", function () {
    $(".nested_step_checklists ul").each(function () {
      reorderCheckboxData(this);
    });
  })
  .on("ajax:success", function(e, data) {
    $(this).after(data.html);
    var $new_step = $(this).next();
    $(this).remove();

    initCallBacks();
    expandStep($new_step);
    initHandsOnTable($new_step);
    toggleButtons(true);
  });

  $form.on("ajax:error", function(e, xhr, status, error) {
    $(this).after(xhr.responseJSON.html);
    var $form = $(this).next();
    $(this).remove();

    formCallback($form);
    formNewAjax($form);
    applyCancelOnNew();
    tabsPropagateErrorClass($form);
  });
}

function toggleButtons(show) {
  if (show) {
    $("#new-step").show();
    $(".edit-step-button").show();
  } else {
    $("#new-step").hide();
    $(".edit-step-button").hide();
  }
}

// Creates handsontable where needed
function initHandsOnTable(root) {
  root.find("div.hot_table").each(function()  {
    var $container = $(this).find(".step-result-hot-table");
    var contents = $(this).find('.hot-contents');

    $container.handsontable({
      startRows: 5,
      startCols: 5,
      rowHeaders: true,
      colHeaders: true,
      cells: function (row, col, prop) {
        var cellProperties = {};

        if (col >= 0)
          cellProperties.readOnly = true;
        else
          cellProperties.readOnly = false;

        return cellProperties;
      }
    });
    var hot = $container.handsontable('getInstance');

    if (contents.attr("value")) {
      var data = JSON.parse(contents.attr("value"));
      hot.loadData(data.data);
    }
  });


   //Rerender tables after showing them in panel
   $(".step-info-tab")
  .on("shown.bs.tab", function() {
    root.find("div.step-result-hot-table").each(function()  {
      $(this).handsontable("render");
    });
  });
  $(".step-panel-collapse-link")
  .on("ajax:success", function() {
    var collapseIcon = $(this).find(".collapse-step-icon");

    // Toggle collapse button
    collapseIcon.toggleClass("glyphicon-collapse-up");
    collapseIcon.toggleClass("glyphicon-collapse-down");

    root.find("div.step-result-hot-table").each(function()  {
      $(this).handsontable("render");
    });
  });
}

// Init handsontable which can be edited
function initEditableHandsOnTable(root) {
  root.find(".editable-table").each(function() {
    var $container = $(this).find(".hot");

    $container.handsontable({
      startRows: 5,
      startCols: 5,
      rowHeaders: true,
      colHeaders: true,
      contextMenu: true
    });
    var hot = $(this).find(".hot").handsontable('getInstance');
    var contents = $(this).find('.hot-contents');
    if (contents.attr("value")) {
      var data = JSON.parse(contents.attr("value"));
      hot.loadData(data.data);
    }
  });

  $(".new-step-tables-tab")
  .on("shown.bs.tab", function() {
    $(this).parents("form").find("div.hot").each(function()  {
      $(this).handsontable("render");
    });
  });
}

// Initialize comment form.
function initStepCommentForm($el) {

  var $form = $el.find("ul form");

  $(".help-block", $form).addClass("hide");

  $form.on("ajax:send", function (data) {
    $("#comment_message", $form).attr("readonly", true);
  })
  .on("ajax:success", function (e, data) {
    if (data.html) {
      var list = $form.parents("ul");

      // Remove potential "no comments" element
      list.parent().find(".content-comments")
        .find("li.no-comments").remove();

      list.parent().find(".content-comments")
        .prepend("<li class='comment'>" + data.html + "</li>")
        .scrollTop(0);
      list.parents("ul").find("> li.comment:gt(8)").remove();
      $("#comment_message", $form).val("");
      $(".form-group", $form)
        .removeClass("has-error");
      $(".help-block", $form)
          .html("")
          .addClass("hide");
    }
  })
  .on("ajax:error", function (ev, xhr) {
    if (xhr.status === 400) {
      var messageError = xhr.responseJSON.errors.message;

      if (messageError) {
        $(".form-group", $form)
          .addClass("has-error");
        $(".help-block", $form)
            .html(messageError[0])
            .removeClass("hide");
      }
    }
  })
  .on("ajax:complete", function () {
    $("#comment_message", $form)
      .attr("readonly", false)
      .focus();
  });
}

// Initialize show more comments link.
function initStepCommentsLink($el) {

  $el.find(".btn-more-comments")
  .on("ajax:success", function (e, data) {
    if (data.html) {
      var list = $(this).parents("ul");
      var moreBtn = list.find(".btn-more-comments");
      var listItem = moreBtn.parents('li');
      $(data.html).insertBefore(listItem);
      if (data.results_number < data.per_page) {
        moreBtn.remove();
      } else {
        moreBtn.attr("href", data.more_url);
      }
    }
  });
}

function initStepCommentTabAjax() {
  $(".comment-tab-link")
  .on("ajax:before", function (e) {
    var $this = $(this);
    var parentNode = $this.parents("li");
    var targetId = $this.attr("aria-controls");

    if (parentNode.hasClass("active")) {
      // TODO move to fn
      parentNode.removeClass("active");
      $("#" + targetId).removeClass("active");
      return false;
    }
  })
  .on("ajax:success", function (e, data) {
    if (data.html) {
      var $this = $(this);
      var targetId = $this.attr("aria-controls");
      var target = $("#" + targetId);
      var parentNode = $this.parents("ul").parent();

      target.html(data.html);
      initStepCommentForm(parentNode);
      initStepCommentsLink(parentNode);

      parentNode.find(".active").removeClass("active");
      $this.parents("li").addClass("active");
      target.addClass("active");
    }
  })
  .on("ajax:error", function(e, xhr, status, error) {
    // TODO
  })
  .on("ajax:complete", function () {
    $(this).tab("show");
  });
}

function applyCancelOnNew() {
  $(".cancel-new").click(function() {
    var $form = $(this).closest("form");
    $form.parent().remove();
    toggleButtons(true);
  });
}

function initDeleteStep(){
  $(".delete-step").on("confirm:complete", function (e, answer) {
    if (answer) {
      animateLoading();
    }
  });
}

function initCallBacks() {
  applyCheckboxCallBack();
  applyStepCompletedCallBack();
  applyEditCallBack();
  initStepCommentTabAjax();
  initDeleteStep();
}

function reorderCheckboxData(el) {
  var itemIds = [];
  var checkboxes = $(el).find(".nested_fields:not(:hidden) .form-group");

  checkboxes.each(function () {
    var itemId = $(this).find("label").attr("for").match(/(\d+)_text/)[1];
    itemIds.push(itemId);
  });

  itemIds.sort();

  checkboxes.each(function (i) {
    var $this = $(this);
    var label = $this.find(".control-label");
    var input = $this.find(".form-control");
    var posInput = $this.parent().find(".checklist-item-pos");
    var itemId = itemIds[i];
    var forAttr = label.attr("for");
    var idAttr = input.attr("id");
    var nameAttr = input.attr("name");
    var posIdAttr = posInput.attr("id");
    var posNameAttr = posInput.attr("name");

    forAttr = forAttr.replace(/\d+_text/, itemId + "_text");
    nameAttr = nameAttr.replace(/\[\d+\]\[text\]/, "[" + itemId + "][text]");
    posIdAttr = posIdAttr.replace(/\d+_position/, itemId + "_text");
    posNameAttr = posNameAttr.replace(/\[\d+\]\[position\]/, "[" + itemId + "][position]")

    label.attr("for", forAttr);
    input.attr("name", nameAttr);
    input.attr("id", forAttr);
    posInput.attr("name", posNameAttr);
    posInput.attr("id", posIdAttr);     
    posInput.val(itemId);
  });
}

function enableCheckboxSorting(el) {
  Sortable.create(el, {
    draggable: 'fieldset', 
    filter: 'script',
    handle: '.glyphicon-chevron-right',

    onUpdate: function () {
      reorderCheckboxData(el);
    }
  });
}

function initializeCheckboxSorting() {
  var el = $("#new-step-checklists a[data-association-path=step_checklists]");

  el.click(function () {
    // calling code below must be defered because at this step HTML in not
    // inserted into DOM.
    setTimeout(function () {
      var list = el.parent().find("fieldset.nested_step_checklists:last ul");
 
      enableCheckboxSorting(list.get(0));
    });
  });
}

// New step AJAX
$("#new-step").on("ajax:success", function(e, data) {
  var $form = $(data.html);
  $("#steps").append($form);

  // Scroll to bottom
  $("html, body").animate({ scrollTop: $(document).height()-$(window).height() });
  formCallback($form);
  formNewAjax($form);
  applyCancelOnNew();
  toggleButtons(false);
  initializeCheckboxSorting();
});

// Initialize edit description modal window
function initEditDescription() {
  var editDescriptionModal = $("#manage-module-description-modal");
  var editDescriptionModalBody = editDescriptionModal.find(".modal-body");
  var editDescriptionModalSubmitBtn = editDescriptionModal.find("[data-action='submit']");
  $(".description-link")
  .on("ajax:success", function(ev, data, status) {
    var descriptionLink = $(".description-refresh");

    // Set modal body & title
    editDescriptionModalBody.html(data.html);
    editDescriptionModal
    .find("#manage-module-description-modal-label")
    .text(data.title);

    editDescriptionModalBody.find("form")
    .on("ajax:success", function(ev2, data2, status2) {
      // Update module's description in the tab
      descriptionLink.html(data2.description_label);

      // Close modal
      editDescriptionModal.modal("hide");
    })
    .on("ajax:error", function(ev2, data2, status2) {
      // Display errors if needed
      $(this).render_form_errors("my_module", data.responseJSON);
    });

    // Show modal
    editDescriptionModal.modal("show");
  })
  .on("ajax:error", function(ev, data, status) {
    // TODO
  });

  editDescriptionModalSubmitBtn.on("click", function() {
    // Submit the form inside the modal
    editDescriptionModalBody.find("form").submit();
  });

  editDescriptionModal.on("hidden.bs.modal", function() {
    editDescriptionModalBody.find("form").off("ajax:success ajax:error");
    editDescriptionModalBody.html("");
  });
}

function bindEditDueDateAjax() {
  var editDueDateModal = null;
  var editDueDateModalBody = null;
  var editDueDateModalTitle = null;
  var editDueDateModalSubmitBtn = null;

  editDueDateModal = $("#manage-module-due-date-modal");
  editDueDateModalBody = editDueDateModal.find(".modal-body");
  editDueDateModalTitle = editDueDateModal.find("#manage-module-due-date-modal-label");
  editDueDateModalSubmitBtn = editDueDateModal.find("[data-action='submit']");

  $(".due-date-link")
  .on("ajax:success", function(ev, data, status) {
    var dueDateLink = $(".due-date-refresh");

    // Load contents
    editDueDateModalBody.html(data.html);
    editDueDateModalTitle.text(data.title);

    // Add listener to form inside modal
    editDueDateModalBody.find("form")
    .on("ajax:success", function(ev2, data2, status2) {
      // Update module's due date
      dueDateLink.html(data2.module_header_due_date_label);

      // Close modal
      editDueDateModal.modal("hide");
    })
    .on("ajax:error", function(ev2, data2, status2) {
      // Display errors if needed
      $(this).render_form_errors("my_module", data.responseJSON);
    });

    // Open modal
    editDueDateModal.modal("show");
  })
  .on("ajax:error", function(ev, data, status) {
    // TODO
  });

  editDueDateModalSubmitBtn.on("click", function() {
    // Submit the form inside the modal
    editDueDateModalBody.find("form").submit();
  });

  editDueDateModal.on("hidden.bs.modal", function() {
    editDueDateModalBody.find("form").off("ajax:success ajax:error");
    editDueDateModalBody.html("");
  });
}

// Expand all steps
function expandAllSteps () {
  $('.step .panel-collapse').collapse('show');
  $(document).find("div.step-result-hot-table").each(function()  {
    $(this).handsontable("render");
  });
  $(document).find("span.collapse-step-icon").each(function()  {
    $(this).addClass("glyphicon-collapse-up");
    $(this).removeClass("glyphicon-collapse-down");
  });
}

function expandStep(step) {
  $('.panel-collapse', step).collapse('show');
  $(step).find("span.collapse-step-icon").each(function()  {
    $(this).addClass("glyphicon-collapse-up");
    $(this).removeClass("glyphicon-collapse-down");
  });
}

// On init
initCallBacks();
initHandsOnTable($(document));
bindEditDueDateAjax();
initEditDescription();
expandAllSteps();
initTutorial();

$(function () {

  $("#steps-collapse-btn").click(function () {
    $('.step .panel-collapse').collapse('hide');
    $(document).find("span.collapse-step-icon").each(function()  {
      $(this).addClass("glyphicon-collapse-down");
      $(this).removeClass("glyphicon-collapse-up");
    });
  });

  $("#steps-expand-btn").click(expandAllSteps);
});

function initTutorial() {
  var currentStep = Cookies.get('current_tutorial_step');
  if (showTutorial() && (currentStep == '6' || currentStep == '7')) {
    var navTabs = $("#secondary-menu").find("ul.navbar-right");
    var moduleProtocolsTutorial = $("#steps").attr("data-module-protocols-step-text");
    navTabs.attr('data-step', '7');
    navTabs.attr('data-intro', moduleProtocolsTutorial);
    navTabs.attr('data-position', 'left');
    Cookies.set('current_tutorial_step', '7');

    introJs()
      .setOptions({
        overlayOpacity: '0.1',
        doneLabel: 'End tutorial',
        showBullets: false,
        showStepNumbers: false,
        tooltipClass: 'custom disabled-next'
      })
      .start();

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
  var tutorialModuleId = tutorialData[0].qpcr_module;
  var currentModuleId = $("#steps").attr("data-module-id");
  return tutorialModuleId == currentModuleId;
}

// S3 direct uploading
function startFileUpload(ev, btn) {
  var form = btn.form;
  var $form = $(form);
  var fileInputs = $form.find("input[type=file]");
  var url = '/asset_signature.json';
  var inputPos = 0;
  var inputPointer = 0;

  $form.clear_form_errors();
  animateSpinner($form);

  function processFile () {
    var fileInput = fileInputs.get(inputPos);
    inputPos += 1;
    inputPointer += 1;

    if (!fileInput) {
      btn.onclick = null;
      $(btn).click();
      animateSpinner($form, false);
      return;
    }

    directUpload(form, null, url, function (assetId) {
      fileInput.type = "hidden";
      fileInput.name = fileInput.name.replace("[file]", "[id]");
      fileInput.value = assetId;
      inputPointer -= 1;

      processFile();

    }, function (errors) {
      var assetError;

      animateSpinner($form, false);

      for (var c in errors) {
        if (/^asset\./.test(c)) {
          assetError = errors[c];
          break;
        }
      }
      if (assetError) {
        var el = $form.find("input[type=file]").get(inputPointer - 1);
        var $el = $(el);

        $form.clear_form_errors();
        $el.closest(".form-group").addClass("has-error");
        $el.parent().append("<span class='help-block'>" + assetError + "</span>");
      }
    });
  }

  processFile();
  ev.preventDefault();
}
