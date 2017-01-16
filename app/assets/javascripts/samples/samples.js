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

/**
 * Initializes tutorial
 */
function initTutorial() {
  var stepNum = parseInt(Cookies.get('current_tutorial_step'), 10);
  if (stepNum >= 17 && stepNum <= 18) {
    var nextPage = $('#reports-nav-tab a').attr('href');
    var steps = [{
      element: $('#importSamplesButton')[0],
      intro: $('#samples-toolbar').attr('data-samples-step-text'),
      position: 'right'
    }, {
      element: $('#secondary-menu')[0],
      intro: $('#samples-toolbar').attr('data-breadcrumbs-step-text')
    }];
    initPageTutorialSteps(17, 18, nextPage,
                          function() {}, function() {}, steps);
  }
}

initTutorial();
