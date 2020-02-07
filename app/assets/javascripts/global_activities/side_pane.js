/* global animateSpinner gaUrlQueryParams PerfectSb dropdownSelector */
/* eslint-disable no-extend-native, no-underscore-dangle, no-use-before-define */

var globalActivities = (function() {
  var updateRunning = false;

  var teamFilter = 'select[name=team]';
  var userFilter = 'select[name=user]';
  var groupActivityFilter = 'select[name=group_activity]';
  var activityFilter = 'select[name=activity]';
  var projectFilter = 'select[name=project]';
  var experimentFilter = 'select[name=experiment]';
  var taskFilter = 'select[name=task]';
  var inventoryFilter = 'select[name=inventory]';
  var inventoryItemFilter = 'select[name=inventory-item]';
  var protocolFilter = 'select[name=protocol]';
  var reportFilter = 'select[name=report]';

  var filterSelectors = ['group_activity', 'activity', 'user', 'team', 'project',
    'experiment', 'task', 'inventory', 'inventory-item', 'protocol', 'report'];
  var clearSelectors = ['group_activity', 'activity', 'user', 'team', 'project',
    'inventory', 'protocol', 'report'];

  Date.prototype.date_to_string = function() {
    return this.getFullYear() + '-' + (this.getMonth() + 1) + '-' + this.getDate();
  };

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
    var typesFilter = convertToInt(dropdownSelector.getValues(activityFilter) || []);
    var typesGroups = dropdownSelector.getValues(groupActivityFilter) || [];
    if (typesFilter.length === 0 && typesGroups.length > 0) {
      $.each(typesGroups, (ig, group) => {
        $.each($(activityFilter).find(`optgroup[label="${group}"] option`), (io, option) => {
          typesFilter.push(parseInt(option.value, 10));
        });
      });
    }

    return {
      teams: convertToInt(dropdownSelector.getValues(teamFilter) || []),
      users: convertToInt(dropdownSelector.getValues(userFilter) || []),
      types: typesFilter,
      subjects: {
        Project: convertToInt(dropdownSelector.getValues(projectFilter) || []),
        Experiment: convertToInt(dropdownSelector.getValues(experimentFilter) || []),
        MyModule: convertToInt(dropdownSelector.getValues(taskFilter) || []),
        Repository: convertToInt(dropdownSelector.getValues(inventoryFilter) || []),
        RepositoryRow: convertToInt(dropdownSelector.getValues(inventoryItemFilter) || []),
        Protocol: convertToInt(dropdownSelector.getValues(protocolFilter) || []),
        Report: convertToInt(dropdownSelector.getValues(reportFilter) || [])
      },
      from_date: GlobalActivitiesFiltersGetDates().from,
      to_date: GlobalActivitiesFiltersGetDates().to
    };
  }

  function init() {
    var ajaxParams = function(params) {
      var filter = GlobalActivitiesFilterPrepareArray();
      filter.query = params.query;
      return filter;
    };

    var defaultOnChangeActions = function() {
      GlobalActivitiesUpdateTopPaneTags();
      reloadActivities();
      toggleClearButtons();
    };
    $('.ga-tags-container').hide();

    dropdownSelector.init(groupActivityFilter, {
      optionClass: 'checkbox-icon',
      onChange: defaultOnChangeActions
    });

    dropdownSelector.init(activityFilter, {
      optionClass: 'checkbox-icon',
      onChange: defaultOnChangeActions,
      localFilter: function(data) {
        var groupFilter = dropdownSelector.getValues(groupActivityFilter);
        if (groupFilter.length === 0) return data;
        if (groupFilter.indexOf(data.parent().attr('label')) !== -1) {
          return data;
        }
        return [];
      }
    });

    $('.activity.clear').click(() => {
      updateRunning = true;
      dropdownSelector.clearData(groupActivityFilter);
      updateRunning = false;
      dropdownSelector.clearData(activityFilter);
    });

    $('.date-selector .date.clear').click(() => {
      updateRunning = true;
      $('#calendar-from-date').data('DateTimePicker').clear();
      $('#calendar-to-date').data('DateTimePicker').clear();
      $('.ga-side .date-selector.filter-block')[0].dataset.periodSelect = '';
      resetHotButtonsBackgroundColor();
      updateRunning = false;
      GlobalActivitiesUpdateTopPaneTags();
      reloadActivities();
      toggleClearButtons();
    });

    dropdownSelector.init(userFilter, {
      optionClass: 'checkbox-icon',
      ajaxParams: ajaxParams,
      onChange: defaultOnChangeActions
    }).initClearButton(userFilter, '.user.clear');

    dropdownSelector.init(teamFilter, {
      optionClass: 'checkbox-icon',
      ajaxParams: ajaxParams,
      onChange: defaultOnChangeActions
    }).initClearButton(teamFilter, '.team.clear');

    dropdownSelector.init(projectFilter, {
      optionClass: 'checkbox-icon',
      ajaxParams: ajaxParams,
      onChange: () => {
        var selectedValues = dropdownSelector.getValues(projectFilter);
        if (selectedValues.length > 0) {
          dropdownSelector.enableSelector(experimentFilter);
        } else {
          dropdownSelector.disableSelector(experimentFilter);
          dropdownSelector.disableSelector(taskFilter);
        }
        defaultOnChangeActions();
      }
    }).initClearButton(projectFilter, '.project.clear');

    dropdownSelector.init(experimentFilter, {
      optionClass: 'checkbox-icon',
      ajaxParams: ajaxParams,
      onChange: () => {
        var selectedValues = dropdownSelector.getValues(experimentFilter);
        if (selectedValues.length === 0) {
          dropdownSelector.disableSelector(taskFilter);
        } else {
          dropdownSelector.enableSelector(taskFilter);
        }
        defaultOnChangeActions();
      }
    });

    dropdownSelector.init(taskFilter, {
      optionClass: 'checkbox-icon',
      ajaxParams: ajaxParams,
      onChange: defaultOnChangeActions
    });

    dropdownSelector.init(inventoryFilter, {
      optionClass: 'checkbox-icon',
      ajaxParams: ajaxParams,
      onChange: () => {
        var selectedValues = dropdownSelector.getValues(inventoryFilter);
        if (selectedValues.length === 0) {
          dropdownSelector.disableSelector(inventoryItemFilter);
        } else {
          dropdownSelector.enableSelector(inventoryItemFilter);
        }
        defaultOnChangeActions();
      }
    }).initClearButton(inventoryFilter, '.inventory.clear');

    dropdownSelector.init(inventoryItemFilter, {
      optionClass: 'checkbox-icon',
      ajaxParams: ajaxParams,
      onChange: defaultOnChangeActions
    });

    dropdownSelector.init(protocolFilter, {
      optionClass: 'checkbox-icon',
      ajaxParams: ajaxParams,
      onChange: defaultOnChangeActions
    }).initClearButton(protocolFilter, '.protocol.clear');

    dropdownSelector.init(reportFilter, {
      optionClass: 'checkbox-icon',
      ajaxParams: ajaxParams,
      onChange: defaultOnChangeActions
    }).initClearButton(reportFilter, '.report.clear');

    $('.ga-side').scroll(() => {
      $.each(filterSelectors, (i, selector) => { dropdownSelector.updateDropdownDirection(`select[name=${selector}]`); });
    });

    $('.clear-container').click(() => {
      var selectorsCount = $(projectFilter).length === 1 ? clearSelectors.length - 1 : 1;
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
            <i class="fas fa-times"></i>
          </div>`).appendTo('.ga-top .ga-tags')
          .find('.fa-times').click(() => {
            $('.date-selector .date.clear').click();
          });
      }
      $.each($('.ga-side .ds-tags'), function(index, tag) {
        var newTag = $(tag.outerHTML).appendTo('.ga-top .ga-tags');
        newTag.find('.fa-times')
          .click(function() {
            newTag.addClass('closing');
            $(tag).find('.fa-times').click();
          });
      });
    }

    function preloadFilters(filters) {
      updateRunning = true;
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

    function toggleClearButtons() {
      var topFilters = $('.ga-tags-container');
      if (topFilters.find('.ds-tags').length) {
        topFilters.show();
      } else {
        topFilters.hide();
      }

      $.each($('.filter-block'), (i, block) => {
        if ($(block).find('.ds-tags').length
        || ($(block).hasClass('date-selector') && $(block)[0].dataset.periodSelect.length)) {
          $(block).find('.clear').show();
        } else {
          $(block).find('.clear').hide();
        }
      });
    }

    function resetHotButtonsBackgroundColor() {
      $('.date-selector .hot-button').each(function() {
        $(this).removeClass('selected');
      });
    }

    $('.filters-container').off('scroll').on('scroll', function() {
      $.each(filterSelectors, function(i, selector) {
        dropdownSelector.updateDropdownDirection(`select[name=${selector}]`);
      });
    });

    $('#calendar-to-date').on('dp.change', function(e) {
      var dateContainer = $('.ga-side .date-selector.filter-block');
      if (!updateRunning) {
        $('#calendar-from-date').data('DateTimePicker').minDate(e.date);
        dateContainer[0].dataset.periodSelect = $('#calendar-to-date').val() + ' - ' + $('#calendar-from-date').val();
        GlobalActivitiesUpdateTopPaneTags();
        reloadActivities();
        toggleClearButtons();
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
        toggleClearButtons();
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
      var monday = new Date(new Date()
        .setDate(today.getDate() - weekDay - (weekDay === 0 ? 6 : -1)));
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
      toggleClearButtons();

      resetHotButtonsBackgroundColor();
      $(this).addClass('selected');
    });
  }

  return {
    getFilters: GlobalActivitiesFilterPrepareArray,
    init: init
  };
}());

$(document).on('turbolinks:load', function() {
  if ($('.global-activities-container').length > 0) globalActivities.init();
});
