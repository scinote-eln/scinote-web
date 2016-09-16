//= require handsontable.full.min
//= require Sortable.min
//= require canvas-to-blob.min
//= require direct-upload
//= require assets
//= require comments

// Sets callbacks for toggling checkboxes
function applyCheckboxCallBack()  {
  $("[data-action='check-item']").on('click', function(e){
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
  $("[data-action='complete-step'], [data-action='uncomplete-step']").on('click', function(e){
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

          button = step.find("[data-action='complete-step']");
          button.attr("data-action", "uncomplete-step");
          button.find(".btn").removeClass("btn-primary").addClass("btn-default");
        }
        else {
          step.addClass("not-completed").removeClass("completed");

          button = step.find("[data-action='uncomplete-step']");
          button.attr("data-action", "complete-step");
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
  $("[data-action='cancel-edit']")
  .on("ajax:success", function(e, data) {
    var $form = $(this).closest("form");

    $form.after(data.html);
    var $new_step = $(this).next();
    $(this).remove();

    initCallBacks();
    initHandsOnTable($new_step);
    toggleButtons(true);
  })
  .on("ajax:error", function(e, xhr, status, error) {
    // TODO: error handling
  });
}

// Set callback for click on edit button
function applyEditCallBack() {
  $("[data-action='edit-step']")
  .on("ajax:success", function(e, data) {
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
    $("#step_name").focus();
    $("#new-step-main-tab a").on("shown.bs.tab", function() {
      $("#step_name").focus();
    });
  });
}

// Set callback for click on edit button
function applyMoveStepCallBack() {
  $("[data-action='move-step']")
  .on("ajax:success", function(e, data) {
    var $step = $(this).closest(".step");
    var stepUpPosition = data.step_up_position;
    var stepDownPosition = data.step_down_position;
    var $stepDown, $stepUp;
    switch (data.move_direction) {
      case "up":
        $stepDown = $step.prev(".step");
        $stepUp = $step;
        break;
      case "down":
        $stepDown = $step;
        $stepUp = $step.next(".step");
    }

    // Switch position of top and bottom steps
    if (!_.isUndefined($stepDown) && !_.isUndefined($stepUp)) {
      $stepDown.insertAfter($stepUp);
      $stepDown.find(".badge").html(stepDownPosition+1);
      $stepUp.find(".badge").html(stepUpPosition+1);
      $("html, body").animate({ scrollTop: $step.offset().top - window.innerHeight / 2 });
    }
  });
}

function applyCollapseLinkCallBack() {
  $(".step-panel-collapse-link")
    .on("ajax:success", function() {
      var collapseIcon = $(this).find(".collapse-step-icon");
      var collapsed = $(this).hasClass("collapsed");
      // Toggle collapse button
      collapseIcon.toggleClass("glyphicon-collapse-up", !collapsed);
      collapseIcon.toggleClass("glyphicon-collapse-down", collapsed);

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

  // Add hidden fields for tables
  $form.submit(function(){
    $(this).find("[data-role='editable-table']").each(function() {
      var hot = $(this).find(".hot").handsontable('getInstance');
      if (hot && hot.countEmptyRows() != hot.countRows()) {
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
    initHandsOnTable($new_step);
    toggleButtons(true);

    // Show the edited step
    $new_step.find(".panel-collapse:first").addClass("collapse in");

    //Rerender tables
    $new_step.find("[data-role='step-hot-table']").each(function()  {
      renderTable($(this));
    });
  })
  .on("ajax:error", function(e, xhr, status, error) {
    $(this).after(xhr.responseJSON.html);
    var $form = $(this).next();
    $(this).remove();

    $errInput = $form.find(".form-group.has-error").first().find("input");
    renderFormError(e, $errInput);

    formCallback($form);
    initEditableHandsOnTable($form);
    applyCancelCallBack();
    formEditAjax($form);

    //Rerender tables
    $form.find("[data-role='step-hot-table']").each(function()  {
      renderTable($(this));
    });
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
    initHandsOnTable($new_step);
    expandStep($new_step);
    toggleButtons(true);

    //Rerender tables
    $new_step.find("div.step-result-hot-table").each(function()  {
      $(this).handsontable("render");
    });
  })
  .on("ajax:error", function(e, xhr, status, error) {
    $(this).after(xhr.responseJSON.html);
    var $form = $(this).next();
    $(this).remove();

    $errInput = $form.find(".form-group.has-error").first().find("input");
    renderFormError(e, $errInput);

    formCallback($form);
    formNewAjax($form);
    applyCancelOnNew();
  });
}

function toggleButtons(show) {
  if (show) {
    $("[data-action='new-step']").show();
    $("[data-action='edit-step']").show();

    // Also show "no steps" label if no steps are present
    if (!$(".step").length) {
      $("[data-role='no-steps-text']").show();
    } else {
      $("[data-role='no-steps-text']").hide();
    }

  } else {
    $("[data-action='new-step']").hide();
    $("[data-action='edit-step']").hide();

    // Also hide "no steps" label if no steps are present
    $("[data-role='no-steps-text']").hide();
  }
}

// Creates handsontable where needed
function initHandsOnTable(root) {
  root.find("[data-role='hot-table']").each(function()  {
    var $container = $(this).find("[data-role='step-hot-table']");
    var contents = $(this).find('.hot-contents');

    $container.handsontable({
      startRows: 5,
      startCols: 5,
      rowHeaders: true,
      colHeaders: true,
      fillHandle: false,
      formulas: true,
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
}

// Init handsontable which can be edited
function initEditableHandsOnTable(root) {
  root.find("[data-role='editable-table']").each(function() {
    var $container = $(this).find(".hot");

    if ($container.is("[initialized]")) {
      return true;
    }

    var contents = $(this).find('.hot-contents');
    var data = null;
    if (contents.attr("value")) {
      data = JSON.parse(contents.attr("value")).data;
    }
    if ($container.is(":visible")) {
      $(this).css("width", $("#new-step-tables").css("width"));
    }

    $container.handsontable({
      data: data,
      startRows: 5,
      startCols: 5,
      minRows: 1,
      minCols: 1,
      rowHeaders: true,
      colHeaders: true,
      contextMenu: true,
      formulas: true,
      preventOverflow: 'horizontal'
    });

    $container.attr("initialized", true);
    renderTable($container);
  });

  $("#new-step-tables-tab a")
  .on("shown.bs.tab", function() {
    $(this).parents("form").find("div.hot").each(function()  {
      $(this).parent().css("width", $("#new-step-tables").css("width"));
      renderTable($(this));
    });
  });
}

// Initialize comment form.
function initStepCommentForm(ev, $el) {
  var $form = $el.find("ul form");

  var $commentInput = $form.find("#comment_message");

  $(".help-block", $form).addClass("hide");

  $form
  .on("ajax:send", function (data) {
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
      scrollCommentOptions(
        list.parent().find(".content-comments .dropdown-comment")
      );
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
        moreBtn.trigger("blur");
      }

      // Reposition dropdown comment options
      scrollCommentOptions(listItem.closest(".content-comments")
      .find(".dropdown-comment"));
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
      initStepCommentForm(e, parentNode);
      initStepCommentsLink(parentNode);

      parentNode.find(".active").removeClass("active");
      $this.parents("li").addClass("active");
      target.addClass("active");
    }
  })
  .on("ajax:error", function(e, xhr, status, error) {
    // TODO
  });
}

function applyCancelOnNew() {
  $("[data-action='cancel-new']").click(function() {
    var $form = $(this).closest("form");
    $form.parent().remove();
    toggleButtons(true);
  });
}

function initDeleteStep(){
  $("[data-action='delete-step']").on("confirm:complete", function (e, answer) {
    if (answer) {
      animateLoading();
    }
  });
}

function initCallBacks() {
  applyCheckboxCallBack();
  applyStepCompletedCallBack();
  applyEditCallBack();
  applyMoveStepCallBack();
  applyCollapseLinkCallBack();
  initStepCommentTabAjax();
  initDeleteStep();
}

/*
 * Correction for sorting with "Sortable.min" JS library to work correctly with
 * "nested_form_fields" gem.
 */
function reorderCheckboxData(checkboxUl) {
  // Make sure checkbox item insertion script is always at the bottom of "ul"
  // tag, otherwise item will not be inserted at bottom
  if(!$(checkboxUl).children().last().is('script')) {
    $(checkboxUl).find("script").appendTo(checkboxUl);
  }

  var $checkboxes = $(checkboxUl).find(".nested_fields");
  $checkboxes.each(function (itemPos) {
    var $this = $(this);

    var $formGroup = $this.find(".form-group");
    var $label = $formGroup.find(".control-label");
    var $textInput = $formGroup.find(".checklist-item-text");
    var $posInput = $formGroup.parent().find(".checklist-item-pos");
    var $destroyLink = $this.find(".remove_nested_fields_link");

    var labelFor = $label.attr("for");
    var textName = $textInput.attr("name");
    var textId = $textInput.attr("id");
    var posName = $posInput.attr("name");
    var posId = $posInput.attr("id");
    var destroyLink = $destroyLink.attr("data-delete-association-field-name");

    labelFor = labelFor.replace(/\d+_text/, itemPos + "_text");
    textName = textName.replace(/\[\d+\]\[text\]/, "[" + itemPos + "][text]");
    textId = textId.replace(/\d+_text/, itemPos + "_text");
    posName = posName.replace(/\[\d+\]\[position\]/, "[" + itemPos + "][position]");
    posId = posId.replace(/\d+_position/, itemPos + "_position");
    destroyLink = destroyLink.replace(/\[\d+\]\[_destroy\]/, "[" + itemPos + "][_destroy]");

    $label.attr("for", labelFor);
    $textInput.attr("name", textName); // Actually needed for sorting to work
    $textInput.attr("id", textId);
    $posInput.attr("name", posName);
    $posInput.attr("id", posId);
    $posInput.val(itemPos);
    $destroyLink.attr("data-delete-association-field-name", destroyLink);

    var $idInput = $this.find("> input");
    if ($idInput.length) {
      var idName = $idInput.attr("name");
      var idId = $idInput.attr("id");

      idName = idName.replace(/\[\d+\]\[id\]/, "[" + itemPos + "][id]");
      idId = idId.replace(/\d+_id/, itemPos + "_id");

      $idInput.attr("name", idName);
      $idInput.attr("id", idId);
    }

    if ($this.css('display') == 'none') {
      // Actually needed for deleting to work
      var $destroyInput = $this.prev();
      var destroyName = $destroyInput.attr("name");
      destroyName = destroyName.replace(/\[\d+\]\[_destroy\]/, "[" + itemPos + "][_destroy]");
      $destroyInput.attr("name", destroyName);
    }
  });
}

function enableCheckboxSorting(el) {
  Sortable.create(el, {
    draggable: 'fieldset',
    handle: '.glyphicon-chevron-right',
    onUpdate: function () {
      reorderCheckboxData(el);
    }
  });
}

function initializeCheckboxSorting() {
  var el = $("#new-step-checklists a[data-association-path=step_checklists]");

  el.click(function () {
    // calling code below must be defered because at this step HTML is not
    // inserted into DOM.
    setTimeout(function () {
      var list = el.parent().find("fieldset.nested_step_checklists:last ul");

      enableCheckboxSorting(list.get(0));
    });
  });
}

// New step AJAX
$("[data-action='new-step']").on("ajax:success", function(e, data) {
  var $form = $(data.html);
  $("#steps").append($form);

  // Scroll to bottom
  $("html, body").animate({ scrollTop: $(document).height()-$(window).height() });
  formCallback($form);
  formNewAjax($form);
  applyCancelOnNew();
  toggleButtons(false);
  initializeCheckboxSorting();

  $("#step_name").focus();
  $("#new-step-main-tab a").on("shown.bs.tab", function() {
    $("#step_name").focus();
  });
});

// Needed because server-side validation failure clears locations of
// files to be uploaded and checklist's items etc. Also user
// experience is improved
function processStep(ev, editMode, forS3) {
  var $form = $(ev.target.form);
  $form.clearFormErrors();
  $form.removeBlankExcelTables(editMode);
  $form.removeBlankFileForms();

  var $fileInputs = $form.find("input[type=file]");
  var filesValid = filesValidator(ev, $fileInputs, FileTypeEnum.FILE);
  var $checklists = $form.find(".nested_step_checklists");
  var checklistsValid = checklistsValidator(ev, $checklists, editMode);
  var $nameInput = $form.find("#step_name");
  var nameValid = textValidator(ev, $nameInput);

  if (filesValid && checklistsValid && nameValid) {
    if (forS3) {
      // Redirects file uploading to S3
      var url = '/asset_signature.json';
      directUpload(ev, url);
    } else {
      // Local file uploading
      animateSpinner();
    }
  }
}

// Expand all steps
function expandAllSteps() {
  $('.step .panel-collapse').collapse('show');
  $(document).find("[data-role='step-hot-table']").each(function()  {
    renderTable($(this));
  });
  $(document).find("span.collapse-step-icon").each(function()  {
    $(this).addClass("glyphicon-collapse-up");
    $(this).removeClass("glyphicon-collapse-down");
  });
}

function expandStep(step) {
  $('.panel-collapse', step).collapse('show');
  $(step).find("span.collapse-step-icon")
    .addClass("glyphicon-collapse-up")
    .removeClass("glyphicon-collapse-down");
  $(step).find("div.step-result-hot-table").each(function()  {
    renderTable($(this));
  });
}

function renderTable(table) {
  $(table).handsontable("render");
  // Yet another dirty hack to solve HandsOnTable problems
  if (parseInt($(table).css("height"), 10) < parseInt($(table).css("max-height"), 10) - 30) {
    $(table).find(".ht_master .wtHolder").css("height", "100%");
  }
}

$(document).ready(function() {
  // On init
  initCallBacks();
  initHandsOnTable($(document));
  expandAllSteps();
  setupAssetsLoading();

  // Init comments edit/delete
  initCommentOptions("ul.content-comments");
  initEditComments("#steps");
  initDeleteComments("#steps");

  $(function () {

    $("[data-action='collapse-steps']").click(function () {
      $('.step .panel-collapse').collapse('hide');
      $(document).find("span.collapse-step-icon").each(function()  {
        $(this).addClass("glyphicon-collapse-down");
        $(this).removeClass("glyphicon-collapse-up");
      });
    });

    $("[data-action='expand-steps']").click(expandAllSteps);
  });
})
