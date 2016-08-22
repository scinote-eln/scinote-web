//= require handsontable.full.min
//= require Sortable.min
//= require canvas-to-blob.min
//= require direct-upload
//= require assets

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

  // Add asset validation
  $form.add_upload_file_size_check(function() {
    tabsPropagateErrorClass($form);
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
  var selectedTabIndex;
  $form
  .on("ajax:beforeSend", function () {
    $(".nested_step_checklists ul").each(function () {
      reorderCheckboxData(this);
    });
  })
  .on("ajax:send", function(e, data) {
    selectedTabIndex = $form.find("li.active").index() + 1;
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

    animateSpinner(null, false);
  })
  .on("ajax:error", function(e, xhr, status, error) {
    $(this).after(xhr.responseJSON.html);
    var $form = $(this).next();
    $(this).remove();

    formCallback($form);
    initEditableHandsOnTable($form);
    applyCancelCallBack();
    formEditAjax($form);
    tabsPropagateErrorClass($form);

    //Rerender tables
    $form.find("[data-role='step-hot-table']").each(function()  {
      renderTable($(this));
    });

    // Select the same tab pane as before
    $form.find("ul.nav-tabs li.active").removeClass("active");
    $form.find(".tab-content div.active").removeClass("active");
    $form.find("ul.nav-tabs li:nth-child(" + selectedTabIndex + ")").addClass("active");
    $form.find(".tab-content div:nth-child(" + selectedTabIndex + ")").addClass("active");

    animateSpinner(null, false);
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

    animateSpinner(null, false);
  })
  .on("ajax:error", function(e, xhr, status, error) {
    $(this).after(xhr.responseJSON.html);
    var $form = $(this).next();
    $(this).remove();

    formCallback($form);
    formNewAjax($form);
    applyCancelOnNew();
    tabsPropagateErrorClass($form);

    animateSpinner(null, false);
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
function initStepCommentForm($el) {

  var $form = $el.find("ul form");

  $(".help-block", $form).addClass("hide");

  $form.on("ajax:send", function (data) {
    $("#comment_message", $form).attr("readonly", true);
  })
  .on("ajax:success", function (e, data) {
    if (data.html) {
      var list = $form.parents("ul");
      var s1 = data.html
      var id = s1.substring(s1.lastIndexOf("delete(")+7,s1.lastIndexOf(")'"))

      // Remove potential "no comments" element
      list.parent().find(".content-comments")
        .find("li.no-comments").remove();

      list.parent().find(".content-comments")
        .prepend("<li class='comment' id='"+id+"'>" + data.html + "</li>")
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

function comment_delete(id) {
  if (confirm('Are you sure you want to delete this comment?')) {
    $.ajax({
        type:   "POST",
        url:    '/protocols/delete_comment',
        dataType:   'json',
        data:     {id: id},
        success:  function (data) {
          $('.content-comments').find('#'+id).remove();  
      }
    });
  }

  return false;
}

function update_comment(id) {
  if (document.getElementById('edit_comment_'+id).type=='text') {
    var txt = document.getElementById('edit_comment_'+id).value;
    $.ajax({
        type:   "POST",
        url:    '/protocols/update_comment',
        dataType:   'json',
        data:     {id: id, msg: txt},
        success:  function (data) {
          document.getElementById('edit_comment_'+id).type='hidden';
          var txt = document.getElementById('edit_comment_'+id).value;
          $('#span_comment_'+id).text(txt);
          $('#span_comment_'+id).show();
      }
    });
  }
}

function comment_edit(id) {
  document.getElementById('edit_comment_'+id).type='text';
  $('#span_comment_'+id).hide();
  return false;
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
    posNameAttr = posNameAttr.replace(/\[\d+\]\[position\]/, "[" + itemId + "][position]");

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

// Needed because Paperclip deletes files on server-side validation fail (after trying to save the model)
function stepValidator( event ) {
  var nameTooShort = $( "#step_name" ).val().length === 0;
  var nameTooLong = $( "#step_name" ).val().length > 50;
  var errMsg;
  if (nameTooShort) {
    errMsg = I18n.t("devise.names.length_too_short");
    animateSpinner(null,false);
  } else if (nameTooLong) {
    errMsg = I18n.t("devise.names.length_too_long", { max_length: 50 });
    animateSpinner(null,false);
  }

  if (!_.isUndefined(errMsg)) {
    if(!$("#step_name_error_msg").length) {
      $("<span id='step_name_error_msg' class='help-block'>" + errMsg + "</span>").insertAfter("#step_name");
      $(".form-group:has(> #step_name)").addClass("has-error");
      $("#new-step-main-tab").addClass("has-error");
    } else {
      $("#step_name_error_msg").html(errMsg);
    }
    animateSpinner(null,false);
    $("#new-step-main-tab a").click();
    event.preventDefault();
  }

  clearBlankElements(event.target.form);
}

// Expand all steps
function expandAllSteps () {
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

// On init
initCallBacks();
initHandsOnTable($(document));
expandAllSteps();
setupAssetsLoading();

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

function renderTable(table) {
  $(table).handsontable("render");
  // Yet another dirty hack to solve HandsOnTable problems
  if (parseInt($(table).css("height"), 10) < parseInt($(table).css("max-height"), 10) - 30) {
    $(table).find(".ht_master .wtHolder").css("height", "100%");
  }
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
  clearBlankElements(form);

  function processFile () {
    var fileInput = fileInputs.get(inputPos);
    inputPos += 1;
    inputPointer += 1;

    if (!fileInput) {
      btn.onclick = null;
      $(btn).click();
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
      } else {
        tabsPropagateErrorClass($form);
      }
    });
  }

  processFile();
  ev.preventDefault();
}

// Clear empty fields in steps
function clearBlankElements(form) {
  // Remove empty checklist items
  $(form).find(".checklist-item-text").each(function () {
    if ($(this).val() === ""){
      $(this).closest("fieldset").remove();
    }
  });

  // Remove empty file forms
  $(form).find("input[type='file']").each(function () {
    if (!this.files[0]) {
      $(this).closest("fieldset").remove();
    }
  });
}

// This checks if the ctarget param exist in the
// rendered url and opens the comment tab
$(document).ready(function(){
  if( getParam('ctarget') ){
    var target = "#"+ getParam('ctarget');
    $(target).find('a.comment-tab-link').click();
  }
});
