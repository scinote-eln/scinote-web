function initLeaveOrganizations() {
  // Bind the "leave organization" buttons in organizations table
  $(document)
  .on(
    "ajax:success",
    "[data-action='leave-user-organization']",
    function (e, data, status, xhr) {
      // Populate the modal heading & body
      var modal = $("#modal-leave-user-organization");
      var modalHeading = modal.find(".modal-header").find(".modal-title");
      var modalBody = modal.find(".modal-body");
      modalHeading.text(data.heading);
      modalBody.html(data.html);

      // Show the modal
      modal.modal("show");
    }
  )
  .on(
    "ajax:error",
    "[data-action='destroy-user-organization']",
    function (e, data, status, xhr) {
      // TODO
    }
  );

  // Also, bind the click action on the modal
  $("#modal-leave-user-organization")
  .on("click", "[data-action='submit']", function() {
    var btn = $(this);
    var form = btn
      .closest(".modal")
      .find(".modal-body")
      .find("form[data-id='leave-user-organization-form']");

    // Simply submit the form!
    form.submit();
  });

  // Lastly, bind on the ajax form
  $(document)
  .on(
    "ajax:success",
    "[data-id='leave-user-organization-form']",
    function (e, data, status, xhr) {
      // Simply reload the page
      location.reload();
    }
  )
  .on(
    "ajax:error",
    "[data-id='destroy-user-organization-form']",
    function (e, data, status, xhr) {
      // TODO
    }
  );
}

initLeaveOrganizations();