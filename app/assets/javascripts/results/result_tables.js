// Init handsontable which can be edited
function initEditableHandsOnTable(root) {
  root.find(".editable-table").each(function() {
    var $container = $(this).find(".hot");
    var data = null;
    var contents = $(this).find('.hot-contents');
    if (contents.attr("value")) {
      data = JSON.parse(contents.attr("value")).data;
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
  });
}

function onSubmitExtractTable($form) {
  $form.submit(function(){
    var hot = $(".hot").handsontable('getInstance');
    var contents = $('.hot-contents');
    var data = JSON.stringify({data: hot.getData()});
    contents.attr("value", data);
    return true;
  });
}

// Edit result table button behaviour
function applyEditResultTableCallback() {
  $(".edit-result-table").on("ajax:success", function(e, data) {
    var $result = $(this).closest(".result");
    var $form = $(data.html);
    var $prevResult = $result;
    $result.after($form);
    $result.remove();

    formAjaxResultTable($form);
    initEditableHandsOnTable($form);
    onSubmitExtractTable($form);

    // Cancel button
    $form.find(".cancel-edit").click(function () {
      $form.after($prevResult);
      $form.remove();
      applyEditResultTableCallback();
      toggleResultEditButtons(true);
    });

    toggleResultEditButtons(false);

    $("#result_name").focus();
  });

  $(".edit-result-table").on("ajax:error", function(e, xhr, status, error) {
    //TODO: Add error handling
  });
}
// New result text behaviour
$("#new-result-table").on("ajax:success", function(e, data) {
  var $form = $(data.html);
  $("#results").prepend($form);

  formAjaxResultTable($form);
  initEditableHandsOnTable($form);
  onSubmitExtractTable($form);

  // Cancel button
  $form.find(".cancel-new").click(function () {
    $form.remove();
    toggleResultEditButtons(true);
  });

  toggleResultEditButtons(false);

  $("#result_name").focus();
});

$("#new-result-table").on("ajax:error", function(e, xhr, status, error) {
  //TODO: Add error handling
});

// Apply ajax callback to form
function formAjaxResultTable($form) {
  $form.on("ajax:success", function(e, data) {
    $form.after(data.html);
    $result = $(this).next();
    initFormSubmitLinks($result);
    $(this).remove();

    applyEditResultTableCallback();
    applyCollapseLinkCallBack();
    initHandsOnTables($result);
    toggleResultEditButtons(true);
    initResultCommentTabAjax();
    expandResult($result);
  });
  $form.on("ajax:error", function(e, xhr, status, error) {
    var data = xhr.responseJSON;
    $form.renderFormErrors("result", data);
  });
}

applyEditResultTableCallback();
