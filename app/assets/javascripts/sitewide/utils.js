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

// Number of all tutorial steps
var TUTORIAL_STEPS_CNT = 26;

/**
 * Initializes tutorial steps for the current page.
 * NOTE: You can specify steps manually in JS with steps parameter (preferred
 * way), or hardcode them in HTML
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
 * NOTE: If only one page step is needed, then make pageFirstStepN ==
 * pageLastStepN (both represent the one and only step number)
 *
 * @param  {number} pageFirstStepN Page's first step number
 * @param  {number} pageLastStepN Page's last step number
 * @param  {string} nextPagePath Next page absolute path
 * @param {function} beforeCb Callback called before the tutorial starts. Mainly
 *  used for setting 'pointer-events: none' on the elements the page's steps
 *  highlight.
 * @param {function} endCb Callback called after the tutorial ends. Mainly used
 *  for setting 'pointer-events: auto' on the elements the page's steps
 *  highlight.
 * @param {object} steps JSON containing intro.js steps.
 */
function initPageTutorialSteps(pageFirstStepN, pageLastStepN, nextPagePath,
                               beforeCb, endCb, steps) {
  var tutorialData = Cookies.get('tutorial_data');
  if (tutorialData) {
    tutorialData = JSON.parse(tutorialData);
    var stepNum = parseInt(Cookies.get('current_tutorial_step'), 10);
    if (isNaN(stepNum)) {
      // Cookies data initialization
      stepNum = 1;
      Cookies.set('current_tutorial_step', stepNum);
      tutorialData[0].backPagesPaths = [];
      Cookies.set('tutorial_data', tutorialData);
    }
    var thisPagePath = window.location.pathname;
    beforeCb();

    // Initialize tutorial for the current pages' steps

    var doneLabel;
    if (pageLastStepN == TUTORIAL_STEPS_CNT) {
      doneLabel = I18n.t('tutorial.finish_tutorial');
    } else {
      doneLabel = I18n.t('tutorial.skip_tutorial');
      // Add extra fake step, so that next button on last step of current page
      // gets focused. Also, if current page has only one step, this adds back
      // and next buttons to the popup.
      steps.push({});
    }
    introJs()
     .setOptions({
       overlayOpacity: '0.2',
       prevLabel: I18n.t('tutorial.back'),
       nextLabel: I18n.t('tutorial.next'),
       skipLabel: I18n.t('tutorial.skip_tutorial'),
       doneLabel: doneLabel,
       showBullets: false,
       showStepNumbers: false,
       exitOnOverlayClick: false,
       exitOnEsc: false,
       disableInteraction: true,
       keyboardNavigation: false,
       tooltipClass: 'custom next-page-link',
       steps: steps
     })
     .goToStep(stepNum - (pageFirstStepN - 1))
     .onexit(function() {
       Cookies.remove('tutorial_data');
       Cookies.remove('current_tutorial_step');
       location.reload();
     })
     .oncomplete(function() {
       Cookies.remove('tutorial_data');
       Cookies.remove('current_tutorial_step');
       location.reload();
     })
     .start();

    // Page navigation when coming to this page from previous or from next page
    $(function() {
      if (stepNum === pageFirstStepN && stepNum > 1) {
        $('.introjs-prevbutton').removeClass('introjs-disabled');
      } else if (stepNum === pageLastStepN && stepNum < TUTORIAL_STEPS_CNT) {
        $('.introjs-nextbutton').removeClass('introjs-disabled');
      }
    });

    // Page navigation when already on this page

    $('.introjs-skipbutton').click(function() {
      Cookies.remove('current_tutorial_step');
      Cookies.remove('tutorial_data');

      endCb();
    });

    $('.introjs-prevbutton').click(function() {
      if (stepNum > 1) {
        Cookies.set('current_tutorial_step', --stepNum);

        if (stepNum === pageFirstStepN && stepNum > 1) {
          $('.introjs-prevbutton').removeClass('introjs-disabled');
        } else if (stepNum < pageFirstStepN) {
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

        if (stepNum === pageLastStepN && stepNum < TUTORIAL_STEPS_CNT) {
          $('.introjs-nextbutton').removeClass('introjs-disabled');
        } else if (stepNum > pageLastStepN) {
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
