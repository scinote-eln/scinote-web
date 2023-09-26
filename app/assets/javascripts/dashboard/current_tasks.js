/* global dropdownSelector animateSpinner PerfectSb InfiniteScroll */
/* eslint-disable no-param-reassign */

var DasboardCurrentTasksWidget = (function() {
  var sortFilter = '.current-tasks-filters .sort-filter';
  var statusFilter = '.current-tasks-filters .view-filter';
  var projectFilter = '.current-tasks-filters .project-filter';
  var experimentFilter = '.current-tasks-filters .experiment-filter';

  function appendTasksList(json, container) {
    $.each(json.data, (i, task) => {
      var currentTaskItem = task;
      $(container).find('.current-tasks-list').append(currentTaskItem);
    });
  }

  function getDefaultStatusValues() {
    // Select uncompleted status values
    var values = [];
    $(statusFilter).find('option').each(function(_, option) {
      if ($(option).data('completionConsequence')) {
        return false;
      }
      values.push(option.value);
      return this;
    });
    return values;
  }

  function resetMarkAppliedFilters() {
    $('.filter-container').removeClass('filters-applied');
  }

  function filtersEnabled() {
    return dropdownSelector.getData(experimentFilter).length > 0
           || dropdownSelector.getData(projectFilter).length > 0
           || (dropdownSelector.getValues(sortFilter) !== 'due_first')
           || dropdownSelector.getValues(statusFilter).sort().toString()
              !== getDefaultStatusValues().sort().toString();
  }

  function markAppliedFilters() {
    if (!filtersEnabled()) {
      resetMarkAppliedFilters();
    } else {
      $('.filter-container').addClass('filters-applied');
    }
  }

  function filterStateSave() {
    var teamId = $('.current-tasks-filters').data('team-id');
    var filterState = {
      sort: dropdownSelector.getValues(sortFilter),
      statuses: dropdownSelector.getValues(statusFilter),
      project_id: dropdownSelector.getData(projectFilter),
      experiment_id: dropdownSelector.getData(experimentFilter),
      mode: $('.current-tasks-navbar .active').data('mode')
    };
    markAppliedFilters();
    localStorage.setItem('current_tasks_filters_per_team/' + teamId, JSON.stringify(filterState));
  }

  function filterStateLoad() {
    var teamId = $('.current-tasks-filters').data('team-id');
    var filterState = localStorage.getItem('current_tasks_filters_per_team/' + teamId);
    var parsedFilterState;
    var allStatusValues = $.map($(statusFilter).find('option'), function(option) {
      return option.value;
    });

    if (filterState) {
      try {
        parsedFilterState = JSON.parse(filterState);
        dropdownSelector.selectValues(sortFilter, parsedFilterState.sort);
        // Check if saved statuses are valid
        if (parsedFilterState.statuses.every(status => allStatusValues.includes(status))) {
          dropdownSelector.selectValues(statusFilter, parsedFilterState.statuses);
        } else {
          dropdownSelector.selectValues(statusFilter, getDefaultStatusValues());
        }
        dropdownSelector.setData(projectFilter, parsedFilterState.project_id);
        dropdownSelector.setData(experimentFilter, parsedFilterState.experiment_id);
        // Select saved navbar state
        $('.current-tasks-navbar .navbar-link').removeClass('active');
        $('.current-tasks-navbar').find(`[data-mode='${parsedFilterState.mode}']`).addClass('active');
        markAppliedFilters();
      } catch (e) {
        dropdownSelector.selectValues(statusFilter, getDefaultStatusValues());
        resetMarkAppliedFilters();
      }
    } else {
      dropdownSelector.selectValues(statusFilter, getDefaultStatusValues());
      resetMarkAppliedFilters();
    }
  }

  function loadCurrentTasksList(newList) {
    var $currentTasksList = $('.current-tasks-list');
    var requestParams = {
      project_id: dropdownSelector.getValues(projectFilter),
      experiment_id: dropdownSelector.getValues(experimentFilter),
      sort: dropdownSelector.getValues(sortFilter),
      statuses: dropdownSelector.getValues(statusFilter),
      query: $('.current-tasks-widget .task-search-field').val(),
      mode: $('.current-tasks-navbar .active').data('mode')
    };
    animateSpinner($currentTasksList, true);
    $.get($currentTasksList.data('tasksListUrl'), requestParams, function(result) {
      $currentTasksList.empty();
      // Toggle empty state
      if (result.data.length === 0) {
        if (filtersEnabled() || $('.current-tasks-widget .task-search-field').val().length > 0) {
          $currentTasksList.append($('#dashboard-current-task-no-search-results').html());
        } else {
          $currentTasksList.append($('#dashboard-current-task-no-tasks').html());
          $currentTasksList.find('.widget-placeholder').addClass($('.current-tasks-navbar .active').data('mode'));
        }
      }
      appendTasksList(result, '.current-tasks-list-wrapper');
      PerfectSb().update_all();

      InfiniteScroll.init('.current-tasks-list-wrapper', {
        url: $currentTasksList.data('tasksListUrl'),
        lastPage: !result.next_page,
        customResponse: (json, container) => {
          appendTasksList(json, container);
        },
        customParams: (params) => {
          return { ...params, ...requestParams };
        }
      });

      animateSpinner($currentTasksList, false);
    }).fail(function(error) {
      // If error is 403, it is possible that the user was removed from project/experiment,
      // so clear local storage and filter state
      if (error.status === 403) {
        localStorage.removeItem('current_tasks_filters_per_team/' + $('.current-tasks-filters').data('team-id'));
        $('.current-tasks-filters .clear-button').trigger('click');
        resetMarkAppliedFilters();
        loadCurrentTasksList();
      }
    });
  }

  function initFilters() {
    $('.current-tasks-filters .clear-button').click((e) => {
      e.stopPropagation();
      e.preventDefault();

      dropdownSelector.selectValues(sortFilter, 'due_first');
      dropdownSelector.selectValues(statusFilter, getDefaultStatusValues());
      dropdownSelector.clearData(projectFilter);
      dropdownSelector.clearData(experimentFilter);
    });

    dropdownSelector.init(sortFilter, {
      noEmptyOption: true,
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple',
      disableSearch: true
    });

    dropdownSelector.init(statusFilter, {
      selectAppearance: 'simple',
      optionClass: 'checkbox-icon'
    });

    dropdownSelector.init(projectFilter, {
      singleSelect: true,
      closeOnSelect: true,
      emptyOptionAjax: true,
      selectAppearance: 'simple',
      ajaxParams: (params) => {
        params.mode = $('.current-tasks-navbar .active').data('mode');
        return params;
      },
      onChange: () => {
        var selectedValue = dropdownSelector.getValues(projectFilter);
        if (selectedValue > 0) {
          dropdownSelector.enableSelector(experimentFilter);
        } else {
          dropdownSelector.disableSelector(experimentFilter);
        }
        dropdownSelector.clearData(experimentFilter);
      }
    });

    dropdownSelector.init(experimentFilter, {
      singleSelect: true,
      closeOnSelect: true,
      emptyOptionAjax: true,
      selectAppearance: 'simple',
      ajaxParams: (params) => {
        params.mode = $('.current-tasks-navbar .active').data('mode');
        params.project_id = dropdownSelector.getValues(projectFilter);
        return params;
      }
    });

    $('.current-tasks-filters').click((e) => {
      // Prevent filter window close
      e.stopPropagation();
      e.preventDefault();
      dropdownSelector.closeDropdown(sortFilter);
      dropdownSelector.closeDropdown(statusFilter);
      dropdownSelector.closeDropdown(projectFilter);
      dropdownSelector.closeDropdown(experimentFilter);
    });

    $('.current-tasks-filters .apply-filters').click((e) => {
      $('.current-tasks-filters').dropdown('toggle');
      e.stopPropagation();
      e.preventDefault();
    });

    $('.current-tasks-filters').on('click', '.close-dropdown', (e) => {
      $('.current-tasks-filters').dropdown('toggle');
      e.stopPropagation();
      e.preventDefault();
    });

    $('.filter-container').on('hide.bs.dropdown', () => {
      loadCurrentTasksList(true);
      filterStateSave();
      $('.current-tasks-list').removeClass('disabled');
    });

    $('.filter-container').on('shown.bs.dropdown', () => {
      $('.current-tasks-list').addClass('disabled');
    });
  }

  function initNavbar() {
    $('.current-tasks-navbar .navbar-link').on('click', function() {
      $(this).parent().find('.navbar-link').removeClass('active');
      $(this).addClass('active');
      loadCurrentTasksList(true);
      filterStateSave();
    });
  }

  function initSearch() {
    $('.current-tasks-widget').on('change', '.task-search-field', () => {
      loadCurrentTasksList();
    });
  }

  return {
    init: () => {
      if ($('.current-tasks-widget').length) {
        initNavbar();
        initFilters();
        initSearch();
        filterStateLoad();
        loadCurrentTasksList();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  DasboardCurrentTasksWidget.init();
});
