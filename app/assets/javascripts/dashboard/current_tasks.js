/* global dropdownSelector animateSpinner PerfectSb InfiniteScroll */
/* eslint-disable no-param-reassign */

var DasboardCurrentTasksWidget = (function() {
  var sortFilter = '.current-tasks-filters .sort-filter';
  var statusFilter = '.current-tasks-filters .view-filter';
  var projectFilter = '.current-tasks-filters .project-filter';
  var experimentFilter = '.current-tasks-filters .experiment-filter';

  function generateTasksListHtml(json, container) {
    $.each(json.data, (i, task) => {
      var currentTaskItem = ` <a class="current-task-item" href="${task.link}">
                                <div class="current-task-breadcrumbs">${task.project}<span class="slash">/</span>${task.experiment}</div>
                                <div class="task-name row-border">${task.name}</div>
                                <div class="task-due-date row-border ${task.due_date.state}">
                                  <span class="${task.due_date.text ? '' : 'hidden'}">
                                    <i class="fas fa-calendar-day"></i> ${task.due_date.text}
                                  </span>
                                </div>
                                <div class="task-status-container row-border">
                                  <span class="task-status" style="background:${task.status_color}">${task.status_name}</span>
                                </div>
                              </a>`;
      $(container).append(currentTaskItem);
    });
  }

  function getDefaultStatusValues() {
    return $.map($(statusFilter).find("option[data-final-status='false']"), function(option) {
      return option.value;
    });
  }

  function initInfiniteScroll() {
    InfiniteScroll.init('.current-tasks-list', {
      url: $('.current-tasks-list').data('tasksListUrl'),
      customResponse: (json, container) => {
        generateTasksListHtml(json, container);
      },
      customParams: (params) => {
        params.project_id = dropdownSelector.getValues(projectFilter);
        params.experiment_id = dropdownSelector.getValues(experimentFilter);
        params.sort = dropdownSelector.getValues(sortFilter);
        params.statuses = dropdownSelector.getValues(statusFilter);
        params.query = $('.current-tasks-widget .task-search-field').val();
        params.mode = $('.current-tasks-navbar .active').data('mode');
        return params;
      }
    });
  }

  function filtersEnabled() {
    return dropdownSelector.getValues(experimentFilter)
           || dropdownSelector.getValues(projectFilter)
           || $('.current-tasks-widget .task-search-field').val().length > 0;
  }

  function filterStateSave() {
    var teamId = $('.current-tasks-filters').data('team-id');
    var filterState = {
      sort: dropdownSelector.getValues(sortFilter),
      statuses: dropdownSelector.getValues(statusFilter),
      mode: $('.current-tasks-navbar .active').data('mode')
    };

    if (filterState) {
      localStorage.setItem('current_tasks_filters_per_team/' + teamId, JSON.stringify(filterState));
    }
  }

  function filterStateLoad() {
    var teamId = $('.current-tasks-filters').data('team-id');
    var filterState = localStorage.getItem('current_tasks_filters_per_team/' + teamId);
    var parsedFilterState;
    var allStatusValues = $.map($(statusFilter).find('option'), function(option) {
      return option.value;
    });

    if (filterState !== null) {
      parsedFilterState = JSON.parse(filterState);
      dropdownSelector.selectValues(sortFilter, parsedFilterState.sort);
      // Check if saved statuses are valid
      if (parsedFilterState.statuses.every(savedStatus => allStatusValues.includes(savedStatus))) {
        dropdownSelector.selectValues(statusFilter, parsedFilterState.statuses);
      } else {
        dropdownSelector.selectValues(statusFilter, getDefaultStatusValues());
      }
      // Select saved navbar state
      $('.current-tasks-navbar .navbar-link').removeClass('active');
      $('.current-tasks-navbar').find(`[data-mode='${parsedFilterState.mode}']`).addClass('active');
    }
  }

  function loadCurrentTasksList(newList) {
    var $currentTasksList = $('.current-tasks-list');
    var params = {
      project_id: dropdownSelector.getValues(projectFilter),
      experiment_id: dropdownSelector.getValues(experimentFilter),
      sort: dropdownSelector.getValues(sortFilter),
      statuses: dropdownSelector.getValues(statusFilter),
      query: $('.current-tasks-widget .task-search-field').val(),
      mode: $('.current-tasks-navbar .active').data('mode')
    };
    animateSpinner($currentTasksList, true);
    $.get($currentTasksList.data('tasksListUrl'), params, function(result) {
      $currentTasksList.empty();
      // Toggle empty state
      if (result.data.length === 0) {
        if (filtersEnabled()) {
          $currentTasksList.append($('#dashboard-current-task-no-search-results').html());
        } else {
          $currentTasksList.append($('#dashboard-current-task-no-tasks').html());
          $currentTasksList.find('.widget-placeholder').addClass($('.current-tasks-navbar .active').data('mode'));
        }
      }
      generateTasksListHtml(result, $currentTasksList);
      PerfectSb().update_all();
      if (newList) InfiniteScroll.resetScroll('.current-tasks-list');
      animateSpinner($currentTasksList, false);
    });
  }

  function initFilters() {
    $('.current-tasks-filters .clear-button').click((e) => {
      e.stopPropagation();
      e.preventDefault();

      dropdownSelector.selectValues(sortFilter, 'due_date');
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
      loadCurrentTasksList(true);
      filterStateSave();
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
        initInfiniteScroll();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  DasboardCurrentTasksWidget.init();
});
