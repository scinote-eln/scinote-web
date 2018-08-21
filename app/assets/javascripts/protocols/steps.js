//= require handsontable.full.min
//= require Sortable.min
//= require canvas-to-blob.min
//= require assets
//= require comments

(function(global) {
  'use strict';

  // Sets callbacks for toggling checkboxes
  function applyCheckboxCallBack()  {
    $("[data-action='check-item']").off().on('click', function(e){
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

  // Complete mymodule
  function complete_my_module_actions() {
    var modal = $('#completed-task-modal');

    modal.find('[data-action="complete"]')
         .off().on().click(function(event) {
        event.stopPropagation();
        event.preventDefault();
        event.stopImmediatePropagation();
        $.ajax({
          url: modal.data('url'),
          type: 'GET',
          success: function(data) {
            var task_button = $("[data-action='complete-task']");
            task_button.attr('data-action', 'uncomplete-task');
            task_button.find('.btn')
              .removeClass('btn-toggle').addClass('btn-default');
            $('.task-due-date').html(data.module_header_due_date_label);
            $('.task-state-label').html(data.module_state_label);
            task_button
              .find('button')
              .html('<span class="fas fa-times"></span>&nbsp;' +
                    data.task_button_title);
            modal.modal('hide');
          },
          error: function() {
            modal.modal('hide');
          }
        });
      });
  }

  // Sets callback for completing/uncompleting step
  function applyStepCompletedCallBack() {
    // First, remove old event handlers, as we use turbolinks
    $("[data-action='complete-step'], [data-action='uncomplete-step']")
    .off().on('click', function(e){
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
            button.find(".btn").removeClass("btn-toggle").addClass("btn-default");
            button.find("button").html('<span class="fas fa-times"></span>&nbsp;' + data.new_title);

            if (data.task_ready_to_complete) {
              $('#completed-task-modal').modal('show');
              complete_my_module_actions();
            }
          }
          else {
            step.addClass("not-completed").removeClass("completed");

            button = step.find("[data-action='uncomplete-step']");
            button.attr("data-action", "complete-step");
            button.find(".btn").removeClass("btn-default").addClass("btn-toggle");
            button.find("button").html('<span class="fas fa-check"></span>&nbsp;' + data.new_title);
          }
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

      setTimeout(function() {
        initStepsComments();
        initPreviewModal();
        SmartAnnotation.preventPropagation('.atwho-user-popover');
        TinyMCE.destroyAll();
        DragNDropSteps.clearFiles();
      }, 1000);

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
      animateSpinner(null, false);
      initPreviewModal();
      DragNDropSteps.clearFiles();
      TinyMCE.refresh();
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
    $("[data-action='move-step']").off("ajax:success");
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
        collapseIcon.toggleClass("fa-caret-square-up", !collapsed);
        collapseIcon.toggleClass("fa-caret-square-down", collapsed);

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
      initPreviewModal();

      TinyMCE.destroyAll();
      SmartAnnotation.preventPropagation('.atwho-user-popover');
      // Show the edited step
      $new_step.find(".panel-collapse:first").addClass("collapse in");

      //Rerender tables
      $new_step.find("[data-role='step-hot-table']").each(function()  {
        renderTable($(this));
      });
      setupAssetsLoading();
    })
    .on("ajax:error", function(e, xhr, status, error) {
      $form.renderFormErrors('step', xhr.responseJSON, true, e);

      formCallback($form);
      initEditableHandsOnTable($form);
      applyCancelCallBack();

      TinyMCE.refresh();
      SmartAnnotation.preventPropagation('.atwho-user-popover');

      //Rerender tables
      $form.find("[data-role='step-hot-table']").each(function()  {
        renderTable($(this));
      });
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
        startRows: $("#const_data").attr('data-HANDSONTABLE_INIT_ROWS_CNT'),
        startCols: $("#const_data").attr('data-HANDSONTABLE_INIT_COLS_CNT'),
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
        startRows: $("#const_data").attr('data-HANDSONTABLE_INIT_ROWS_CNT'),
        startCols: $("#const_data").attr('data-HANDSONTABLE_INIT_COLS_CNT'),
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

  function applyCancelOnNew() {
    $("[data-action='cancel-new']").click(function(event) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();

      var $form = $(this).closest("form");
      $form.parent().remove().promise().done(function() {
        newStepHandler();
      });
      toggleButtons(true);
      DragNDropSteps.clearFiles();
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
    initDeleteStep();
    TinyMCE.highlight();
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
      handle: '.fa-circle',
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
  function newStepHandler() {
    $("[data-action='new-step']").off().on('click', function(event) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
      var $btn = $(this);
      $btn.off();
      animateSpinner(null, true);

      $.ajax({
        url: $btn.data('href'),
        method: 'GET',
        success: function(data) {
          var $form = $(data.html);
          $('#steps').append($form).promise().done(function() {
            animateSpinner(null, false);
            // Scroll to bottom
            $('html, body').animate({
              scrollTop: $(document).height() - $(window).height()
            });
            formCallback($form);
            applyCancelOnNew();
            toggleButtons(false);
            initializeCheckboxSorting();

            $('#step_name').focus();
            $('#new-step-main-tab a').on('shown.bs.tab', function() {
              $('#step_name').focus();
            });

            TinyMCE.refresh();
          });

        },
        error: function() {
          newStepHandler();
        }
      })
    });
  }

  // Needed because server-side validation failure clears locations of
  // files to be uploaded and checklist's items etc. Also user
  // experience is improved
  global.processStep = function processStep(ev, editMode) {
    ev.stopPropagation();
    ev.preventDefault();
    ev.stopImmediatePropagation();

    var $form = $(ev.target.form);
    $form.clearFormErrors();
    $form.removeBlankFileForms();

    var $checklists = $form.find(".nested_step_checklists");
    var checklistsValid = checklistsValidator(ev, $checklists, editMode);
    var $nameInput = $form.find("#step_name");
    var nameValid = textValidator(ev, $nameInput, 1,
      $("#const_data").attr('data-NAME_MAX_LENGTH'));
    var $descrTextarea = $form.find("#step_description");
    var $tinyMCEInput = TinyMCE.getContent();
    var descriptionValid = textValidator(ev, $descrTextarea, 0,
      $("#const_data").attr('data-TEXT_MAX_LENGTH'), false, $tinyMCEInput);

    if (DragNDropSteps.filesStatus() &&
        checklistsValid &&
        nameValid &&
        descriptionValid) {

      $form.find("[data-role='editable-table']").each(function() {
        var hot = $(this).find(".hot").handsontable('getInstance');
        var contents = $(this).find('.hot-contents');
        var data = JSON.stringify({data: hot.getData()});
        contents.attr("value", data);
      });

      setTimeout(function() {
        initStepsComments();
        SmartAnnotation.preventPropagation('.atwho-user-popover');
      }, 1000);

      animateSpinner(null, true);
      var data = DragNDropSteps.appendFilesToForm(ev);
      data.append('step[description]', TinyMCE.getContent());
      $.ajax({
        url: $form.attr('action'),
        method: 'POST',
        data: data,
        contentType: false,
        processData: false,
        beforeSend: function() {
          $(".nested_step_checklists ul").each(function () {
            reorderCheckboxData(this);
          });
        },
        success: function(data) {
          $($form.closest('.well')).after(data.html);
          var $new_step = $($form.closest('.well')).next();
          $($form.closest('.well')).remove();

          initCallBacks();
          initHandsOnTable($new_step);
          expandStep($new_step);
          toggleButtons(true);
          SmartAnnotation.preventPropagation('.atwho-user-popover');

          //Rerender tables
          $new_step.find("div.step-result-hot-table").each(function()  {
            $(this).handsontable("render");
          });
          animateSpinner(null, false);
          setupAssetsLoading();
          DragNDropSteps.clearFiles();
          initPreviewModal();
        },
        error: function(xhr) {
          if (xhr.responseJSON['assets.file']) {
            $('#new-step-assets-group').addClass('has-error');
            $('#new-step-assets-tab').addClass('has-error');
            $.each(xhr.responseJSON['assets.file'], function(_, value) {
               $('#new-step-assets-group').prepend('<span class="help-block">' + value + '</span>');
            });
          }
          animateSpinner(null, false);
          SmartAnnotation.preventPropagation('.atwho-user-popover');
        }
      });
      newStepHandler();
    }
  }

  // Expand all steps
  function expandAllSteps() {
    $('.step .panel-collapse').collapse('show');
    $(document).find("[data-role='step-hot-table']").each(function()  {
      renderTable($(this));
    });
    $(document).find("span.collapse-step-icon").each(function()  {
      $(this).addClass("fa-caret-square-up");
      $(this).removeClass("fa-caret-square-down");
    });
  }

  function expandStep(step) {
    $('.panel-collapse', step).collapse('show');
    $(step).find("span.collapse-step-icon")
      .addClass("fa-caret-square-up")
      .removeClass("fa-caret-square-down");
    $(step).find("div.step-result-hot-table").each(function()  {
      renderTable($(this));
    });
  }

  function renderTable(table) {
    $(table).handsontable("render");
    // Yet another dirty hack to solve HandsOnTable problems
    if (parseInt($(table).css('height'), 10) < parseInt($(table).css('max-height'), 10) - 30) {
      $(table).find('.ht_master .wtHolder').css({ 'height': '100%',
                                                  'width': '100%' });
    }
  }

  function initStepsComments() {
    Comments.initialize();
    Comments.initCommentOptions("ul.content-comments");
    Comments.initEditComments("#steps");
    Comments.initDeleteComments("#steps");
  }

  // On init
  initCallBacks();
  initHandsOnTable($(document));
  expandAllSteps();
  setupAssetsLoading();
  initStepsComments();
  initPreviewModal();
  TinyMCE.highlight();
  SmartAnnotation.preventPropagation('.atwho-user-popover');
  newStepHandler();

  $(function () {
    $("[data-action='collapse-steps']").click(function () {
      $('.step .panel-collapse').collapse('hide');
      $(document).find("span.collapse-step-icon").each(function()  {
        $(this).addClass("fa-caret-square-down");
        $(this).removeClass("fa-caret-square-up");
      });
    });
    $("[data-action='expand-steps']").click(expandAllSteps);
  });

  global.initHandsOnTable = initHandsOnTable;
})(window);
