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
      filters.from_id = moreButton.data('next-id');
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

          if (json.more_activities === true) {
            moreButton.data('next-id', json.next_id);
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
