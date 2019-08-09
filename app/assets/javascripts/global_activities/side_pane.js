/* global animateSpinner gaUrlQueryParams PerfectSb dropdownSelector */
/* eslint-disable no-extend-native, no-underscore-dangle, no-use-before-define */
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
  var convertToInt = (array) => { return array.map(e => { return parseInt(e, 10); }); };
  var typesFilter = convertToInt(dropdownSelector.getValues('select[name=activity]') || []);
  var typesGroups = dropdownSelector.getValues('select[name=group_activity]') || [];
  if (typesFilter.length === 0 && typesGroups.length > 0) {
    $.each(typesGroups, (ig, group) => {
      $.each($('select[name=activity]').find(`optgroup[label="${group}"] option`), (io, option) => {
        typesFilter.push(parseInt(option.value, 10));
      });
    });
  }

  return {
    teams: convertToInt(dropdownSelector.getValues('select[name=team]') || []),
    users: convertToInt(dropdownSelector.getValues('select[name=user]') || []),
    types: typesFilter,
    subjects: {
      Project: convertToInt(dropdownSelector.getValues('select[name=project]') || []),
      Experiment: convertToInt(dropdownSelector.getValues('select[name=experiment]') || []),
      MyModule: convertToInt(dropdownSelector.getValues('select[name=task]') || []),
      Repository: convertToInt(dropdownSelector.getValues('select[name=inventory]') || []),
      RepositoryRow: convertToInt(dropdownSelector.getValues('select[name=inventory-item]') || []),
      Protocol: convertToInt(dropdownSelector.getValues('select[name=protocol]') || []),
      Report: convertToInt(dropdownSelector.getValues('select[name=report]') || [])
    },
    from_date: GlobalActivitiesFiltersGetDates().from,
    to_date: GlobalActivitiesFiltersGetDates().to
  };
}

