//= require datatables

// Create custom field ajax
$("#modal-create-custom-field").on("show.bs.modal", function(event) {
    // Clear input when modal is opened
    input = $(this).find("input#name-input");
    input.val("");
    input.closest(".form-group").removeClass("has-error");
    input.closest(".form-group").find(".help-block").remove();
});
$("#modal-create-custom-field").on("shown.bs.modal", function(event) {
    $(this).find("input#name-input").focus();
});

$("form#new_custom_field").on("ajax:success", function(ev, data, status) {
    $("#modal-create-custom-field").modal("hide");

    // Reload page with URL parameter of newly created field
    window.location.href = addParam(window.location.href, "new_col");
});

$("form#new_custom_field").on("ajax:error", function(e, data, status, xhr) {
    input = $(this).find("#name-input");
    input.closest(".form-group").find(".help-block").remove();
    input.closest(".form-group").addClass("has-error");

    $.each(data.responseJSON, function(i, val) {
        input.parent().append("<span class='help-block'>" + val[0].charAt(0).toUpperCase() + val[0].slice(1) +"<br /></span>");
    });
});

// Create sample type ajax
$("#modal-create-sample-type").on("show.bs.modal", function(event) {
    // Clear input when modal is opened
    input = $(this).find("input#name-input");
    input.val("");
    input.closest(".form-group").removeClass("has-error");
    input.closest(".form-group").find(".help-block").remove();
});

$("#modal-create-sample-type").on("shown.bs.modal", function(event) {
    $(this).find("input#name-input").focus();
});

$("form#new_sample_type").on("ajax:success", function(ev, data, status) {
    $("#modal-create-sample-type").modal("hide");
    updateSamplesTypesandGroups();
    sampleAlertMsg(data.flash, "success");
    currentMode = "viewMode";
    updateButtons();
});

$("form#new_sample_type").on("ajax:error", function(e, data, status, xhr) {
    input = $(this).find("#name-input");
    input.closest(".form-group").find(".help-block").remove();
    input.closest(".form-group").addClass("has-error");

    $.each(data.responseJSON, function(i, val) {
        input.parent().append("<span class='help-block'>" + val[0].charAt(0).toUpperCase() + val[0].slice(1) +"<br /></span>");
    });
});

// Create sample group ajax
$("#modal-create-sample-group").on("show.bs.modal", function(event) {
    // Clear input when modal is opened
    input = $(this).find("input#name-input");
    input.val("");
    input.closest(".form-group").removeClass("has-error");
    input.closest(".form-group").find(".help-block").remove();
});

$("#modal-create-sample-group").on("shown.bs.modal", function(event) {
    $(this).find("input#name-input").focus();
});

$("form#new_sample_group").on("ajax:success", function(ev, data, status) {
    $("#modal-create-sample-group").modal("hide");
    updateSamplesTypesandGroups();
    sampleAlertMsg(data.flash, "success");
    currentMode = "viewMode";
    updateButtons();
});

$("form#new_sample_group").on("ajax:error", function(e, data, status, xhr) {
    input = $(this).find("#name-input");
    input.closest(".form-group").find(".help-block").remove();
    input.closest(".form-group").addClass("has-error");

    $.each(data.responseJSON, function(i, val) {
        input.parent().append("<span class='help-block'>" + val[0].charAt(0).toUpperCase() + val[0].slice(1) +"<br /></span>");
    });
});


// Create import samples ajax
$("#modal-import-samples").on("show.bs.modal", function(event) {
    formGroup = $(this).find(".form-group");
    formGroup.removeClass("has-error");
    formGroup.find(".help-block").remove();
});

$("form#form-samples-file")
.on("ajax:success", function(ev, data, status) {
  $("#modal-parse-samples").html(data.html);
  $("#modal-import-samples").modal("hide");
  $("#modal-parse-samples").modal("show");
})
.on("ajax:error", function(ev, data, status) {
  $(this).find(".form-group").addClass("has-error");
  $(this).find(".form-group").find(".help-block").remove();
  $(this).find(".form-group").append("<span class='help-block'>" + data.responseJSON.message + "</span>");
});

