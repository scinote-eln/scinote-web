(function(){

  function initProjectExperiment(){
    var url = $("[data-lupdated-url]").data("lupdated-url");
    var updated = "[data-id=" + $("[data-lupdated-id]").data('lupdated-id') +"]";
    var el = $(updated).find("img");
    el.hide();
    var timestamp = el.data("timestamp");
    var img_url = $(updated).find(".workflowimg-container").data('updated-img');
    animateSpinner($(updated).find(".workflowimg-container"), true);

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
          setTimeout(initProjectExperiment(), 200);
        }
        animateSpinner($(updated).find(".workflowimg-container"), false);
      }
    });
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
        animateSpinner($(updated).find(".workflowimg-container"), false);
      }
    });
  }
  // init
  initProjectExperiment();
})();
