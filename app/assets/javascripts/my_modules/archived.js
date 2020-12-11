(function() {
  let selectedTasks = [];

  $('#module-archive').on('click', '.restore-button-container', function(e) {
    e.preventDefault();
    alert('woop! Not implemented yet!')
  });

  $('#module-archive').on('click', '.task-selector', function() {
    let taskId = $(this).closest('.task-selector-container').data('task-id');
    let index = $.inArray(taskId, selectedTasks);
    let resoteTasksButton = $('.restore-button-container');

    // If checkbox is checked and row ID is not in list of selected folder IDs
    if (this.checked && index === -1) {
      selectedTasks.push(taskId);
      resoteTasksButton.collapse('show');
      // Otherwise, if checkbox is not checked and ID is in list of selected IDs
    } else if (!this.checked && index !== -1) {
      selectedTasks.splice(index, 1);
    }
    // Hide button
    if (selectedTasks.length === 0) resoteTasksButton.collapse('hide');
  });
}());
