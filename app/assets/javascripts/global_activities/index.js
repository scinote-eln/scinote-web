/* global animateSpinner */

'use strict';

(function() {
  function initExpandCollapseAllButtons() {
    $('#global-activities-colapse-all').on('click', function() {
      $('.activities-group').collapse('hide');
    });
    $('#global-activities-expand-all').on('click', function() {
      $('.activities-group').collapse('show');
    });
  }

  function initExpandCollapseButton() {
    $('.activities-group').on('hide.bs.collapse', function() {
      $('#' + $(this)
        .attr('id') + '-button').find('.fas').removeClass('fa-caret-down');
      $('#' + $(this)
        .attr('id') + '-button').find('.fas').addClass('fa-caret-right');
    });
    $('.activities-group').on('show.bs.collapse', function() {
      $('#' + $(this)
        .attr('id') + '-button').find('.fas').removeClass('fa-caret-right');
      $('#' + $(this)
        .attr('id') + '-button').find('.fas').addClass('fa-caret-down');
    });
  }

  function initShowMoreButton() {
    var moreButton = $('.btn-more-activities');
    moreButton.on('click', function(ev) {
      ev.preventDefault();
      animateSpinner(null, true);
      $.ajax({
        url: $('.global-activities_activities-list').data('activities-url'),
        data: { from_date: moreButton.data('next-date') },
        dataType: 'json',
        type: 'POST',
        success: function(json) {
          $('.global-activities_activities-list').html(json.activities_html);
          if (json.more_activities === true) {
            moreButton.data('next-date', json.next_date);
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
