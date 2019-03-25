/* global animateSpinner */

'use strict';

function globalActivitiesInit() {
  function initExpandCollapseAllButtons() {
    $('#global-activities-colapse-all').on('click', function() {
      $('.activities-group').collapse('hide');
    });
    $('#global-activities-expand-all').on('click', function() {
      $('.activities-group').collapse('show');
    });
  }

  function initExpandCollapseButton() {
    $('.activities-group').on('hidden.bs.collapse', function() {
      $(this.dataset.buttonLink)
        .find('.fas').removeClass('fa-caret-down').addClass('fa-caret-right');
    });
    $('.activities-group').on('shown.bs.collapse', function() {
      $(this.dataset.buttonLink)
        .find('.fas').removeClass('fa-caret-right').addClass('fa-caret-down');
    });
  }
  function initShowMoreButton() {
    var moreButton = $('.btn-more-activities');
    moreButton.on('click', function(ev) {
      var filters = GlobalActivitiesFilterPrepareArray();
      ev.preventDefault();
      animateSpinner(null, true);
      filters.to_date = moreButton.data('next-date');
      $.ajax({
        url: $('.ga-activities-list').data('activities-url'),
        data: filters,
        dataType: 'json',
        type: 'POST',
        success: function(json) {
          $(json.activities_html).appendTo('.ga-activities-list');
          if (json.more_activities === true) {
            moreButton.data('next-date', json.from);
          } else {
            moreButton.addClass('hidden');
          }
          (new globalActivitiesInit()).updateCollapseButton();
          animateSpinner(null, false);
        }
      });
    });
  }
  if (this) {
    this.updateCollapseButton = function() {
      initExpandCollapseButton();
    };
  }

  initExpandCollapseAllButtons();
  initExpandCollapseButton();
  initShowMoreButton();
}

globalActivitiesInit();
