(function() {
  'use strict';

  $('.delete-repo-option').initializeModal('#delete-repo-modal');
  $('.rename-repo-option').initializeModal('#rename-repo-modal');
})();

// create new
function init() {
  initCreateNewModal();
}

function initCreateNewModal() {
  var link = $("[data-action='create-new-repository']");
  var modal = $("#create-new-modal");
  var submitBtn = modal.find(".modal-footer [data-action='submit']");

  link.on("click", function() {
    $.ajax({
      url: link.attr("data-url"),
      type: "GET",
      dataType: "json",
      success: function (data) {
        var modalBody = modal.find(".modal-body");
        modalBody.html(data.html);

        modalBody.find("form")
        .on("ajax:success", function(ev2, data2, status2) {
          // Redirect to index page
          $(location).attr("href", data2.url);
        })
        .on("ajax:error", function(ev2, data2, status2) {
          // Display errors if needed
          $(this).renderFormErrors("repository", data2.responseJSON);
        });

        modal.modal("show");
        modalBody.find("input[type='text']").focus();
      },
      error: function (error) {
        // TODO
      }
    });
  });

  submitBtn.on("click", function() {
    // Submit the form inside modal
    $(this).closest(".modal").find(".modal-body form").submit();
  });

  modal.on("hidden.bs.modal", function(e) {
    modal.find(".modal-body form").off("ajax:success ajax:error");
    modal.find(".modal-body").html("");
  });
}

init();
