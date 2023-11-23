/* global animateSpinner PerfectSb dropdownSelector */
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
    var fromDate = $('#calendar-from-date').data('dateTimePicker').$refs.vueDateTime.datetime;
    var toDate = $('#calendar-to-date').data('dateTimePicker').$refs.vueDateTime.datetime;
    if (fromDate) {
      fromDate = fromDate.date_to_string();
    }
    if (toDate) {
      toDate = toDate.date_to_string();
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
        RepositoryBase: convertToInt(dropdownSelector.getValues(inventoryFilter) || []),
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
      $('#calendar-from-date').data('dateTimePicker').clearDate();
      $('#calendar-to-date').data('dateTimePicker').clearDate();
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

      $('#calendar-from-date').data('dateTimePicker').clearDate();
      $('#calendar-to-date').data('dateTimePicker').clearDate();
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
            <i class="sn-icon sn-icon-close-small"></i>
          </div>`).appendTo('.ga-top .ga-tags')
          .find('.sn-icon-close-small').click(() => {
            $('.date-selector .date.clear').click();
          });
      }
      $.each($('.ga-side .ds-tags'), function(index, tag) {
        var newTag = $(tag.outerHTML).appendTo('.ga-top .ga-tags');
        newTag.find('.sn-icon-close-small')
          .click(function() {
            newTag.addClass('closing');
            $(tag).find('.sn-icon-close-small').click();
          });
      });

      toggleClearButtons();
    }

    function preloadFilters(filters) {
      if (!filters) return;

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

    $('.datetime-picker-container').on('dp:ready', function() {
      $(this).find('.calendar-input').data('dateTimePicker').onChange = () => {
        let dateContainer = $('.ga-side .date-selector.filter-block');
        if (!updateRunning) {
          let toDate = $('#calendar-to-date').data('dateTimePicker').$refs.vueDateTime.datetime;
          let fromDate = $('#calendar-from-date').data('dateTimePicker').$refs.vueDateTime.datetime;
          dateContainer[0].dataset.periodSelect = (toDate ? toDate?.date_to_string() : '') + ' - ' + (fromDate ? fromDate.date_to_string() : '');
          GlobalActivitiesUpdateTopPaneTags();
          reloadActivities();
          toggleClearButtons();
          resetHotButtonsBackgroundColor();
        }
      }
    });

    GlobalActivitiesUpdateTopPaneTags();

    preloadFilters($('#filters').data('filters'));

    $('.date-selector .hot-button').click(function() {
      var selectPeriod = this.dataset.period;
      var dateContainer = $('.ga-side .date-selector.filter-block');
      var fromDate = $('#calendar-from-date').data('dateTimePicker');
      var toDate = $('#calendar-to-date').data('dateTimePicker');
      var today = new Date();
      var yesterday = new Date(new Date().setDate(today.getDate() - 1));
      var weekDay = today.getDay();
      var monday = new Date(new Date()
        .setDate(today.getDate() - weekDay - (weekDay === 0 ? 6 : -1)));
      var lastWeekStart = new Date(monday.getTime() - (7 * 24 * 60 * 60 * 1000));
      var lastWeekEnd = new Date(lastWeekStart.getTime() + (6 * 24 * 60 * 60 * 1000));
      var firstDay = new Date(today.getFullYear(), today.getMonth(), 1);
      var lastMonthEnd = new Date(new Date().setDate(firstDay.getDate() - 1));
      var lastMonthStart = new Date(lastMonthEnd.getFullYear(), lastMonthEnd.getMonth(), 1);
      updateRunning = true;
      if (selectPeriod === 'today') {
        fromDate.$refs.vueDateTime.datetime = today;
        toDate.$refs.vueDateTime.datetime = today;
      } else if (selectPeriod === 'yesterday') {
        fromDate.$refs.vueDateTime.datetime = yesterday;
        toDate.$refs.vueDateTime.datetime = yesterday;
      } else if (selectPeriod === 'this_week') {
        fromDate.$refs.vueDateTime.datetime = today;
        toDate.$refs.vueDateTime.datetime = monday;
      } else if (selectPeriod === 'last_week') {
        fromDate.$refs.vueDateTime.datetime = lastWeekEnd;
        toDate.$refs.vueDateTime.datetime = lastWeekStart;
      } else if (selectPeriod === 'this_month') {
        fromDate.$refs.vueDateTime.datetime = today;
        toDate.$refs.vueDateTime.datetime = firstDay;
      } else if (selectPeriod === 'last_month') {
        fromDate.$refs.vueDateTime.datetime = lastMonthEnd;
        toDate.$refs.vueDateTime.datetime = lastMonthStart;
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
