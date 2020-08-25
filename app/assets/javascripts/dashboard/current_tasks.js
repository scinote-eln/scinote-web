/* global dropdownSelector animateSpinner PerfectSb InfiniteScroll */
/* eslint-disable no-param-reassign */

var DasboardCurrentTasksWidget = (function() {
  var sortFilter = '.curent-tasks-filters .sort-filter';
  var viewFilter = '.curent-tasks-filters .view-filter';
  var projectFilter = '.curent-tasks-filters .project-filter';
  var experimentFilter = '.curent-tasks-filters .experiment-filter';

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
        params.view = dropdownSelector.getValues(viewFilter);
        params.query = $('.current-tasks-widget .task-search-field').val();
        params.mode = $('.current-tasks-navbar .active').data('mode');
        return params;
      }
    });
  }

  function filtersEnabled() {
    return dropdownSelector.getValues(experimentFilter)
           || dropdownSelector.getValues(projectFilter)
           || $('.current-tasks-widget .task-search-field').val().length > 0
           || dropdownSelector.getValues(viewFilter) !== 'uncompleted';
  }

  function loadCurrentTasksList(newList) {
    var $currentTasksList = $('.current-tasks-list');
    var params = {
      project_id: dropdownSelector.getValues(projectFilter),
      experiment_id: dropdownSelector.getValues(experimentFilter),
      sort: dropdownSelector.getValues(sortFilter),
      view: dropdownSelector.getValues(viewFilter),
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
    $('.curent-tasks-filters .clear-button').click((e) => {
      e.stopPropagation();
      e.preventDefault();
      dropdownSelector.selectValue(sortFilter, 'date_asc');
      dropdownSelector.selectValue(viewFilter, 'uncompleted');
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

    dropdownSelector.init(viewFilter, {
      noEmptyOption: true,
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple',
      disableSearch: true
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

    $('.curent-tasks-filters').click((e) => {
      // Prevent filter window close
      e.stopPropagation();
      e.preventDefault();
      dropdownSelector.closeDropdown(sortFilter);
      dropdownSelector.closeDropdown(viewFilter);
      dropdownSelector.closeDropdown(projectFilter);
      dropdownSelector.closeDropdown(experimentFilter);
    });

    $('.curent-tasks-filters .apply-filters').click((e) => {
      $('.curent-tasks-filters').dropdown('toggle');
      e.stopPropagation();
      e.preventDefault();
      loadCurrentTasksList(true);
    });

    $('.filter-container').on('hide.bs.dropdown', () => {
      loadCurrentTasksList(true);
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
        loadCurrentTasksList();
        initInfiniteScroll();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  DasboardCurrentTasksWidget.init();
});
