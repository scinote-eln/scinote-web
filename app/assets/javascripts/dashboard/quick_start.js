/* global I18n dropdownSelector */
/* eslint-disable no-param-reassign */

var DasboardQuickStartWidget = (function() {
  var projectFilter = '#create-task-modal .project-filter';
  var experimentFilter = '#create-task-modal .experiment-filter';
  var createTaskButton = '#create-task-modal .create-task-button';
  var newProjectsVisibility = '#create-task-modal .new-projects-visibility';

  function initNewReportLink() {
    $('.quick-start-buttons .new-report').click(() => {
      sessionStorage.setItem('scinote-dashboard-new-report', Math.floor(Date.now() / 1000));
    });
  }

  function initNewProtocolLink() {
    $('.quick-start-buttons .new-protocol').click(() => {
      sessionStorage.setItem('scinote-dashboard-new-protocol', Math.floor(Date.now() / 1000));
    });
  }

  function initNewTaskModal() {
    $('.quick-start-buttons .new-task').click(() => {
      $('#create-task-modal').modal('show');
      $('#create-task-modal .select-block').attr('data-error', '');
    });

    dropdownSelector.init(projectFilter, {
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple',
      optionLabel: (data) => {
        if (data.value === 0) {
          return `<i class="sn-icon sn-icon-new-task"></i>
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
          return `<i class="sn-icon sn-icon-new-task"></i>
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
          $(createTaskButton).attr('disabled', false);
        } else {
          $(createTaskButton).attr('disabled', true);
        }
      }
    });

    $(createTaskButton).one('click', (e) => {
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
      e.stopPropagation();
      e.preventDefault();
      $('#create-task-modal .select-block').attr('data-error', '');
      $.post($(createTaskButton).data('ajaxUrl'), params, function(data) {
        window.location.href = data.my_module_path;
      }).fail((response) => {
        var errorsObject = response.responseJSON.error_object;
        var errorsText = response.responseJSON.errors.name.join(' ');
        $(`#create-task-modal .select-block[data-error-object="${errorsObject}"]`).attr('data-error', errorsText);
      });
    });
  }

  return {
    init: () => {
      if ($('.quick-start-buttons').length) {
        initNewTaskModal();
        initNewProtocolLink();
        initNewReportLink();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  DasboardQuickStartWidget.init();
});
