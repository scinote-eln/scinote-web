/* global animateSpinner globalActivities HelperModule */

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

  function initShowMoreButton() {
    var moreButton = $('.btn-more-activities');
    moreButton.on('click', function(ev) {
      var filters = globalActivities.getFilters();
      ev.preventDefault();
      animateSpinner(null, true);
      filters.page = moreButton.data('next-page');
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
            existingLastDay.find('.activities-counter-label strong').text(newNumber);
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

  function validateActivityFilterName() {
    let filterName = $('#saveFilterModal .activity-filter-name-input').val();
    $('#saveFilterModal .btn-confirm').prop('disabled', filterName.length === 0);
  }

  $('#saveFilterModal')
    .on('keyup', '.activity-filter-name-input', function() {
      validateActivityFilterName();
    })
    .on('click', '.btn-confirm', function() {
      $.ajax({
        url: this.dataset.saveFilterUrl,
        type: 'POST',
        global: false,
        dataType: 'json',
        data: {
          name: $('#saveFilterModal .activity-filter-name-input').val(),
          filter: globalActivities.getFilters()
        },
        success: function(data) {
          HelperModule.flashAlertMsg(data.message, 'success');
          $('#saveFilterModal .activity-filter-name-input').val('');
          validateActivityFilterName();
          $('#saveFilterModal').modal('hide');
        },
        error: function(response) {
          HelperModule.flashAlertMsg(response.responseJSON.errors.join(','), 'danger');
        }
      });
    });

  initExpandCollapseAllButtons();
  initShowMoreButton();
}());
