/* global animateSpinner I18n gaUrlQueryParams */

// Common code


Date.prototype.date_to_string = function() {
  return this.getFullYear() + '-' + (this.getMonth() + 1) + '-' + this.getDate();
};

// GA code

function GlobalActivitiesFiltersGetDates() {
  var fromDate = $('#calendar-from-date').data('DateTimePicker').date();
  var toDate = $('#calendar-to-date').data('DateTimePicker').date();
  if (fromDate) {
    fromDate = fromDate._d.date_to_string();
  }
  if (toDate) {
    toDate = toDate._d.date_to_string();
  }
  return { from: fromDate, to: toDate };
}

function GlobalActivitiesFilterPrepareArray() {
  var teamFilter = ($('.ga-side .team-selector select').val() || [])
    .map(e => { return parseInt(e, 10); });
  var userFilter = ($('.ga-side .user-selector select').val() || [])
    .map(e => { return parseInt(e, 10); });
  var activityFilter = ($('.ga-side .activity-selector select').val() || [])
    .map(e => { return parseInt(e, 10); });
  var subjectFilter = {};
  $.each(($('.ga-side .subject-selector select').val() || []), function(index, object) {
    var splitObject = object.split('_');
    if (subjectFilter[splitObject[0]] === undefined) subjectFilter[splitObject[0]] = [];
    subjectFilter[splitObject[0]].push(parseInt(splitObject[1], 10));
  });

  // Clear request parameters if all options are selected
  if (teamFilter.length === $('.ga-side .team-selector option').length) {
    teamFilter = [];
  }
  if (userFilter.length === $('.ga-side .user-selector option').length) {
    userFilter = [];
  }
  if (activityFilter.length === $('.ga-side .activity-selector option').length) {
    activityFilter = [];
  }

  return {
    teams: teamFilter,
    users: userFilter,
    types: activityFilter,
    subjects: subjectFilter,
    from_date: GlobalActivitiesFiltersGetDates().from,
    to_date: GlobalActivitiesFiltersGetDates().to
  };
}

