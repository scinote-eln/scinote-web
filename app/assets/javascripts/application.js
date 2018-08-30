// turbolinks MUST BE THE LAST inclusion
//= require jquery
//= require jquery_ujs
//= require jquery.mousewheel.min
//= require jquery.scrollTo
//= require jquery.autosize
//= require jquery-ui/widget
//= require jquery-ui/widgets/mouse
//= require jquery-ui/widgets/draggable
//= require jquery-ui/widgets/droppable
//= require jquery.ui.touch-punch.min
//= require jquery-ui/effects/effect-slide
//= require jquery.caret.min
//= require jquery.atwho.min
//= require hammer
//= require js.cookie
//= require spin
//= require jquery.spin
//= require bootstrap-sprockets
//= require moment
//= require bootstrap-datetimepicker
//= require bootstrap-colorselector
//= require bootstrap-tagsinput.min
//= require bootstrap-checkbox.min
//= require typeahead.bundle.min
//= require nested_form_fields
//= require highlight.pack
//= require tinymce-jquery
//= require jsPlumb-2.0.4-min
//= require jsnetworkx
//= require bootstrap-select
//= require_directory ./sitewide
//= require jquery.dataTables.yadcf
//= require datatables
//= require ajax-bootstrap-select.min
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
  // If overlaying the whole page, put the spinner in the middle of the page
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

/**
 * Automatic handling of show/hide spinner.
 * @param  {boolean} redirection Whether page is refreshed/redirected on success
 * @param  {boolean} onElement   Whether spinner is fixed on the center of fn
 *         element or it's positions on the center of whole page
 */
$.fn.animateSpinner = function(redirection, onElement) {
  redirection = _.isUndefined(redirection) ? false : redirection;
  onElement = _.isUndefined(onElement) ? false : onElement;

  $(this)
    .on('ajax:beforeSend', function() {
      onElement ? animateSpinner($(this)) : animateSpinner();
    })
    .on('ajax:error', function(e, data) {
      animateSpinner(null, false);
    })
    .on('ajax:success', function(e, data) {
      if (!redirection) {
        animateSpinner(null, false);
      }
    });
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

var HelperModule = (function(){

  var helpers = {};

  helpers.treeLinkTruncation = function() {
    $('.tree-link a').each( function(){
      truncateLongString( $(this), gon.global.NAME_TRUNCATION_LENGTH );
    });
    $(".tree-link span").each( function(){
      truncateLongString( $(this), gon.global.NAME_TRUNCATION_LENGTH );
    });
  }

  helpers.hideFlashMsg =  function() {
    var flash = $('.alert');
    if (flash.length > 0) {
      window.setTimeout(function () {
        flash.fadeTo(500, 0).slideUp(500, function () {
          $(this).remove();
        });
      }, 3000);
    }
  }

  helpers.dismissAlert = function() {
    $('#alert-flash').on('click', function() {
      $('#alert-flash').alert('close');
    })
  }

  helpers.flashAlertMsg = function(message, type) {
    var alertType, fasSign;

    $('#notifications').html('');
    if (type === 'success') {
      alertType = ' alert-success ';
      fasSign = ' fa-check-circle ';
    } else if (type === 'danger') {
      alertType = ' alert-danger ';
      fasSign = ' fa-exclamation-circle ';
    } else if (type === 'info') {
      alertType = ' alert-info ';
      fasSign = ' fa-exclamation-circle ';
    } else if (type === 'warning') {
      alertType = ' alert-warning ';
      fasSign = ' fa-exclamation-circle ';
    }
    var htmlSnippet = '<div id="alert-flash" class="alert alert' + alertType +
                      'alert-dismissable alert-floating">' +
                        '<div>' +
                        '<button type="button" class="close" ' +
                        'data-dismiss="alert" aria-label="Close">' +
                          '<span aria-hidden="true">×</span></button>' +
                            '<span class="fas' + fasSign + '"></span>&nbsp;' +
                            '<span>' + message + '</span>' +
                          '</div>' +
                        '</div>';
    $('#notifications').html(htmlSnippet);
    helpers.hideFlashMsg();
    helpers.dismissAlert();
  }

  $(document).on('turbolinks:load', function() {
    helpers.treeLinkTruncation();
    helpers.hideFlashMsg();
    helpers.dismissAlert();
  });

  return helpers;
})();

(function() {
  $(document).on('turbolinks:load', function() {
    // initialize code markup in rich text fields
    $('[class^=language]').each(function(i, block) {
      hljs.highlightBlock(block);
    });

    // fix dropdown-menu style throughout the app
    $('.dropdown-header').parent('ul').addClass('custom-dropdown-menu');

    // Close all open modals before caching
    $(document).on('turbolinks:before-cache', function() {
      $('.modal').modal('hide');
    });
  });
})();