$(function() {
  var updateRunning = false;

  var filterSelectors = ['group_activity', 'activity', 'user', 'team', 'project',
    'experiment', 'task', 'inventory', 'inventory-item', 'protocol', 'report'];
  var clearSelectors = ['group_activity', 'activity', 'user', 'team', 'project',
    'inventory', 'protocol', 'report'];


  var ajaxParams = function(params) {
    var filter = GlobalActivitiesFilterPrepareArray();
    filter.query = params.query;
    return filter;
  };

  var defaultOnChangeActions = function() {
    GlobalActivitiesUpdateTopPaneTags();
    reloadActivities();
  };

  dropdownSelector.init('select[name=group_activity]', {
    onChange: defaultOnChangeActions
  });
  dropdownSelector.init('select[name=activity]', {
    onChange: defaultOnChangeActions,
    localFilter: function(data) {
      var groupFilter = dropdownSelector.getValues('select[name=group_activity]');
      if (groupFilter.length === 0) return data;
      if (groupFilter.indexOf(data.parent().attr('label')) !== -1) {
        return data;
      }
      return [];
    }
  });
  $('.activity.clear').click(() => {
    updateRunning = true;
    dropdownSelector.clearData('select[name=group_activity]');
    updateRunning = false;
    dropdownSelector.clearData('select[name=activity]');
  });

  dropdownSelector.init('select[name=user]', {
    ajaxParams: ajaxParams,
    onChange: defaultOnChangeActions
  }).initClearButton('select[name=user]', '.user.clear');

  dropdownSelector.init('select[name=team]', {
    ajaxParams: ajaxParams,
    onChange: defaultOnChangeActions
  }).initClearButton('select[name=team]', '.team.clear');

  dropdownSelector.init('select[name=project]', {
    ajaxParams: ajaxParams,
    onChange: () => {
      var selectedValues = dropdownSelector.getValues('select[name=project]');
      if (selectedValues.length > 0) {
        dropdownSelector.disableSelector('select[name=experiment]', false);
      } else {
        dropdownSelector.disableSelector('select[name=experiment]', true);
        dropdownSelector.disableSelector('select[name=task]', true);
      }
      defaultOnChangeActions();
    }
  }).initClearButton('select[name=project]', '.project.clear');

  dropdownSelector.init('.select-container.experiment select', {
    ajaxParams: ajaxParams,
    onChange: () => {
      var selectedValues = dropdownSelector.getValues('select[name=experiment]');
      dropdownSelector.disableSelector('select[name=task]', (selectedValues.length === 0));
      defaultOnChangeActions();
    }
  });

  dropdownSelector.init('select[name=task]', {
    ajaxParams: ajaxParams,
    onChange: defaultOnChangeActions
  });

  dropdownSelector.init('select[name=inventory]', {
    ajaxParams: ajaxParams,
    onChange: () => {
      var selectedValues = dropdownSelector.getValues('select[name=inventory]');
      dropdownSelector.disableSelector('select[name=inventory-item]', (selectedValues.length === 0));
      defaultOnChangeActions();
    }
  }).initClearButton('select[name=inventory]', '.inventory.clear');

  dropdownSelector.init('select[name=inventory-item]', {
    ajaxParams: ajaxParams,
    onChange: defaultOnChangeActions
  });

  dropdownSelector.init('select[name=protocol]', {
    ajaxParams: ajaxParams,
    onChange: defaultOnChangeActions
  }).initClearButton('select[name=protocol]', '.protocol.clear');

  dropdownSelector.init('select[name=report]', {
    ajaxParams: ajaxParams,
    onChange: defaultOnChangeActions
  }).initClearButton('select[name=report]', '.report.clear');

  $('.ga-side').scroll(() => {
    $.each(filterSelectors, (i, selector) => { dropdownSelector.updateDropdownDirection(`select[name=${selector}]`); });
  });

  $('.clear-container').click(() => {
    var selectorsCount = $('select[name=project]').length === 1 ? clearSelectors.length - 1 : 1;
    updateRunning = true;

    $('#calendar-from-date').data('DateTimePicker').clear();
    $('#calendar-to-date').data('DateTimePicker').clear();
    $('.ga-side .date-selector.filter-block')[0].dataset.periodSelect = '';


    $.each(clearSelectors, (i, selector) => {
      if (i === selectorsCount) updateRunning = false;
      dropdownSelector.clearData(`select[name=${selector}]`);
    });

    resetHotButtonsBackgroundColor();
  });

  function GlobalActivitiesUpdateTopPaneTags() {
    var dateContainer = $('.ga-side .date-selector.filter-block');
    if (updateRunning) return false;
    $('.ga-top .ga-tags').children().remove();
    if (dateContainer[0].dataset.periodSelect) {
      $(`<div class="ds-tags">
          <div class="tag-label">
            ${dateContainer[0].dataset.periodLabel}
            ${$('.ga-side .date-selector.filter-block')[0].dataset.periodSelect}
          </div>
        </div>`).appendTo('.ga-top .ga-tags');
    }
    $.each($('.ga-side .ds-tags'), function(index, tag) {
      var newTag = $(tag.outerHTML).appendTo('.ga-top .ga-tags');
      newTag.find('.fa-times')
        .click(() => {
          $(tag).find('.fa-times').click();
        });
    });
  }

  function preloadFilters(filters) {
    updateRunning = true;
    if (filters.types) {
      $('.ga-side .activity-selector select').val(filters.types).trigger('change');
    }
    if (filters.from_date) {
      $('#calendar-from-date').data('DateTimePicker').date(new Date(filters.from_date));
    }
    if (filters.to_date) {
      $('#calendar-to-date').data('DateTimePicker').date(new Date(filters.to_date));
    }
    if (filters.subject_labels) {
      $.each(filters.subject_labels, (i, subject) => {
        var currentData = dropdownSelector.getData(`select[name=${subject.object}]`);
        currentData.push(subject);
        dropdownSelector.setData(`select[name=${subject.object}]`, currentData);
      });
    }
    updateRunning = false;
    GlobalActivitiesUpdateTopPaneTags();
  }

  // update_filter
  function reloadActivities() {
    var moreButton = $('.btn-more-activities');
    var noActivitiesMessage = $('.no-activities-message');
    if (updateRunning) return false;
    updateRunning = true;
    $('.ga-activities-list .activities-day').remove();
    animateSpinner('.ga-main', true);
    $.ajax({
      url: $('.ga-activities-list').data('activities-url'),
      data: GlobalActivitiesFilterPrepareArray(),
      dataType: 'json',
      type: 'POST',
      success: function(json) {
        $(json.activities_html).appendTo('.ga-activities-list');
        if (json.next_page) {
          moreButton.removeClass('hidden');
          moreButton.data('next-page', json.next_page);
        } else {
          moreButton.addClass('hidden');
        }
        if (json.activities_html === '') {
          noActivitiesMessage.removeClass('hidden');
        } else {
          noActivitiesMessage.addClass('hidden');
        }
        $('.ga-activities-list').data('starting-timestamp', json.starting_timestamp);
        updateRunning = false;
        animateSpinner('.ga-main', false);

        $('.ga-main').scrollTop(0);
        PerfectSb().update_all();
      },
      error: function() {
        updateRunning = false;
        animateSpinner('.ga-main', false);
      }
    });
    return true;
  }

  function resetHotButtonsBackgroundColor() {
    $('.date-selector .hot-button').each(function() {
      $(this).removeClass('selected');
    });
  }

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
