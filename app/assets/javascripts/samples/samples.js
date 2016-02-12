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


function initTutorial() {
  var currentStep = parseInt(Cookies.get('current_tutorial_step'));
  if (currentStep == 8)
    currentStep++;
  if (showTutorial() && currentStep == 9 || currentStep == 10) {
    var samplesTutorial =$("#samples-toolbar").attr("data-samples-step-text");
    var breadcrumbsTutorial = $("#samples-toolbar").attr("data-breadcrumbs-step-text");

    introJs()
      .setOptions({
        steps: [
          {
            element: document.getElementById("samples-toolbar"),
            intro: samplesTutorial,
            tooltipClass: 'custom'
          },
          {
            element: document.getElementById("secondary-menu"),
            intro: breadcrumbsTutorial,
            tooltipClass: 'custom disabled-next'
          }
        ],
        overlayOpacity: '0.1',
        nextLabel: 'Next',
        doneLabel: 'End tutorial',
        skipLabel: 'End tutorial',
        showBullets: false,
        showStepNumbers: false,
        disableInteraction: true
      })
      .goToStep(currentStep - 8)
      .onafterchange(function (tarEl) {
        Cookies.set('current_tutorial_step', this._currentStep + 9);

        // Disable interaction only for first step (dirty hack)
        if (this._currentStep)
          $('.introjs-disableInteraction').remove();
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
  var currentModuleId = $("#samples-toolbar").attr("data-module-id");
  return tutorialModuleId == currentModuleId;
}

// Initialize first-time tutorial
initTutorial();