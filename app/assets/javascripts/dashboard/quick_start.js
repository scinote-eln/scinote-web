/* global dropdownSelector */
/* eslint-disable no-param-reassign */

var DasboardQuickStartWidget = (function() {
  var projectFilter = '#create-task-modal .project-filter';
  var experimentFilter = '#create-task-modal .experiment-filter';

  function initNewTaskModal() {
    $('.quick-start-widget .new-task').click(() => {
      $('#create-task-modal').modal('show');
    });

    dropdownSelector.init(projectFilter, {
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple'
    });

    dropdownSelector.init(experimentFilter, {
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple'
    });
  }

  return {
    init: () => {
      if ($('.quick-start-widget').length) {
        initNewTaskModal();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  DasboardQuickStartWidget.init();
});
