function initHandsOnTables(root) {
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
    var data = JSON.parse(contents.attr("value"));
    hot.loadData(data.data);

     $(".result-panel-collapse-link")
    .on("ajax:success", function() {
      var collapseIcon = $(this).find(".collapse-result-icon");

      // Toggle collapse button
      collapseIcon.toggleClass("glyphicon-collapse-up");
      collapseIcon.toggleClass("glyphicon-collapse-down");
      root.find("div.step-result-hot-table").each(function()  {
        $(this).handsontable("render");
      });
    });
  });
}

// Initialize comment form.
function initResultCommentForm($el) {

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
function initResultCommentsLink($el) {

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

function initResultCommentTabAjax() {
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
      initResultCommentForm(parentNode);
      initResultCommentsLink(parentNode);

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

// Toggle editing buttons
function toggleResultEditButtons(show) {
  if (show) {
    $("#results-toolbar").show();
    $(".edit-result-button").show();
  } else {
    $(".edit-result-button").hide();
    $("#results-toolbar").hide();
  }
}

// Expand all results
function expandAllResults() {
  $('.result .panel-collapse').collapse('show');
  $(document).find("div.step-result-hot-table").each(function()  {
    $(this).handsontable("render");
  });
  $(document).find("span.collapse-result-icon").each(function()  {
    $(this).addClass("glyphicon-collapse-up");
    $(this).removeClass("glyphicon-collapse-down");
  });
}

function expandResult(result) {
  $('.panel-collapse', result).collapse('show');
  $(result).find("span.collapse-result-icon").each(function()  {
    $(this).addClass("glyphicon-collapse-up");
    $(this).removeClass("glyphicon-collapse-down");
  });
}


initHandsOnTables($(document));
initResultCommentTabAjax();
expandAllResults();
initTutorial();

$(function () {
  $("#results-collapse-btn").click(function () {
    $('.result .panel-collapse').collapse('hide');
    $(document).find("span.collapse-result-icon").each(function()  {
      $(this).addClass("glyphicon-collapse-down");
      $(this).removeClass("glyphicon-collapse-up");
    });
  });

  $("#results-expand-btn").click(expandAllResults);
});

// Initialize first-time tutorial
function initTutorial() {
  var currentStep = Cookies.get('current_tutorial_step');
  if (showTutorial() && (currentStep == '7' || currentStep == '8')) {
    var moduleResultsTutorial = $("#results").attr("data-module-protocols-step-text");
    Cookies.set('current_tutorial_step', '8');

    introJs()
      .setOptions({
        steps: [{
          element: document.getElementById("results-toolbar"),
          intro: moduleResultsTutorial
        }],
        overlayOpacity: '0.1',
        doneLabel: 'End tutorial',
        showBullets: false,
        showStepNumbers: false,
        tooltipClass: 'custom disabled-next',
        disableInteraction: true
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
  var currentModuleId = $("#results").attr("data-module-id");
  return tutorialModuleId == currentModuleId;
}

// S3 direct uploading
function startFileUpload(ev, btn) {
  var form = btn.form;
  var $form = $(form);
  var assetInput = $form.find("input[name='result[asset_attributes][id]']").get(0);
  var fileInput = $form.find("input[type=file]").get(0);
  var origAssetId = assetInput ? assetInput.value : null;
  var url = '/asset_signature.json';

  $form.clear_form_errors();
  animateSpinner($form);

  directUpload(form, origAssetId, url, function (assetId) {
    // edit mode - input field has to be removed
    animateSpinner($form, false);
    if (assetInput) {
      assetInput.value = assetId;
      $(fileInput).remove();

    // create mode
    } else {
      fileInput.type = "hidden";
      fileInput.name = "result[asset_attributes][id]";
      fileInput.value = assetId;
    }

    btn.onclick = null;
    $(btn).click();

  }, function (errors) {
    animateSpinner($form, false);
    showResultFormErrors($form, errors);
  });

  ev.preventDefault();
}
