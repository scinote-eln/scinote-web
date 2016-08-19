(function(){
  var count = 0;

  function initProjectExperiment(){
    var url = $("[data-lupdated-url]").data("lupdated-url");
    var updated = "[data-id=" + $("[data-lupdated-id]").data('lupdated-id') +"]";
    var el = $(updated).find("img");
    var timestamp = el.data("timestamp");
    var img_url = $(updated).find(".workflowimg-container").data('updated-img');

    animateSpinner($(updated).find(".workflowimg-container"), true);
    checkUpdatedImg(el, img_url, url, timestamp, updated);
    animateSpinner($(updated).find(".workflowimg-container"), false);
  }


  function checkUpdatedImg(el, img_url, url, timestamp, updated){
    if (count !== 100){
      $.ajax({
        url: url,
        type: "GET",
        data: { "timestamp": timestamp },
        dataType: "json",
        success: function (data) {
          getNewWorkforwImg(el, img_url, updated);
          animateSpinner($(updated).find(".workflowimg-container"), false);
        },
        error: function (ev) {
          if (ev.status == 404) {
              setTimeout(checkUpdatedImg(el, img_url, url, timestamp, updated), 200);
            }
            count++;
          }
      });
    }
  }

  function getNewWorkforwImg(el, url, updated){
    $.ajax({
      url: url,
      type: "GET",
      dataType: "json",
      success: function (data) {
        el.html(data.workflowimg);
        animateSpinner($(updated).find(".workflowimg-container"), false);
      },
      error: function (ev) {
        // TODO
      }
    });
  }
  // init
  initProjectExperiment();
})();
