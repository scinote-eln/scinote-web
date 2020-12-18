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

function prepareRepositoryHeaderForExport(th) {
  var val;
  switch ($(th).attr('id')) {
    case 'checkbox':
      val = -1;
      break;
    case 'assigned':
      val = -2;
      break;
    case 'row-id':
      val = -3;
      break;
    case 'row-name':
      val = -4;
      break;
    case 'added-by':
      val = -5;
      break;
    case 'added-on':
      val = -6;
      break;
    case 'archived-by':
      val = -7;
      break;
    case 'archived-on':
      val = -8;
      break;
    default:
      val = th.attr('id');
  }

  return val;
}
