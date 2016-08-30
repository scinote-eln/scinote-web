// jquery.turbolinks MUST IMMEDIATELY FOLLOW jquery inclusion
// turbolinks MUST BE THE LAST inclusion
//= require jquery
//= require jquery.turbolinks
//= require jquery_ujs
//= require jquery.remotipart
//= require jquery.mousewheel.min
//= require jquery.scrollTo
//= require jquery-ui/widget
//= require jquery-ui/mouse
//= require jquery-ui/draggable
//= require jquery-ui/droppable
//= require jquery.ui.touch-punch.min
//= require hammer
//= require introjs
//= require js.cookie
//= require spin
//= require jquery.spin
//= require bootstrap-sprockets
//= require moment
//= require bootstrap-datetimepicker
//= require bootstrap-colorselector
//= require bootstrap-tagsinput.min
//= require typeahead.bundle.min
//= require nested_form_fields
//= require_directory ./sitewide
//= require dataTables.noSearchHidden
//= require bootstrap-select
//= require underscore
//= require i18n.js
//= require i18n/translations
//= require turbolinks


// Initialize links for submitting forms. This is useful for submitting
// forms with clicking on links outside form in cases when other than
// GET method is used.
function initFormSubmitLinks(el) {

  el = el || $(document.body);
  $(".form-submit-link", el).click(function () {
    var val = true;
    if ($(this).is("[data-confirm-form]")) {
      val = confirm($(this).data("confirm-form"));
    }
    // Only submit form if confirmed
    if (val) {
      animateLoading();
      $("#" + $(this).data("submit-form")).submit();
    }
  });
}

/* Enable loading bars */
Turbolinks.enableProgressBar();
$(document)
  .bind("ajaxSend", function(){
    animateLoading();
  })
  .bind("ajaxComplete", function(){
    animateLoading(false);
  });

/*
 * Show/hide loading indicator on top of page.
 */
function animateLoading(start){
  if (start === undefined)
    start = true;
  start = start !== false;
  if (start) {
    $("#loading-animation").addClass("animate");
  }
  else {
    $("#loading-animation").removeClass("animate");
  }
}

/*
 * Show/hide spinner for a given element.
 * Shows spinner if start is true or not given, hides it if false.
 * Optional parameter options for spin.js options.
 */
function animateSpinner(el, start, options) {
  // If overlaying the whole page,
  // put the spinner in the middle of the page
  var overlayPage = false;
  if (_.isUndefined(el) || el === null) {
    overlayPage = true;
    if ($(document.body).has('.loading-overlay-center').length === 0) {
      $(document.body).append('<div class="loading-overlay-center" />');
    }
    el = $(document.body).find('.loading-overlay-center');
  }

  if (_.isUndefined(start)) {
    start = true;
  }

  if (start && options) {
    $(el).spin(options);
  }
  else {
    $(el).spin(start);
  }

  if (start) {
    if (overlayPage) {
      $(document.body).append('<div class="loading-overlay" />');
    } else {
      $(el).append('<div class="loading-overlay" />');
    }
  } else {
    $(".loading-overlay").remove();
  }
}

/*
 * Prevents user from accidentally leaving page when server is busy
 * and notifies him with a message.
 *
 * NOTE: Don't prevent event propagation (ev.stopPropagation()), or
 * else all events occurring when alert is up will be ignored.
 */
function preventLeavingPage(prevent, msg) {
  busy = prevent;
  if (busy && !_.isUndefined(msg)) {
    busyMsg = msg;
  }
}
var busy = false;
var busyMsg = I18n.t("general.busy");
window.onbeforeunload = function () {
  if (busy) {
    var currentMsg = busyMsg;
    // Reset to default message
    busyMsg = I18n.t("general.busy");
    return currentMsg;
  }
}

/*
 * Disable Firefox caching to get rid of issues with pressing
 * browser back, like opening canvas in edit mode.
 */
$(window).unload(function () {
  $(window).unbind('unload');
});

$(document.body).ready(function () {
  // Activity feed modal in main navigation menu
  var activityModal = $('#activity-modal');
  var activityModalBody = activityModal.find('.modal-body');

  var initMoreBtn = function () {
    activityModalBody.find('.btn-more-activities')
      .on('ajax:success', function (e, data) {
        $(data.html).insertBefore($(this).parents('li'));
        $(this).attr('href', data.next_url);
        if (data.activities_number < data.per_page) {
          $(this).remove();
        }
      });
  };

  notificationAlertClose();

  $('#main-menu .btn-activity')
    .on('ajax:before', function () {
      activityModal.modal('show');
    })
    .on('ajax:success', function (e, data) {
      activityModalBody.html(data.html);
      initMoreBtn();
    });

  activityModal.on('hidden.bs.modal', function () {
    activityModalBody.html('');
  });
});

$(document).ajaxComplete(function(){
  notificationAlertClose();
});

function notificationAlertClose(){
  $("#notifications .alert").on("closed.bs.alert", function () {
    $("#content-wrapper")
      .addClass("alert-hidden")
      .removeClass("alert-shown");
  });
}

$(document).ready(function(){
  $('.tree-link a').each( function(){
    truncateLongString( $(this), 30);
  });
  $(".tree-link span").each( function(){
    truncateLongString( $(this), 30);
  });
});