$(function() {
  var updateRunning = false;
  var selectors = ['team', 'activity', 'user'];
  // Ajax request for object search
  var subjectAjaxQuery = {
    url: '/global_activities/search_subjects',
    dataType: 'json',
    data: function(params) {
      return {
        query: params.term // search term
      };
    },
    // preparing results
    processResults: function(data) {
      var result = [];
      $.each(data, (key, items) => {
        var updateItems = items.map(item => {
          return {
            id: key + '_' + item.id,
            text: item.name,
            label: I18n.t('global_activities.subject_name.' + key.toLowerCase())
          };
        });
        result.push({
          text: I18n.t('global_activities.subject_name.' + key.toLowerCase()),
          children: updateItems
        });
      });
      return {
        results: result
      };
    }
  };
  // custom display function
  var subjectCustomDisplay = (state) => {
    return (state.label ? state.label + ': ' : '') + state.text;
  };

  function GlobalActivitiesUpdateTopPaneTags(event) {
    var dateContainer = $('.ga-side .date-selector.filter-block');
    if (updateRunning) return false;
    $('.ga-top .ga-tags').children().remove();
    if (dateContainer[0].dataset.periodSelect) {
      $('<li class="select2-selection__choice">'
          + dateContainer[0].dataset.periodLabel
          + $('.ga-side .date-selector.filter-block')[0].dataset.periodSelect
        + '</li>').appendTo('.ga-top .ga-tags');
    }
    $.each($('.ga-side .select2-selection__choice'), function(index, tag) {
      var newTag = $(tag.outerHTML).appendTo('.ga-top .ga-tags');
      var selectedValues = [];
      var parentSelector = $(tag).parents('.select2-container').prev();
      var elementToDelete = null;
      newTag.find('.select2-selection__choice__remove')
        .click(() => {
          var parentTag = $(tag).find('span.select2-block-body')[0];
          if (event && event.type === 'select2:select' && parentTag) {
            // Adding remove action for native blocks
            selectedValues = parentSelector.val();
            elementToDelete = parentTag.dataset.selectId;
            selectedValues = $.grep(selectedValues, v => { return v !== elementToDelete; });
            parentSelector.val(selectedValues).change();
          } else {
            $(tag).find('.select2-selection__choice__remove').click();
          }
        });
    });
  }

  function preloadFilters(filters) {
    updateRunning = true;
    if (filters.types) {
      $('.ga-side .activity-selector select').val(filters.types).trigger('change');
    }
    if (filters.teams) {
      $('.ga-side .team-selector select').val(filters.teams).trigger('change');
    }
    if (filters.users) {
      $('.ga-side .user-selector select').val(filters.users).trigger('change');
    }
    if (filters.from_date) {
      $('#calendar-from-date').data('DateTimePicker').date(new Date(filters.from_date));
    }
    if (filters.to_date) {
      $('#calendar-to-date').data('DateTimePicker').date(new Date(filters.to_date));
    }
    if (filters.subject_labels) {
      $.each(filters.subject_labels, function(index, subject) {
        var subjectHash = JSON.parse(subject);
        $('<option data-label="test" value="' + subjectHash.id + '" selected >' + subjectHash.label + '</option>').appendTo('.ga-side .subject-selector select');
      });
      $('.ga-side .subject-selector select').trigger('change');
    }
    updateRunning = false;
    GlobalActivitiesUpdateTopPaneTags({ type: 'select2:select' });
  }

  // update_filter
  function reloadActivities() {
    var moreButton = $('.btn-more-activities');
    var noActivitiesMessage = $('.no-activities-message');
    if (updateRunning) return false;
    updateRunning = true;
    $('.ga-activities-list .activities-day').remove();
    animateSpinner(null, true);
    $.ajax({
      url: $('.ga-activities-list').data('activities-url'),
      data: GlobalActivitiesFilterPrepareArray(),
      dataType: 'json',
      type: 'POST',
      success: function(json) {
        $(json.activities_html).appendTo('.ga-activities-list');
        if (json.more_activities === true) {
          moreButton.removeClass('hidden');
          moreButton.data('next-date', json.from);
        } else {
          moreButton.addClass('hidden');
        }
        if (json.activities_html === '') {
          noActivitiesMessage.removeClass('hidden');
        } else {
          noActivitiesMessage.addClass('hidden');
        }
        updateRunning = false;
        animateSpinner(null, false);
      },
      error: function() {
        updateRunning = false;
        animateSpinner(null, false);
      }
    });
    return true;
  }

  function resetHotButtonsBackgroundColor() {
    $('.date-selector .hot-button').each(function() {
      $(this).removeClass('selected');
    });
  }

  // Common selection intialize
  $.each(selectors, (index, e) => {
    $('.ga-side .' + e + '-selector select').select2Multiple({ singleDisplay: true })
      .on('change', function() {
        GlobalActivitiesUpdateTopPaneTags();
        reloadActivities();
      });
    $('.ga-side .' + e + '-selector .clear').click(function() {
      $('.ga-side .' + e + '-selector select').select2MultipleClearAll();
    });
  });
  // Object selection intialize
  $('.ga-side .subject-selector select').select2Multiple({
    ajax: subjectAjaxQuery,
    customSelection: subjectCustomDisplay,
    unlimitedSize: true
  }).on('change select2:select', function(e) {
    GlobalActivitiesUpdateTopPaneTags(e);
    reloadActivities();
  });
  $('.ga-side .subject-selector .clear').click(function() {
    $('.ga-side .subject-selector select').select2MultipleClearAll();
  });

  $('.ga-tags-container .clear-container span').click(function() {
    updateRunning = true;
    $.each(selectors, (index, e) => { $('.ga-side .' + e + '-selector select').select2MultipleClearAll(); });
    $('.ga-side .subject-selector select').select2MultipleClearAll();
    $('#calendar-from-date').data('DateTimePicker').clear();
    $('#calendar-to-date').data('DateTimePicker').clear();
    $('.ga-side .date-selector.filter-block')[0].dataset.periodSelect = '';

    updateRunning = false;
    GlobalActivitiesUpdateTopPaneTags();
    reloadActivities();
    resetHotButtonsBackgroundColor();
  });

  $('#calendar-to-date').on('dp.change', function(e) {
    var dateContainer = $('.ga-side .date-selector.filter-block');
    if (!updateRunning) {
      $('#calendar-from-date').data('DateTimePicker').minDate(e.date);
      dateContainer[0].dataset.periodSelect = $('#calendar-to-date').val() + ' - ' + $('#calendar-from-date').val();
      GlobalActivitiesUpdateTopPaneTags();
      reloadActivities();
      resetHotButtonsBackgroundColor();
    }
  });

  $('#calendar-from-date').on('dp.change', function(e) {
    var dateContainer = $('.ga-side .date-selector.filter-block');
    if (!updateRunning) {
      $('#calendar-to-date').data('DateTimePicker').maxDate(e.date);
      dateContainer[0].dataset.periodSelect = $('#calendar-to-date').val() + ' - ' + $('#calendar-from-date').val();
      GlobalActivitiesUpdateTopPaneTags();
      reloadActivities();
      resetHotButtonsBackgroundColor();
    }
  });

  GlobalActivitiesUpdateTopPaneTags();

  if (typeof gaUrlQueryParams !== 'undefined' && gaUrlQueryParams) {
    preloadFilters(gaUrlQueryParams);
  }

  $('.date-selector .hot-button').click(function() {
    var selectPeriod = this.dataset.period;
    var dateContainer = $('.ga-side .date-selector.filter-block');
    var fromDate = $('#calendar-from-date').data('DateTimePicker');
    var toDate = $('#calendar-to-date').data('DateTimePicker');
    var today = new Date();
    var yesterday = new Date(new Date().setDate(today.getDate() - 1));
    var weekDay = today.getDay();
    var monday = new Date(new Date().setDate(today.getDate() - weekDay + (weekDay === 0 ? -6 : 1)));
    var lastWeekEnd = new Date(new Date().setDate(monday.getDate() - 1));
    var lastWeekStart = new Date(new Date().setDate(monday.getDate() - 7));
    var firstDay = new Date(today.getFullYear(), today.getMonth(), 1);
    var lastMonthEnd = new Date(new Date().setDate(firstDay.getDate() - 1));
    var lastMonthStart = new Date(lastMonthEnd.getFullYear(), lastMonthEnd.getMonth(), 1);
    updateRunning = true;
    fromDate.minDate(new Date(1900, 1, 1));
    toDate.maxDate(new Date(3000, 1, 1));
    if (selectPeriod === 'today') {
      fromDate.date(today);
      toDate.date(today);
    } else if (selectPeriod === 'yesterday') {
      fromDate.date(yesterday);
      toDate.date(yesterday);
    } else if (selectPeriod === 'this_week') {
      fromDate.date(today);
      toDate.date(monday);
    } else if (selectPeriod === 'last_week') {
      fromDate.date(lastWeekEnd);
      toDate.date(lastWeekStart);
    } else if (selectPeriod === 'this_month') {
      fromDate.date(today);
      toDate.date(firstDay);
    } else if (selectPeriod === 'last_month') {
      fromDate.date(lastMonthEnd);
      toDate.date(lastMonthStart);
    }
    updateRunning = false;
    dateContainer[0].dataset.periodSelect = this.innerHTML;
    GlobalActivitiesUpdateTopPaneTags();
    reloadActivities();

    resetHotButtonsBackgroundColor();
    $(this).addClass('selected');
  });
});
