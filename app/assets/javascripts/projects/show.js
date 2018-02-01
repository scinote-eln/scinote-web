(function(){
  var count = 0;

  function init(){
    $("[data-id]").each(function(){
      var that = $(this);
      initProjectExperiment(that);
    });

    initTutorial();
  }

  function initProjectExperiment(element){
    var container = element.find(".workflowimg-container");
    var url = container.data("check-img");
    var timestamp = container.data("timestamp");
    var img_url = container.data('updated-img');

    animateSpinner(container, true);
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
        el.append(data.workflowimg);
      },
      error: function (ev) {
        // TODO
      }
    });
  }

  /**
   * Initializes tutorial
   */
  function initTutorial() {
    var stepNum = parseInt(Cookies.get('current_tutorial_step'), 10);
    if (stepNum >= 4 && stepNum <= 5) {
      var nextPage = $('[data-canvas-link]').data('canvasLink');
      var steps = [{
        element: $('#new-experiment')[0],
        intro: I18n.t('tutorial.tutorial_welcome_title_html'),
        position: 'left'
      }, {
        element: $('.experiment-panel')[0],
        intro: I18n.t('tutorial.edit_experiment_html'),
        position: 'right'
      }];
      initPageTutorialSteps(4, 5, nextPage, tutorialBeforeCb, tutorialAfterCb,
       steps);
    }
  }

  /**
   * Callback to be executed before tutorial starts
   */
  function tutorialBeforeCb() {
    $.each( $(".panel-title"), function(){
      $(this).css({ "pointer-events": "none" });
    });
    $.each( $(".workflowimg-container"), function(){
      $(this).css({ "pointer-events": "none" });
    });
    $.each( $(".dropdown-experiment-actions").find("li"),
      function(){
        $(this).css({ "pointer-events": "none" });
    });
  }

  /**
   * Callback to be executed after tutorial exits
   */
  function tutorialAfterCb() {
    $.each( $(".panel-title"), function(){
      $(this).css({ "pointer-events": "auto" });
    });
    $.each( $(".workflowimg-container"), function(){
      $(this).css({ "pointer-events": "auto" });
    });
    $.each( $(".dropdown-experiment-actions").find("li"),
      function(){
        $(this).css({ "pointer-events": "auto" });
    });
  }

  init();
})();
