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
    $(document).on('shown.bs.dropdown', function() {
      $('#searchAssignedTasks').focus();
    });
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
    case 'relationship':
      val = -9;
      break;
    default:
      val = th.attr('id');
  }

  return val;
}

function initReminderDropdown(table) {
  $(table).on('keyup', '.row-reminders-dropdown', function(e) {
    if (e.key === 'Escape' && $('.row-reminders-dropdown').hasClass('open')) {
      $(this).children('.dropdown-menu').dropdown('toggle');
      // Preventing closing modal on full view mode for assigning repository items
      e.preventDefault();
      e.stopPropagation();
    }
  });

  $(table).on('keyup', '.row-reminders-footer', function(e) {
    if (e.key === ' ') {
      $(this).click();
    }
  });

  $(table).on('show.bs.dropdown', '.row-reminders-dropdown', function() {
    let row = $(this).closest('tr');
    let screenHeight = screen.height;
    let rowPosition = row[0].getBoundingClientRect().y;
    let dropdownMenu = $(this).find('.dropdown-menu');
    if ((screenHeight / 2) < rowPosition && $('.repository-show').length) {
      dropdownMenu.css({ top: 'unset', bottom: '100%' });
    } else {
      dropdownMenu.css({ bottom: 'unset', top: '100%' });
    }
    $.ajax({
      url: $(this).attr('data-row-reminders-url'),
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        dropdownMenu.html(data.html);
      }
    });
  });

  $(table).on('click', '.row-reminders-footer', function(e) {
    var dropdownMenuLength = $(this).closest('.dropdown-menu').children().length;
    var bellIcon = $(this).closest('.row-reminders-dropdown');
    $.ajax({
      url: $(this).attr('data-row-hide-reminders-url'),
      type: 'POST',
      dataType: 'json',
      success: function() {
        $(this).closest('.row-reminders-notification').remove();

        if (dropdownMenuLength === 1) {
          bellIcon.remove();
        }
        e.stopPropagation();
      }
    });
  });
}
