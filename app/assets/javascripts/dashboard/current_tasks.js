/* global dropdownSelector */
/* eslint-disable no-param-reassign */

var DasboardCurrentTasksWidget = (function() {
  function initFilters() {
    var sortFilter = '.curent-tasks-filters .sort-filter';
    var viewFilter = '.curent-tasks-filters .view-filter';
    var projectFilter = '.curent-tasks-filters .project-filter';
    var experimentFilter = '.curent-tasks-filters .experiment-filter';

    $('.curent-tasks-filters .clear-button').click(() => {
      dropdownSelector.clearData(projectFilter);
      dropdownSelector.clearData(experimentFilter);
    });

    dropdownSelector.init(sortFilter, {
      noEmptyOption: true,
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple'
    });

    dropdownSelector.init(viewFilter, {
      noEmptyOption: true,
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple'
    });

    dropdownSelector.init(projectFilter, {
      singleSelect: true,
      closeOnSelect: true,
      emptyOptionAjax: true,
      selectAppearance: 'simple',
      ajaxParams: (params) => {
        params.mode = 'team';
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
        params.mode = 'team';
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
  }

  return {
    init: () => {
      if ($('.current-tasks-widget').length) {
        initFilters();
      }
    }
  };
}());

$(document).on('turbolinks:load', function() {
  DasboardCurrentTasksWidget.init();
});
