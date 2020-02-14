/* global dropdownSelector */

var DasboardCurrentTasksWidget = (function() {
  function initFilters() {
    dropdownSelector.init('.curent-tasks-filters .sort-filter', {
      noEmptyOption: true,
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple'
    });

    dropdownSelector.init('.curent-tasks-filters .view-filter', {
      noEmptyOption: true,
      singleSelect: true,
      closeOnSelect: true,
      selectAppearance: 'simple'
    });

    dropdownSelector.init('.curent-tasks-filters .project-filter');
    dropdownSelector.init('.curent-tasks-filters .experiment-filter');

    $('.curent-tasks-filters').click((e) => {
      e.stopPropagation();
      e.preventDefault();
      dropdownSelector.closeDropdown('.curent-tasks-filters .sort-filter');
      dropdownSelector.closeDropdown('.curent-tasks-filters .view-filter');
      dropdownSelector.closeDropdown('.curent-tasks-filters .project-filter');
      dropdownSelector.closeDropdown('.curent-tasks-filters .experiment-filter');
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
