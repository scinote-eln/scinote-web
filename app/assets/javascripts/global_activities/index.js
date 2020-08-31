/* global animateSpinner globalActivities */

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
        .find('.fas').removeClass('fa-chevron-down').addClass('fa-chevron-right');
    });
    $('.ga-activities-list').on('shown.bs.collapse', function(ev) {
      $(ev.target.dataset.buttonLink)
        .find('.fas').removeClass('fa-chevron-right').addClass('fa-chevron-down');
    });
  }
  function initShowMoreButton() {
    var moreButton = $('.btn-more-activities');
    moreButton.on('click', function(ev) {
      var filters = globalActivities.getFilters();
      ev.preventDefault();
      animateSpinner(null, true);
      filters.page = moreButton.data('next-page');
      filters.starting_timestamp = $('.ga-activities-list').data('starting-timestamp');
      $.ajax({
        url: $('.ga-activities-list').data('activities-url'),
        data: filters,
        dataType: 'json',
        type: 'POST',
        success: function(json) {
          var newFirstDay;
          var existingLastDay;

          // Attach newly fetched activities to temporary placeholder
          $(json.activities_html).appendTo('#ga-more-activities-placeholder');

          newFirstDay = $('#ga-more-activities-placeholder').find('.activities-day').first();
          existingLastDay = $('.ga-activities-list').find('.activities-day').last();

          if (newFirstDay.data('date') === existingLastDay.data('date')) {
            let newNumber;
            existingLastDay.find('.activities-group').append(newFirstDay.find('.activities-group').html());
            newNumber = existingLastDay.find('.activity-card').length;
            existingLastDay.find('.activities-counter-label strong').html(newNumber);
            newFirstDay.remove();
          }

          $('.ga-activities-list').append($('#ga-more-activities-placeholder').html());
          $('#ga-more-activities-placeholder').html('');

          if (json.next_page) {
            moreButton.data('next-page', json.next_page);
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
