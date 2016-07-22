// New result asset behaviour
$("#new-result-asset").on("ajax:success", function(e, data) {
  var $form = $(data.html);
  $("#results").prepend($form);

  $form.files_validator();
  formAjaxResultAsset($form);

  // Cancel button
  $form.find(".cancel-new").click(function () {
    $form.remove();
    toggleResultEditButtons(true);
  });

  toggleResultEditButtons(false);

  $("#result_name").focus();
});

$("#new-result-asset").on("ajax:error", function(e, xhr, status, error) {
  //TODO: Add error handling
});

// Edit result asset button behaviour
function applyEditResultAssetCallback() {
  $(".edit-result-asset").on("ajax:success", function(e, data) {
    var $result = $(this).closest(".result");
    var $form = $(data.html);
    var $prevResult = $result;
    $result.after($form);
    $result.remove();

    $form.files_validator();
    formAjaxResultAsset($form);

    // Cancel button
    $form.find(".cancel-edit").click(function () {
      $form.after($prevResult);
      $form.remove();
      applyEditResultAssetCallback();
      toggleResultEditButtons(true);
    });

    toggleResultEditButtons(false);

    $("#result_name").focus();
  });

  $(".edit-result-asset").on("ajax:error", function(e, xhr, status, error) {
    //TODO: Add error handling
  });
}

function showResultFormErrors($form, errors) {
  $form.render_form_errors("result", errors);

  if (errors["asset.file"]) {
  var $el = $form.find("input[type=file]");

  $el.closest(".form-group").addClass("has-error");
  $el.parent().append("<span class='help-block'>" + errors["asset.file"] + "</span>");
  }
}

// Apply ajax callback to form
function formAjaxResultAsset($form) {
  $form
  .on("ajax:success", function(e, data) {

    if (data.status === "ok") {
      $form.after(data.html);
      var newResult = $form.next();
      initFormSubmitLinks(newResult);
      $(this).remove();
      applyEditResultAssetCallback();
      applyCollapseLinkCallBack();
      toggleResultEditButtons(true);
      initResultCommentTabAjax();
      expandResult(newResult);

    } else if (data.status === 'error') {
      showResultFormErrors($form, data.errors);
    }
    animateSpinner(null, false);
  })
  .on("ajax:error", function() {
    animateSpinner(null, false);
  });
}


applyEditResultAssetCallback();
