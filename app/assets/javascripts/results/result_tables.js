// Init handsontable which can be edited
function initEditableHandsOnTable(root) {
  root.find(".editable-table").each(function() {
    var $container = $(this).find(".hot");

    $container.handsontable({
      startRows: 5,
      startCols: 5,
      rowHeaders: true,
      colHeaders: true,
      contextMenu: true
    });
    var hot = $(this).find(".hot").handsontable('getInstance');
    var contents = $(this).find('.hot-contents');
    if (contents.attr("value")) {
      var data = JSON.parse(contents.attr("value"));
      hot.loadData(data.data);
    }
  });
}

function onSubmitExtractTable($form) {
  $form.submit(function(){
    var hot = $(".hot").handsontable('getInstance');
    var contents = $('.hot-contents');
    var data = JSON.stringify({data: hot.getData()});
    contents.attr("value", data)
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
    initHandsOnTables($result);
    toggleResultEditButtons(true);
    initResultCommentTabAjax();
    expandResult($result);
    initHandsOnTables($result);
  });
  $form.on("ajax:error", function(e, xhr, status, error) {
    var data = xhr.responseJSON;
    $form.render_form_errors("result", data);
  });
}

applyEditResultTableCallback();
