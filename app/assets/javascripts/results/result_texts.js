// New result text behaviour
$("#new-result-text").on("ajax:success", function(e, data) {
    var $form = $(data.html);
    $("#results").prepend($form);

    formAjaxResultText($form);

    // Cancel button
    $form.find(".cancel-new").click(function () {
        $form.remove();
        toggleResultEditButtons(true);
    });

    toggleResultEditButtons(false);

    $("#result_name").focus();
});

$("#new-result-text").on("ajax:error", function(e, xhr, status, error) {
    //TODO: Add error handling
});

// Edit result text button behaviour
function applyEditResultTextCallback() {
    $(".edit-result-text").on("ajax:success", function(e, data) {
        var $result = $(this).closest(".result");
        var $form = $(data.html);
        var $prevResult = $result;
        $result.after($form);
        $result.remove();

        formAjaxResultText($form);

        // Cancel button
        $form.find(".cancel-edit").click(function () {
            $form.after($prevResult);
            $form.remove();
            applyEditResultTextCallback();
            toggleResultEditButtons(true);
        });

        toggleResultEditButtons(false);

        $("#result_name").focus();
    });

    $(".edit-result-text").on("ajax:error", function(e, xhr, status, error) {
        //TODO: Add error handling
    });
}

// Apply ajax callback to form
function formAjaxResultText($form) {
    $form.on("ajax:success", function(e, data) {
        $form.after(data.html);
        var newResult = $form.next();
        initFormSubmitLinks(newResult);
        $(this).remove();

        applyEditResultTextCallback();
        applyCollapseLinkCallBack();
        toggleResultEditButtons(true);
        expandResult(newResult);
        initHighlightjs();
    });
    $form.on("ajax:error", function(e, xhr, status, error) {
        var data = xhr.responseJSON;
        $form.renderFormErrors("result", data);
        initHighlightjs();
        if (data["result_text.text"]) {
            var $el = $form.find("textarea[name=result\\[result_text_attributes\\]\\[text\\]]");

            $el.closest(".form-group").addClass("has-error");
            $el.parent().append("<span class='help-block'>" + data["result_text.text"] + "</span>");
        }
    });
}


function initHighlightjs() {
  if(hljs) {
    $('.ql-editor pre').each(function(i, block) {
     hljs.highlightBlock(block);
   });
  }
}
$(document).ready(function() {
  initHighlightjs();
});
applyEditResultTextCallback();
