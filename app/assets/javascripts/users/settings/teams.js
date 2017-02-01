function initLeaveTeams() {
  // Bind the "leave team" buttons in teams table
  $(document)
  .on(
    "ajax:success",
    "[data-action='leave-user-team']",
    function (e, data, status, xhr) {
      // Populate the modal heading & body
      var modal = $("#modal-leave-user-team");
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
    "[data-action='destroy-user-team']",
    function (e, data, status, xhr) {
      // TODO
    }
  );

  // Also, bind the click action on the modal
  $("#modal-leave-user-team")
  .on("click", "[data-action='submit']", function() {
    var btn = $(this);
    var form = btn
      .closest(".modal")
      .find(".modal-body")
      .find("form[data-id='leave-user-team-form']");

    // Simply submit the form!
    form.submit();
  });

  // Lastly, bind on the ajax form
  $(document)
  .on(
    "ajax:success",
    "[data-id='leave-user-team-form']",
    function (e, data, status, xhr) {
      // Simply reload the page
      location.reload();
    }
  )
  .on(
    "ajax:error",
    "[data-id='destroy-user-team-form']",
    function (e, data, status, xhr) {
      // TODO
    }
  );
}

initLeaveTeams();
