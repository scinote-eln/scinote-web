/* global I18n dropdownSelector */
/* eslint-disable no-param-reassign */

var DasboardQuickStartWidget = (function() {
  var projectFilter = '#create-task-modal .project-filter';
  var experimentFilter = '#create-task-modal .experiment-filter';
  var createTaskButton = '#create-task-modal .create-task-button';
  var newProjectsVisibility = '#create-task-modal .new-projects-visibility';

  function initNewTaskModal() {
    $('.quick-start-widget .new-task').click(() => {
      $('#create-task-modal').modal('show');
    });

    dropdownSelector.init(projectFilter, {
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple',
      optionLabel: (data) => {
        if (data.value === 0) {
          return `<i class="fas fa-plus"></i>
                  <span class="create-new">${I18n.t('dashboard.create_task_modal.filter_create_new')}</span>
                  <span>"${data.label}"</span>`;
        }
        return data.label;
      },
      onSelect: () => {
        var selectedValue = dropdownSelector.getValues(projectFilter);
        // Toggle project visibility button
        if (selectedValue === '0') {
          $(newProjectsVisibility).show();
        } else {
          $(newProjectsVisibility).hide();
        }
        // Enable/disable experiment filter
        if (selectedValue >= 0) {
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
      selectAppearance: 'simple',
      optionLabel: (data) => {
        if (data.value === 0) {
          return `<i class="fas fa-plus"></i>
                  <span class="create-new">${I18n.t('dashboard.create_task_modal.filter_create_new')}</span>
                  <span>"${data.label}"</span>`;
        }
        return data.label;
      },
      ajaxParams: (params) => {
        if (dropdownSelector.getValues(projectFilter) === '0') {
          params.project = {
            name: dropdownSelector.getData(projectFilter)[0].label,
            visibility: $('input[name="projects-visibility-selector"]:checked').val()
          };
        } else {
          params.project = { id: dropdownSelector.getValues(projectFilter) };
        }
        return params;
      },
      onSelect: () => {
        var selectedValue = dropdownSelector.getValues(experimentFilter);
        if (selectedValue >= 0) {
          $(createTaskButton).removeAttr('disabled');
        } else {
          $(createTaskButton).attr('disabled', true);
        }
      }
    });

    $(createTaskButton).click(() => {
      var params = {};
      if (dropdownSelector.getValues(projectFilter) === '0') {
        params.project = {
          name: dropdownSelector.getData(projectFilter)[0].label,
          visibility: $('input[name="projects-visibility-selector"]:checked').val()
        };
      } else {
        params.project = { id: dropdownSelector.getValues(projectFilter) };
      }
      if (dropdownSelector.getValues(experimentFilter) === '0') {
        params.experiment = { name: dropdownSelector.getData(experimentFilter)[0].label };
      } else {
        params.experiment = { id: dropdownSelector.getValues(experimentFilter) };
      }
      $.post($(createTaskButton).data('ajaxUrl'), params, function(data) {
        window.location.href = data.my_module_path;
      });
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
