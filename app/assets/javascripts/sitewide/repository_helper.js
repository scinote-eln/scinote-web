/* global GLOBAL_CONSTANTS I18n */

(function() {
  'use strict';

  function initUnsavedWorkDialog() {
    $(document).on('turbolinks:before-visit', () => {
      let exit = true;
      let editing = $(`.${GLOBAL_CONSTANTS.REPOSITORY_ROW_EDITOR_FORM_CLASS_NAME}`).length > 0;

      if (editing) {
        exit = confirm(I18n.t('repositories.js.leaving_warning'));
      }

      return exit;
    });
  }

  initUnsavedWorkDialog();
}());

function initAssignedTasksDropdown(table) {
  function loadTasks(counterContainer) {
    var tasksContainer = counterContainer.find('.tasks');
    var tasksUrl = counterContainer.data('task-list-url');
    var searchQuery = counterContainer.find('.search-tasks').val();
    $.get(tasksUrl, { query: searchQuery }, function(result) {
      tasksContainer.html(result.html);
    });
  }

  $(table).on('show.bs.dropdown', '.assign-counter-container', function() {
    var cell = $(this);
    loadTasks(cell);
  });

  $(table).on('click', '.assign-counter-container .dropdown-menu', function(e) {
    e.stopPropagation();
  });

  $(table).on('click', '.assign-counter-container .clear-search', function() {
    var cell = $(this).closest('.assign-counter-container');
    $(this).prev('.search-tasks').val('');
    loadTasks(cell);
  });

  $(table).on('keyup', '.assign-counter-container .search-tasks', function() {
    var cell = $(this).closest('.assign-counter-container');
    loadTasks(cell);
  });
}
