(function(){
  var count = 0;

  function init(){
    $("[data-id]").each(function(){
      var that = $(this);
      initProjectExperiment(that);
    });
  }

  function initProjectExperiment(element){
    var container = element.find(".workflowimg-container");
    var url = container.data("check-img");
    var timestamp = container.data("timestamp");
    var img_url = container.data('updated-img');

    animateSpinner(container, true, { color: '#555', top: '60%', zIndex: '100' });
    checkUpdatedImg(img_url, url, timestamp, container);
  }

  // checks if the experiment image is updated
  function checkUpdatedImg(img_url, url, timestamp, container){
    if (count < 30 && timestamp){
      $.ajax({
        url: url,
        type: "GET",
        data: { "timestamp": timestamp },
        dataType: "json",
        success: function (data) {
          getNewWorkforwImg(container, img_url);
          container.show();
          animateSpinner(container, false);
        },
        error: function (ev) {
          if (ev.status == 404) {
            setTimeout(function () {
              checkUpdatedImg(img_url, url, timestamp, container)
            }, 5000);
          } else {
            animateSpinner(container, false);
          }
          count++;
          }
      });
    } else {
      animateSpinner(container, false);
    }
  }

  // fetch the new experiment image
  function getNewWorkforwImg(el, url){
    $.ajax({
      url: url,
      type: "GET",
      dataType: "json",
      success: function (data) {
        el.children('img').remove();
        el.append(data.workflowimg);
      },
      error: function (ev) {
        // TODO
      }
    });
  }

  init();
})();
