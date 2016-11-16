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
 * Initializes tutorial steps for the current page.
 * NOTE: If some steps edit page, then this function needs to be called several
 * times for the same page, but for different steps. The same goes if the page
 * has discontinuous tutorial steps. In such cases, use steps branching, e.g.:
 * @example
 * var tutorialData = Cookies.get('tutorial_data');
 * if (tutorialData) {
 *   tutorialData = JSON.parse(tutorialData);
 *   var stepNum = parseInt(Cookies.get('current_tutorial_step'), 10);
 *
 *   if (stepNum >= 6 && stepNum <= 7) {
 *     ...
 *   } else if ...
 * NOTE: If an element the popup is pointing at is of lesser horizontal length
 * than the popup itself, then it will not be positioned correctly if it's
 * position is top or bottom, so set/change the step's position to either left
 * or right (and don't use any custom styling!), e.g.:
 * @example
 * var steps = [
 *   {
 *     ...
 *     position: 'right'
 *   },
 *   {
 *   ...
 * ];
 *
 * @param  {number} pageFirstStep Page's first step
 * @param  {number} pageLastStep Page's last step
 * @param  {string} nextPagePath Next page absolute path
 * @param {function} beforeCb Callback called before the tutorial starts. Mainly
 *  used for setting 'pointer-events: none' on the elements the page's steps
 *  highlight.
 * @param {function} endCb Callback called after the tutorial ends. Mainly used
 *  for setting 'pointer-events: auto' on the elements the page's steps
 *  highlight.
 * @param {object} steps Optional JSON containing introJs steps. They can be
 *  specified here, or hardcoded in HTML.
 */
function initPageTutorialSteps(pageFirstStep, pageLastStep, nextPagePath,
                               beforeCb, endCb, steps) {
  var tutorialData = Cookies.get('tutorial_data');
  if (tutorialData) {
    tutorialData = JSON.parse(tutorialData);
    var stepNum = parseInt(Cookies.get('current_tutorial_step'), 10);
    if (isNaN(stepNum)) {
      stepNum = 1;
      Cookies.set('current_tutorial_step', stepNum);
      tutorialData[0].backPagesPaths = [];
      Cookies.set('tutorial_data', tutorialData);
    }
    var thisPagePath = window.location.pathname;
    beforeCb();

    // Initialize tutorial for the current page's steps
    var doneLabel = (pageLastStep === TUTORIAL_STEPS_CNT) ?
     'Start using sciNote' : 'End tutorial';
    if (_.isUndefined(steps)) {
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
    } else {
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
         tooltipClass: 'custom next-page-link',
         steps: steps
       })
       .goToStep(stepNum - (pageFirstStep - 1))
       .start();
    }

    // Page navigation when coming to this page from previous/next page
    $(function() {
      if (stepNum === pageFirstStep && stepNum > 1) {
        $('.introjs-prevbutton').removeClass('introjs-disabled');
      } else if (stepNum === pageLastStep && stepNum < TUTORIAL_STEPS_CNT) {
        $('.introjs-nextbutton').removeClass('introjs-disabled');
      }
    });

    // Page navigation when already on this page

    $('.introjs-skipbutton').click(function() {
      Cookies.remove('tutorial_data');
      Cookies.remove('current_tutorial_step');

      endCb();
    });

    $('.introjs-prevbutton').click(function() {
      if (stepNum > 1) {
        Cookies.set('current_tutorial_step', --stepNum);

        if (stepNum === pageFirstStep && stepNum > 1) {
          $('.introjs-prevbutton').removeClass('introjs-disabled');
        } else if (stepNum < pageFirstStep) {
          // Go to previous page;

          var prevPagePath = tutorialData[0].backPagesPaths.pop();
          Cookies.set('tutorial_data', tutorialData);
          $('.introjs-prevbutton').attr('href', prevPagePath);
          introJs().exit();
          endCb();
        }
      }
    });

    $('.introjs-nextbutton').click(function() {
      if (stepNum < TUTORIAL_STEPS_CNT) {
        Cookies.set('current_tutorial_step', ++stepNum);

        if (stepNum === pageLastStep && stepNum < TUTORIAL_STEPS_CNT) {
          $('.introjs-nextbutton').removeClass('introjs-disabled');
        } else if (stepNum > pageLastStep) {
          // Go to next page

          tutorialData[0].backPagesPaths.push(thisPagePath);
          Cookies.set('tutorial_data', tutorialData);
          $('.introjs-nextbutton').attr('href', nextPagePath);
          introJs().exit();
          endCb();
        }
      }
    });
  }
}