// Fetch samples data and updates the select options fields for
// sample group and sample type column
function updateSamplesTypesandGroups() {
  changeToEditMode();
  updateButtons();

  $.ajax({
    url: $("table#samples").data("new-sample"),
    type: "GET",
    dataType: "json",
    success: function (data) {
      $("select[name=sample_group_id]").each(function(){
        var sample_group = $(this).val();
        var selectGroup = createSampleGroupSelect(data.sample_groups, sample_group);
        var gtd = $(this).parent("td");
        gtd.html(selectGroup[0]);
      });
      $("select[name=sample_type_id]").each(function(){
        var sample_type = $(this).val();
        var selectType = createSampleTypeSelect(data.sample_types, sample_type);
        var ttd = $(this).parent("td");
        ttd.html(selectType[0]);
      });

      $("select[name=sample_group_id]").selectpicker();
      $("select[name=sample_type_id]").selectpicker();
    },
    error: function (e, eData, status, xhr) {
      if (e.status == 403)
        showAlertMessage(I18n.t("samples.js.permission_error"));
        changeToViewMode();
        updateButtons();
      }
    });
}

function sampleAlertMsg(message, type) {
  var alertType, glyphSign;
  if (type == 'success') {
    alertType = ' alert-success ';
    glyphSign = ' glyphicon-ok-sign ';
  } else if (type == 'danger') {
    alertType = ' alert-danger ';
    glyphSign = ' glyphicon-exclamation-sign ';
  }
  var htmlSnippet = '<div class="alert' + alertType + 'alert-dismissable alert-floating">' +
                      '<div class="container">' +
                        '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">×</span></button>' +
                          '<span class="glyphicon' + glyphSign + '"></span>' +
                          '<span>'+ message +'</span>' +
                        '</div>' +
                      '</div>';
  $('#notifications').html(htmlSnippet);
  $('#content-wrapper').addClass('alert-shown');
}

function sampleAlertMsgHide() {
  $('#notifications').html('<div></div>');
  $('#content-wrapper').removeClass('alert-shown');
}

function initTutorial() {
  var currentStep = parseInt(Cookies.get('current_tutorial_step'), 10);
  if (currentStep == 8)
    currentStep++;
  if (showTutorial() && (currentStep > 12 &&  currentStep < 16)) {
    var samplesTutorial =$("#samples-toolbar").attr("data-samples-step-text");
    var breadcrumbsTutorial = $("#samples-toolbar").attr("data-breadcrumbs-step-text");

    introJs()
      .setOptions({
        steps: [
          {
            element: document.getElementById("importSamplesButton"),
            intro: samplesTutorial
          },
          {
            element: document.getElementById("secondary-menu"),
            intro: breadcrumbsTutorial,
            tooltipClass: 'custom next-page-link',
          }
        ],
        overlayOpacity: '0.1',
        nextLabel: 'Next',
        doneLabel: 'End tutorial',
        skipLabel: 'End tutorial',
        showBullets: false,
        showStepNumbers: false,
        exitOnOverlayClick: false,
        exitOnEsc: false,
        disableInteraction: true,
        tooltipClass: "custom"
      })
      .onafterchange(function (tarEl) {
        Cookies.set('current_tutorial_step', this._currentStep + 14);

        if (this._currentStep == 1) {
          setTimeout(function() {
            $('.next-page-link a.introjs-nextbutton')
              .removeClass('introjs-disabled')
              .attr('href', $("#reports-nav-tab a").attr('href'));
            $('.introjs-disableInteraction').remove();
            positionTutorialTooltip();
          }, 500);
        } else {
          positionTutorialTooltip();
        }
      })
      .goToStep(currentStep == 15 ? 2 : 1)
      .start();

    // Destroy first-time tutorial cookies when skip tutorial
    // or end tutorial is clicked
    $(".introjs-skipbutton").each(function (){
      $(this).click(function (){
        Cookies.remove('tutorial_data');
        Cookies.remove('current_tutorial_step');
        restore_after_tutorial();
      });
    });
  }
}

function positionTutorialTooltip() {
  if (Cookies.get('current_tutorial_step') == 13) {
    if ($("#reports-nav-tab").offset().left == 0) {
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
  var currentModuleId = $("#samples-toolbar").attr("data-module-id");
  return tutorialModuleId == currentModuleId;
}

function samples_tutorial_helper(){
    if( $('div').hasClass('introjs-overlay') ){
      $.each( $('#secondary-menu').find('a'), function(){
        $(this).css({ 'pointer-events': 'none' });
      });
    }
}

function restore_after_tutorial(){
  $.each( $('#secondary-menu').find('a'), function(){
    $(this).css({ 'pointer-events': 'auto' });
  });
}
// Initialize first-time tutorial
initTutorial();
samples_tutorial_helper();
