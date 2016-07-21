$("#content-wrapper")
.on(
  "ajax:success",
  function(e, data) {
    if ($(e.target).is("[data-role='edit-step-form'], [data-role='new-step-form']")) {
      // Get the updated_at URL
      var url = $("[data-role='updated-at-label-url']").attr("data-url");

      // Fetch new updated at label
      $.ajax({
        url: url,
        type: "GET",
        dataType: "json",
        success: function (data2) {
          $("[data-role='updated-at-refresh']").html(data2.html);
        }
      });
    }
  }
);