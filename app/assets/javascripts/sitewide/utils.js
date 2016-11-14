/*
 * Converts JSON data received from the server to flat array of values.
 */
function jsonToValuesArray(jsonData) {
  var errMsgs = [];
  for (var key in jsonData) {
  	var values = jsonData[key];
    $.each(values, function (idx, val) {
      errMsgs.push(val);
	});
  }
  return errMsgs;
}

/*
 * Calls callback function on AJAX success (because built-in functions don't
 * work!)
 */
$.fn.onAjaxComplete = function (cb) {
  $(this)
  .on('ajax:success', function () {
	cb();
  })
  .on('ajax:error', function () {
	cb();
  });
}

var TUTORIAL_STEPS_CNT = 20;

/**
 * Initializes tutorial steps for the current page
 * @param  {number} pageFirstStep Page's first step
 * @param  {number} pageLastStep Page's last step
 * @param  {string} nextPagePath Next page absolute path
 * @param {function} beforeCb Callback called before the fucntion logic
 * @param {function} afterCb Callback called after the fucntion logic
 */
function initPageTutorialSteps(pageFirstStep, pageLastStep, nextPagePath,
                               beforeCb, afterCb) {
  var tutorialData = Cookies.get('tutorial_data');
  if (tutorialData) {
    tutorialData = JSON.parse(tutorialData);
    var stepNum = parseInt(Cookies.get('current_tutorial_step'), 10);
    if (isNaN(stepNum)) {
      stepNum = 1;
      Cookies.set('current_tutorial_step', stepNum);
    }
    beforeCb();

    // Initialize tutorial for the current page's steps
    var doneLabel = (pageLastStep === TUTORIAL_STEPS_CNT) ?
     'Start using sciNote' : 'End tutorial';
    introJs()
      .setOptions({
        overlayOpacity: '0.2',
        prevLabel: 'Back',
        nextLabel: 'Next',
        skipLabel: 'End tutorial',
        doneLabel: doneLabel,
        showBullets: false,
        showStepNumbers: false,
        exitOnOverlayClick: false,
        exitOnEsc: false,
        disableInteraction: true,
        tooltipClass: 'custom next-page-link'
      })
      .goToStep(stepNum - (pageFirstStep - 1))
      .start();

    // Page navigation when coming to this page from previous/next page
    $(function() {
      if (stepNum === pageFirstStep && stepNum > 1) {
        $('.introjs-prevbutton').removeClass('introjs-disabled');
      } else if (stepNum === pageLastStep) {
        $('.introjs-nextbutton').removeClass('introjs-disabled');
      }
    });

    // Page navigation when already on this page

    $('.introjs-skipbutton').click(function() {
      Cookies.remove('tutorial_data');
      Cookies.remove('current_tutorial_step');

      afterCb();
      $('.introjs-overlay').remove();
    });

    $('.introjs-prevbutton').click(function() {
      if (stepNum > 1) {
        Cookies.set('current_tutorial_step', --stepNum);

        if (stepNum === pageFirstStep && stepNum > 1) {
          $('.introjs-prevbutton').removeClass('introjs-disabled');
        } else if (stepNum < pageFirstStep) {
          // Going to previous page
          var prevPage = tutorialData[0].previousPage;
          $('.introjs-prevbutton').attr('href', prevPage);
        }
      }
    });

    $('.introjs-nextbutton').click(function() {
      if (stepNum < TUTORIAL_STEPS_CNT) {
        Cookies.set('current_tutorial_step', ++stepNum);

        if (stepNum === pageLastStep && stepNum < TUTORIAL_STEPS_CNT) {
          $('.introjs-nextbutton').removeClass('introjs-disabled');
        } else if (stepNum > pageLastStep) {
          // Going to next page

          var prevPage = window.location.pathname;
          tutorialData[0].previousPage = prevPage;
          Cookies.set('tutorial_data', tutorialData);

          $('.introjs-nextbutton').attr('href', nextPagePath);
        }
      }
    });
  }
}
