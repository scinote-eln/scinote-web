//= require comments

function initHandsOnTables(root) {
  root.find("div.hot-table").each(function()  {
    var $container = $(this).find(".step-result-hot-table");
    var contents = $(this).find('.hot-contents');

    $container.handsontable({
      width: '100%',
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
    var data = JSON.parse(contents.attr("value"));
    hot.loadData(data.data);

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

      // Reposition dropdown comment options
      scrollCommentOptions(listItem.closest(".content-comments").find(".dropdown-comment"));
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

function applyCollapseLinkCallBack() {
  $(".result-panel-collapse-link")
    .on("ajax:success", function() {
      var collapseIcon = $(this).find(".collapse-result-icon");
      var collapsed = $(this).hasClass("collapsed");
      // Toggle collapse button
      collapseIcon.toggleClass("glyphicon-collapse-up", !collapsed);
      collapseIcon.toggleClass("glyphicon-collapse-down", collapsed);
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
  $(document).find("span.collapse-result-icon").each(function()  {
    $(this).addClass("glyphicon-collapse-up");
    $(this).removeClass("glyphicon-collapse-down");
  });
  $(document).find("div.step-result-hot-table").each(function()  {
    renderTable(this);
  });
}

function expandResult(result) {
  $('.panel-collapse', result).collapse('show');
  $(result).find("span.collapse-result-icon").each(function()  {
    $(this).addClass("glyphicon-collapse-up");
    $(this).removeClass("glyphicon-collapse-down");
  });
  renderTable($(result).find("div.step-result-hot-table"));
}

function renderTable(table) {
  $(table).handsontable("render");
  // Yet another dirty hack to solve HandsOnTable problems
  if (parseInt($(table).css("height"), 10) < parseInt($(table).css("max-height"), 10) - 30) {
    $(table).find(".ht_master .wtHolder").css({ 'height': '100%',
                                                 'width': '100%' });
  }
}

// Initialize first-time tutorial
function initTutorial() {
  var currentStep = Cookies.get('current_tutorial_step');
  if (showTutorial() && (currentStep > 10 &&  currentStep < 14)) {
    var moduleResultsTutorial = $("#results").attr("data-module-protocols-step-text");
    var moduleResultsClickSamplesTutorial = $("#results").attr("data-module-protocols-click-samples-step-text");
    var samplesTab = $("#module-samples-nav-tab");

    introJs()
      .setOptions({
        steps: [
          {
            element: document.getElementById("results-toolbar"),
            intro: moduleResultsTutorial,
            disableInteraction: true
          },
          {
            element: samplesTab[0],
            intro: moduleResultsClickSamplesTutorial,
            tooltipClass: 'custom next-page-link'
          }
        ],
        overlayOpacity: '0.1',
        doneLabel: 'End tutorial',
        skipLabel: 'End tutorial',
        nextLabel: 'Next',
        showBullets: false,
        showStepNumbers: false,
        exitOnOverlayClick: false,
        exitOnEsc: false,
        tooltipClass: 'custom',
        disableInteraction: true
      })
      .onafterchange(function (tarEl){
        Cookies.set('current_tutorial_step', this._currentStep + 12);
        if (this._currentStep == 1) {
          setTimeout(function() {
            $('.next-page-link a.introjs-nextbutton')
              .removeClass('introjs-disabled')
              .attr('href', samplesTab.find("a").attr('href'));

            $(".introjs-disableInteraction").remove();
            positionTutorialTooltip();
          }, 500);
        } else {
          positionTutorialTooltip();
        }
      })
      .goToStep(currentStep == 13 ? 2 : 1)
      .start();

    window.onresize = positionTutorialTooltip;

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

function positionTutorialTooltip() {
  if (Cookies.get('current_tutorial_step') == 13) {
    if ($("#module-samples-nav-tab").offset().left == 0) {
      $(".introjs-tooltip").css("left", (window.innerWidth / 2 - 50)  + "px");
      $(".introjs-tooltip").addClass("repositioned");
    } else if ($(".introjs-tooltip").hasClass("repositioned")) {
      $(".introjs-tooltip").css("left", "");
      $(".introjs-tooltip").removeClass("repositioned");
    }
  } else {
    if ($(".introjs-tooltip").offset().left > window.innerWidth) {
      $(".introjs-tooltip").css("left", (window.innerWidth / 2 - 50)  + "px");
      $(".introjs-tooltip").addClass("repositioned");
    } else if ($(".introjs-tooltip").hasClass("repositioned")) {
      $(".introjs-tooltip").css("left", "");
      $(".introjs-tooltip").removeClass("repositioned");
    }
  }
};

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

var ResultTypeEnum = Object.freeze({
  FILE: 0,
  TABLE: 1,
  TEXT: 2,
  COMMENT: 3
});

function processResult(ev, resultTypeEnum, editMode, forS3) {
  forS3 = (typeof forS3 !== 'undefined') ? forS3 : false;
  var $form = $(ev.target.form);
  $form.clearFormErrors();

  switch(resultTypeEnum) {
    case ResultTypeEnum.FILE:
      var $nameInput = $form.find("#result_name");
      var nameValid = textValidator(ev, $nameInput, true);
      var $fileInput = $form.find("#result_asset_attributes_file");
      var filesValid = filesValidator(ev, $fileInput, FileTypeEnum.FILE, editMode);

      if(nameValid && filesValid) {
        if(forS3) {
          // Redirects file uploading to S3
          var url = '/asset_signature.json';
          directUpload(ev, url);
        } else {
          // Local file uploading
          animateSpinner();
        }
      }
      break;
    case ResultTypeEnum.TABLE:
      var $nameInput = $form.find("#result_name");
      var nameValid = textValidator(ev, $nameInput, true);
      break;
    case ResultTypeEnum.TEXT:
      var $nameInput = $form.find("#result_name");
      var nameValid = textValidator(ev, $nameInput, true);
      var $textInput = $form.find("#result_result_text_attributes_text");
      textValidator(ev, $textInput, false, false);
      break;
    case ResultTypeEnum.COMMENT:
      var $commentInput = $form.find("#comment_message");
      var commentValid = textValidator(ev, $commentInput, false, false);
      break;
  }
}

// This checks if the ctarget param exist in the
// rendered url and opens the comment tab
$(document).ready(function(){
  initHandsOnTables($(document));
  initResultCommentTabAjax();
  expandAllResults();
  initTutorial();
  applyCollapseLinkCallBack();

  initCommentOptions("ul.content-comments");
  initEditComments("#results");
  initDeleteComments("#results");

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

  if( getParam('ctarget') ){
    var target = "#"+ getParam('ctarget');
    $(target).find('a.comment-tab-link').click();
  }
});
