// Show more activities link.
$(".btn-more-activities")
  .on("ajax:success", function (e, data) {
    if (data.html) {
      var list = $("#list-activities");
      var moreBtn = $(".btn-more-activities");
      // Remove button if all activities are shown
      if (data.results_number < data.per_page) {
        moreBtn.remove();
      //  Otherwise update reference
      } else {
        moreBtn.attr("href", data.more_url);
      }
      $(list).append(data.html);
    }
  });
