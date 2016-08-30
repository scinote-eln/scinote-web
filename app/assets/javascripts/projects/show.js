(function(){
  var count = 0;

  function init(){
    $("[data-id]").each(function(){
      var that = $(this);
      that.find(".workflowimg-container").hide();
      initProjectExperiment(that);
    });
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
            setTimeout(checkUpdatedImg(img_url, url, timestamp, container), 500);
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
  // init
  init();
})();


/* Initialize the first-time demo tutorial if needed. */
(function(){
  function initializeTutorial() {
    if (showTutorial()) {
      introJs()
        .setOptions({
          overlayOpacity: '0.2',
          hidePrev: true,
          nextLabel: 'Next',
          doneLabel: 'End tutorial',
          skipLabel: 'End tutorial',
          showBullets: false,
          showStepNumbers: false,
          exitOnOverlayClick: false,
          exitOnEsc: false,
          tooltipClass: 'custom next-page-link',
          disableInteraction: true
        })
        .onafterchange(function (tarEl) {
          Cookies.set('current_tutorial_step', this._currentStep + 2);

          if (this._currentStep == 1) {
            setTimeout(function() {
              $('.next-page-link a.introjs-nextbutton')
                .removeClass('introjs-disabled')
                .attr('href', $('[data-canvas-link]').data('canvasLink'));
              $('.introjs-disableInteraction').remove();
            }, 500);
          } else {

          }
        })
        .start();

      window.onresize = function() {
        if (Cookies.get('current_tutorial_step') == 4 ) {
          $(".introjs-tooltip").css("right", ($(".new-element.initial").width() + 60)  + "px");
        }
      };

      // Destroy first-time tutorial cookies when skip tutorial
      // or end tutorial is clicked
      $(".introjs-skipbutton").each(function (){
        $(this).click(function (){
          Cookies.remove('tutorial_data');
          Cookies.remove('current_tutorial_step');
          restore_after_tutorial();
        });
      });
    }
  }

  function showTutorial() {
    var tutorialData;

    if (Cookies.get('tutorial_data'))
      tutorialData = JSON.parse(Cookies.get('tutorial_data'));
    else
      return false;
    var currentStep = Cookies.get('current_tutorial_step');
    if (currentStep < 3 || currentStep > 5)
      return false;
    var tutorialProjectId = tutorialData[0].project;
    var currentProjectId = $("#data-holder").attr("data-project-id");

    return tutorialProjectId == currentProjectId;
  }

  function project_tutorial_helper(){
    $(document).ready(function(){
      if( $('div').hasClass('introjs-overlay')){
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
    });
  }

  function restore_after_tutorial(){
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

  $(document).ready(function(){
    initializeTutorial();
    project_tutorial_helper();
  });

})();
