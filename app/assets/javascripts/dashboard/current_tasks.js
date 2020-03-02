/* global dropdownSelector I18n animateSpinner PerfectSb InfiniteScroll */
/* eslint-disable no-param-reassign */

var DasboardCurrentTasksWidget = (function() {
  var sortFilter = '.curent-tasks-filters .sort-filter';
  var viewFilter = '.curent-tasks-filters .view-filter';
  var projectFilter = '.curent-tasks-filters .project-filter';
  var experimentFilter = '.curent-tasks-filters .experiment-filter';
  var emptyState = `<div class="no-tasks">
                      <p class="text-1">${ I18n.t('dashboard.current_tasks.no_tasks.text_1') }</p>
                      <p class="text-2">${ I18n.t('dashboard.current_tasks.no_tasks.text_2') }</p>
                      <i class="fas fa-angle-double-down"></i>
                    </div>`;

  function generateTasksListHtml(json, container) {
    $.each(json.data, (i, task) => {
      var currentTaskItem;
      var stepsPercentage = task.steps_state.percentage + '%';
      var stateText;
      var dueDate = (task.due_date !== null) ? '<i class="fas fa-calendar-day"></i>'
        + I18n.t('dashboard.current_tasks.due_date', { date: task.due_date }) : '';
      var overdue = (task.overdue) ? 'overdue' : '';
      if (task.state === 'completed') {
        stateText = I18n.t('dashboard.current_tasks.progress_bar.completed');
      } else {
        stateText = I18n.t('dashboard.current_tasks.progress_bar.in_progress');
        if (task.overdue) { stateText = I18n.t('dashboard.current_tasks.progress_bar.overdue'); }
        if (task.steps_state.all_steps !== 0) {
          stateText += I18n.t('dashboard.current_tasks.progress_bar.completed_steps',
            { steps: task.steps_state.completed_steps, total_steps: task.steps_state.all_steps });
        }
      }
      currentTaskItem = `<a class="current-task-item" href="${task.link}">
                           <div class="current-task-breadcrumbs">${task.project}/${task.experiment}</div>
                           <div class="item-row">
                             <div class="task-name">${task.name}</div>
                             <div class="task-due-date ${overdue}">${dueDate}</div>
                             <div class="task-progress-container ${task.state} ${overdue}">
                               <div class="task-progress" style="padding-left: ${stepsPercentage}"></div>
                               <div class="task-progress-label">${stateText}</div>
                             </div>
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

  function loadCurrentTasksList(newList) {
    var $currentTasksList = $('.current-tasks-list');
    var params = {
      project_id: dropdownSelector.getValues(projectFilter),
      experiment_id: dropdownSelector.getValues(experimentFilter),
      sort: dropdownSelector.getValues(sortFilter),
      view: dropdownSelector.getValues(viewFilter),
      mode: $('.current-tasks-navbar .active').data('mode')
    };
    animateSpinner($currentTasksList, true);
    $.get($currentTasksList.data('tasksListUrl'), params, function(data) {
      // Toggle empty state
      if (data.data.length === 0) {
        $currentTasksList.append(emptyState);
      } else {
        $currentTasksList.find('.no-tasks').remove();
      }
      // Clear the list
      $currentTasksList.find('.current-task-item').remove();
      generateTasksListHtml(data, $currentTasksList);
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
  }

  function initNavbar() {
    $('.navbar-assigned, .navbar-all').on('click', function(e) {
      e.stopPropagation();
      e.preventDefault();
      $('.current-tasks-navbar').find('a').removeClass('active');
      $(this).addClass('active');
      loadCurrentTasksList(true);
    });
  }

  return {
    init: () => {
      if ($('.current-tasks-widget').length) {
        initNavbar();
        initFilters();
        loadCurrentTasksList();
        initInfiniteScroll();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  DasboardCurrentTasksWidget.init();
});
