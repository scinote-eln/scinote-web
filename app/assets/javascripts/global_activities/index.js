/* global animateSpinner GlobalActivitiesFilterPrepareArray */

'use strict';

(function() {
  function initExpandCollapseAllButtons() {
    $('#global-activities-colapse-all').on('click', function(ev) {
      ev.preventDefault();
      $('.activities-group').collapse('hide');
    });
    $('#global-activities-expand-all').on('click', function(ev) {
      ev.preventDefault();
      $('.activities-group').collapse('show');
    });
  }

  function initExpandCollapseButton() {
    $('.ga-activities-list').on('hidden.bs.collapse', function(ev) {
      $(ev.target.dataset.buttonLink)
        .find('.fas').removeClass('fa-caret-down').addClass('fa-caret-right');
    });
    $('.ga-activities-list').on('shown.bs.collapse', function(ev) {
      $(ev.target.dataset.buttonLink)
        .find('.fas').removeClass('fa-caret-right').addClass('fa-caret-down');
    });
  }
  function initShowMoreButton() {
    var moreButton = $('.btn-more-activities');
    moreButton.on('click', function(ev) {
      var filters = GlobalActivitiesFilterPrepareArray();
      ev.preventDefault();
      animateSpinner(null, true);
      filters.from_date = moreButton.data('next-date');
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
          animateSpinner(null, false);
        }
      });
    });
  }

  initExpandCollapseAllButtons();
  initExpandCollapseButton();
  initShowMoreButton();
}());
